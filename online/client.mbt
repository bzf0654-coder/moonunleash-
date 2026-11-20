///|
pub(all) struct Response {
  status : Int32
  body : String
  etag : String?
}

///|
/// Dependency-injection boundary. Token is captured privately by the HTTP adapter.
pub(all) struct Transport {
  request : async (String, String, String?, String?) -> Response
}

///|
pub struct Options {
  priv base_url : String
  priv app_name : String
  priv environment : String
  priv token : String
  priv refresh_ms : Int32
  priv timeout_ms : Int32
  priv max_response_bytes : Int32
  priv stale_after_ms : Int64
  priv max_stale_ms : Int64?
  priv instance_id : String?
  priv metrics_ms : Int32
  priv disable_metrics : Bool
}

///|
pub fn Options::new(
  base_url : String,
  app_name : String,
  token : String,
  environment~ : String = "default",
  allow_http_loopback~ : Bool = false,
  refresh_ms~ : Int32 = 15000,
  timeout_ms~ : Int32 = 5000,
  max_response_bytes~ : Int32 = 8388608,
  stale_after_ms~ : Int64 = 60000L,
  max_stale_ms? : Int64,
  instance_id? : String,
  metrics_ms~ : Int32 = 60000,
  disable_metrics~ : Bool = false,
) -> Options raise @sdk.ConfigError {
  if app_name == "" || environment == "" || token == "" {
    raise @sdk.ConfigError::Invalid(
      "app_name, environment and token are required",
    )
  }
  if app_name.length() > 128 ||
    environment.length() > 128 ||
    token.length() > 8192 ||
    base_url.length() > 2048 {
    raise @sdk.ConfigError::Invalid("client option length budget exceeded")
  }
  for v in [base_url, app_name, environment, token] {
    if v.to_array().any(fn(c) { c < ' ' || c == '\u007f' }) {
      raise @sdk.ConfigError::Invalid("control character in client options")
    }
  }
  if base_url.contains("?") ||
    base_url.contains("#") ||
    base_url.contains("@") ||
    base_url.contains("\\") ||
    base_url.contains(" ") {
    raise @sdk.ConfigError::Invalid(
      "base URL must not contain credentials, query, fragment or whitespace",
    )
  }
  let url = base_url.trim_end(chars="/").to_owned()
  let (scheme, rest) = match url.split_once("://") {
    Some(pair) => pair
    None => raise @sdk.ConfigError::Invalid("absolute API URL required")
  }
  let host = rest.split("/").next().unwrap_or("")
  if host == "" || host.contains("%") {
    raise @sdk.ConfigError::Invalid("invalid API authority")
  }
  let loopback = host == "127.0.0.1" ||
    host.has_prefix("127.0.0.1:") ||
    host == "localhost" ||
    host.has_prefix("localhost:")
  if scheme != "https" && !(scheme == "http" && allow_http_loopback && loopback) {
    raise @sdk.ConfigError::Invalid(
      "HTTPS required; explicit loopback HTTP is for local development only",
    )
  }
  if refresh_ms < 1 ||
    timeout_ms < 1 ||
    max_response_bytes < 1 ||
    max_response_bytes > 8388608 {
    raise @sdk.ConfigError::Invalid(
      "invalid refresh, timeout or body-size budget",
    )
  }
  if metrics_ms < 1 {
    raise @sdk.ConfigError::Invalid("metrics interval must be positive")
  }
  if instance_id is Some(id) {
    if id == "" ||
      id.length() > 128 ||
      id.to_array().any(fn(c) { c < ' ' || c == '\u007f' }) {
      raise @sdk.ConfigError::Invalid("invalid instance id")
    }
  }
  ignore(@sdk.SnapshotStore::new(stale_after_ms~, max_stale_ms?))
  {
    base_url: url,
    app_name,
    environment,
    token,
    refresh_ms,
    timeout_ms,
    max_response_bytes,
    stale_after_ms,
    max_stale_ms,
    instance_id,
    metrics_ms,
    disable_metrics,
  }
}

///|
// Use the streaming connection API shared by the verified toolchain versions.
// Options already rejects credentials, query, fragment and control characters.
fn http_target(url : String) -> (String, String) raise @sdk.ConfigError {
  let (scheme, rest) = match url.split_once("://") {
    Some(pair) => pair
    None =>
      raise @sdk.ConfigError::Invalid("absolute HTTP request URL required")
  }
  if scheme != "https" && scheme != "http" {
    raise @sdk.ConfigError::Invalid("invalid HTTP request scheme")
  }
  let (authority, path) = match rest.split_once("/") {
    Some((authority, path)) => (authority.to_owned(), "/\{path}")
    None => (rest.to_owned(), "/")
  }
  if authority == "" {
    raise @sdk.ConfigError::Invalid("empty HTTP request authority")
  }
  ("\{scheme}://\{authority}", path)
}

///|
fn http_transport(options : Options) -> Transport {
  {
    request: async fn(verb, url, body, etag) {
      let headers : @http.Headers = Map([
        (@http.CaseInsensitiveString("Authorization"), options.token),
        (@http.CaseInsensitiveString("Accept"), "application/json"),
        (@http.CaseInsensitiveString("UNLEASH-APPNAME"), options.app_name),
        (@http.CaseInsensitiveString("UNLEASH-SDK"), "moonunleash:0.1.0"),
      ])
      if etag is Some(value) {
        headers[@http.CaseInsensitiveString("If-None-Match")] = value
      }
      if body is Some(_) {
        headers[@http.CaseInsensitiveString("Content-Type")] = "application/json"
      }
      let (origin, path) = http_target(url)
      let conn = @http.ClientConnection(origin, headers~)
      defer conn.close()
      conn.request(if verb == "POST" { Post } else { Get }, path)
      if body is Some(text) {
        conn.write(@utf8.encode(text))
      }
      let header = conn.end_request()
      if header.code >= 300 && header.code < 400 && header.code != 304 {
        // Never follow a redirect with an SDK credential.
        return { status: header.code, body: "", etag: None, }
      }
      let buffer = @buffer.Buffer()
      while conn.read() is Some(bytes) {
        if bytes.length() > options.max_response_bytes - buffer.length() {
          raise @sdk.ConfigError::Invalid("HTTP response body budget exceeded")
        }
        buffer.write_bytes(bytes)
      }
      {
        status: header.code,
        body: @utf8.decode(buffer.to_bytes()),
        etag: header.headers.get(@http.CaseInsensitiveString("ETag")),
      }
    },
  }
}

///|
/// The same bounded direct HTTP transport used by Client::new. Useful for
/// observational decorators; an injected transport must preserve the contract.
pub fn Transport::http(options : Options) -> Transport {
  http_transport(options)
}

///|
pub struct Client {
  priv options : Options
  priv transport : Transport
  priv store : @sdk.SnapshotStore
  priv mut etag : String?
  priv mut registered : Bool
  priv mut registering : Bool
  priv mut refreshing : Bool
  priv mut closed : Bool
  priv mut last_clock : Int64
  priv mut poll_task : @async.Task[Unit]?
  priv instance_id : String
  priv metrics : @sdk.Metrics
  priv mut flushing_metrics : Bool
  priv mut metrics_task : @async.Task[Unit]?
  priv mut registration_status : Int32?
  priv mut poll_status : Int32?
  priv mut metrics_status : Int32?
  priv mut metrics_error : String?
}

///|
/// Starts no background task; use with_client for scoped automatic polling.
pub fn Client::new(options : Options, transport? : Transport) -> Client raise {
  let max_stale_ms = options.max_stale_ms
  let started_at = @async.now()
  let instance_id = options.instance_id.unwrap_or_else(fn() {
    let rng = @random.Rand::chacha8()
    "moon-\{started_at}-\{rng.int(limit=1000000000)}-\{rng.int(limit=1000000000)}"
  })
  {
    options,
    transport: transport.unwrap_or_else(fn() { http_transport(options) }),
    store: @sdk.SnapshotStore::new(
      stale_after_ms=options.stale_after_ms,
      max_stale_ms?,
    ),
    etag: None,
    registered: false,
    registering: false,
    refreshing: false,
    closed: false,
    last_clock: started_at,
    instance_id,
    metrics: @sdk.Metrics::new(started_at),
    flushing_metrics: false,
    metrics_task: None,
    registration_status: None,
    poll_status: None,
    metrics_status: None,
    metrics_error: None,
    poll_task: None,
  }
}

///|
fn Client::now(self : Client) -> Int64 {
  // core/async.now is Unix epoch ms, not a monotonic timer. Refuse stale-clock
  // evaluation after rollback until a fresh full response reanchors freshness.
  let now = @async.now()
  if now < self.last_clock {
    self.store.invalidate_clock()
    self.etag = None
  }
  self.last_clock = now
  now
}

///|
async fn Client::send(
  self : Client,
  verb : String,
  path : String,
  body : String?,
  etag : String?,
) -> Response {
  @async.with_timeout(self.options.timeout_ms, async fn() {
    let response = (self.transport.request)(
      verb,
      self.options.base_url + path,
      body,
      etag,
    )
    if @utf8.encode(response.body).length() > self.options.max_response_bytes {
      raise @sdk.ConfigError::Invalid("transport response body budget exceeded")
    }
    response
  })
}

///|
async fn Client::register(self : Client) -> Bool {
  if self.closed || self.registered || self.registering {
    return self.registered && !self.closed
  }
  self.registering = true
  defer {
    self.registering = false
  }
  let payload = @json.Json::object(
    Map([
      ("appName", @json.Json::string(self.options.app_name)),
      ("instanceId", @json.Json::string(self.instance_id)),
      ("sdkVersion", @json.Json::string("moonunleash:0.1.0")),
      // Fixed server v7.4.0's documented interval is feature polling seconds.
      (
        "interval",
        @json.Json::number(self.options.refresh_ms.to_double() / 1000),
      ),
      // RFC3339 avoids the server OpenAPI/Joi numeric timestamp unit ambiguity.
      ("started", @json.Json::string(self.metrics.started_at())),
      (
        "strategies",
        @json.Json::array(
          [
            "default", "userWithId", "remoteAddress", "flexibleRollout", "gradualRolloutUserId",
            "gradualRolloutSessionId", "gradualRolloutRandom",
          ].map(@json.Json::string),
        ),
      ),
    ]),
  )
  self.registration_status = None
  try {
    let response = self.send(
      "POST",
      "/client/register",
      Some(payload.stringify()),
      None,
    )
    self.registration_status = Some(response.status)
    if !self.closed {
      self.registered = response.status >= 200 && response.status < 300
    }
  } catch {
    error => if @async.is_being_cancelled() { raise error }
  }
  self.registered && !self.closed
}

///|
/// Poll once, preserving the last good snapshot and ETag on any failed update.
pub async fn Client::refresh(self : Client) -> Bool {
  if self.closed || self.refreshing {
    return false
  }
  self.refreshing = true
  defer {
    self.refreshing = false
  }
  ignore(self.register())
  let _ = self.now()
  self.poll_status = None
  try {
    let r = self.send("GET", "/client/features", None, self.etag)
    self.poll_status = Some(r.status)
    if self.closed {
      return false
    }
    if r.status == 200 {
      ignore(self.store.install(r.body, self.now(), origin="remote"))
      self.etag = r.etag
      true
    } else if r.status == 304 && self.etag is Some(_) {
      self.store.revalidate(self.now())
      true
    } else {
      self.store.record_failure("http_\{r.status}")
      false
    }
  } catch {
    e => {
      // Preserve cancellation semantics rather than treating cancellation as outage.
      if @async.is_being_cancelled() {
        raise e
      }
      let message = match e {
        @sdk.ConfigError::Invalid(detail) => "invalid_configuration: \{detail}"
        @sdk.ConfigError::Unsupported(detail) =>
          "unsupported_configuration: \{detail}"
        _ => "transport_or_decode_error"
      }
      self.store.record_failure(message)
      false
    }
  }
}

///|
pub fn Client::status(self : Client) -> @sdk.Status {
  self.store.status(self.now())
}

///|
pub fn Client::is_registered(self : Client) -> Bool {
  self.registered
}

///|
fn Client::evaluate_raw(
  self : Client,
  name : String,
  ctx : @sdk.Context,
  fallback~ : Bool = false,
) -> @sdk.EvaluatedDecision {
  self.store.evaluate(
    name,
    ctx.with_defaults(
      self.options.app_name,
      environment=self.options.environment,
    ),
    self.now(),
    fallback~,
  )
}

///|
fn Client::count(
  self : Client,
  name : String,
  enabled : Bool,
  variant? : String,
) -> Unit {
  if !self.closed && !self.options.disable_metrics {
    self.metrics.count(name, enabled, variant?)
  }
}

///|
/// One public boolean decision counts one yes/no; only get_variant counts variants.
pub fn Client::evaluate(
  self : Client,
  name : String,
  ctx : @sdk.Context,
  fallback~ : Bool = false,
) -> @sdk.EvaluatedDecision {
  let result = self.evaluate_raw(name, ctx, fallback~)
  self.count(name, result.decision.enabled)
  result
}

///|
pub fn Client::is_enabled(
  self : Client,
  name : String,
  ctx : @sdk.Context,
  fallback~ : Bool = false,
) -> Bool {
  let enabled = self.evaluate_raw(name, ctx, fallback~).decision.enabled
  self.count(name, enabled)
  enabled
}

///|
pub fn Client::evaluate_many(
  self : Client,
  names : Array[String],
  ctx : @sdk.Context,
  fallback~ : Bool = false,
) -> @sdk.BatchDecision {
  let result = self.store.evaluate_many(
    names,
    ctx.with_defaults(
      self.options.app_name,
      environment=self.options.environment,
    ),
    self.now(),
    fallback~,
  )
  for i = 0; i < names.length(); i = i + 1 {
    let decision = result.decisions[i]
    self.count(names[i], decision.enabled)
  }
  result
}

///|
pub fn Client::get_variant(
  self : Client,
  name : String,
  ctx : @sdk.Context,
) -> @sdk.Variant {
  let variant = self.store.get_variant(
    name,
    ctx.with_defaults(
      self.options.app_name,
      environment=self.options.environment,
    ),
    self.now(),
  )
  self.count(name, variant.feature_enabled, variant=variant.name)
  variant
}

///|
pub fn Client::instance_id(self : Client) -> String {
  self.instance_id
}

///|
pub fn Client::last_registration_status(self : Client) -> Int32? {
  self.registration_status
}

///|
pub fn Client::last_poll_status(self : Client) -> Int32? {
  self.poll_status
}

///|
pub fn Client::last_metrics_status(self : Client) -> Int32? {
  self.metrics_status
}

///|
/// Metrics failures are isolated from configuration readiness/freshness.
pub fn Client::metrics_error(self : Client) -> String? {
  self.metrics_error
}

///|
/// Freeze/send one bounded bucket. Only classic metrics 202 acknowledges it.
/// Failures retain the exact pending bucket while new calls collect separately.
/// Retrying an ambiguous response is at-least-once, never exactly-once delivery.
pub async fn Client::flush_metrics(self : Client) -> Bool {
  if self.closed || self.flushing_metrics {
    return false
  }
  if self.options.disable_metrics {
    return true
  }
  self.flushing_metrics = true
  defer {
    self.flushing_metrics = false
  }
  try {
    guard self.metrics.prepare(self.now()) is Some(bucket) else {
      self.metrics_error = None
      return true
    }
    if !self.register() {
      self.metrics_error = Some("metrics_registration_unavailable")
      return false
    }
    let payload = @json.Json::object(
      Map([
        ("appName", @json.Json::string(self.options.app_name)),
        ("instanceId", @json.Json::string(self.instance_id)),
        ("sdkVersion", @json.Json::string("moonunleash:0.1.0")),
        ("bucket", @json.parse(bucket)),
      ]),
    )
    self.metrics_status = None
    let response = self.send(
      "POST",
      "/client/metrics",
      Some(payload.stringify()),
      None,
    )
    self.metrics_status = Some(response.status)
    if self.closed {
      return false
    }
    if response.status == 202 {
      self.metrics.acknowledge()
      self.metrics_error = None
      true
    } else {
      self.metrics_error = Some("metrics_http_\{response.status}")
      false
    }
  } catch {
    error => {
      if @async.is_being_cancelled() {
        raise error
      }
      self.metrics_error = Some("metrics_transport_clock_or_decode_error")
      false
    }
  }
}

///|
pub async fn Client::wait_ready(
  self : Client,
  timeout_ms~ : Int32 = 10000,
) -> Unit {
  @async.with_timeout(timeout_ms, async fn() {
    while !self.status().ready {
      if self.closed {
        raise @sdk.ConfigError::Invalid("client closed while waiting")
      }
      @async.sleep(10)
    }
  })
}

///|
pub fn Client::close(self : Client) -> Unit {
  self.closed = true
  if self.poll_task is Some(task) {
    task.cancel()
  }
  self.poll_task = None
  if self.metrics_task is Some(task) {
    task.cancel()
  }
  self.metrics_task = None
  self.etag = None
  self.store.close()
}

///|
/// Poller cancellation and in-flight connections are scoped to this callback.
pub async fn with_client(
  options : Options,
  callback : async (Client) -> Unit,
  transport? : Transport,
) -> Unit {
  let client = Client::new(options, transport?)
  defer client.close()
  @async.with_task_group() <| group => {
    let task = group.spawn(async fn() {
      let rng = @random.Rand::chacha8()
      let mut retry_ms = 1000
      while !client.closed {
        let ok = client.refresh()
        if ok {
          retry_ms = 1000
        }
        let delay = if ok {
          options.refresh_ms
        } else {
          retry_ms + rng.int(limit=retry_ms / 4 + 1)
        }
        if !ok {
          retry_ms = if retry_ms >= 30000 { 60000 } else { retry_ms * 2 }
        }
        @async.sleep(delay)
      }
    })
    client.poll_task = Some(task)
    if !options.disable_metrics {
      client.metrics_task = Some(
        group.spawn(async fn() {
          while !client.closed {
            @async.sleep(options.metrics_ms)
            if !client.closed {
              ignore(client.flush_metrics())
            }
          }
        }),
      )
    }
    callback(client)
    group.return_immediately()
  }
}
