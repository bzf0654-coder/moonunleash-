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
  }
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
      let conn = @http.request(
        if verb == "POST" {
          Post
        } else {
          Get
        },
        url,
        headers~,
      )
      defer conn.close()
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
pub struct Client {
  priv options : Options
  priv transport : Transport
  priv store : @sdk.SnapshotStore
  priv mut etag : String?
  priv mut registered : Bool
  priv mut refreshing : Bool
  priv mut closed : Bool
  priv mut last_clock : Int64
  priv mut poll_task : @async.Task[Unit]?
  priv started_at : Int64
}

///|
/// Starts no background task; use with_client for scoped automatic polling.
pub fn Client::new(options : Options, transport? : Transport) -> Client raise {
  let max_stale_ms = options.max_stale_ms
  let started_at = @async.now()
  {
    options,
    transport: transport.unwrap_or_else(fn() { http_transport(options) }),
    store: @sdk.SnapshotStore::new(
      stale_after_ms=options.stale_after_ms,
      max_stale_ms?,
    ),
    etag: None,
    registered: false,
    refreshing: false,
    closed: false,
    last_clock: started_at,
    started_at,
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
/// Poll once, preserving the last good snapshot and ETag on any failed update.
pub async fn Client::refresh(self : Client) -> Bool {
  if self.closed || self.refreshing {
    return false
  }
  self.refreshing = true
  defer {
    self.refreshing = false
  }
  if !self.registered {
    let payload : @json.Json = @json.Json::object(
      Map([
        ("appName", @json.Json::string(self.options.app_name)),
        ("sdkVersion", @json.Json::string("moonunleash:0.1.0")),
        (
          "interval",
          @json.Json::number(self.options.refresh_ms.to_double() / 1000),
        ),
        ("started", @json.Json::number(self.started_at.to_double() / 1000)),
        (
          "strategies",
          @json.Json::array(
            [
              "default", "userWithId", "flexibleRollout", "gradualRolloutUserId",
              "gradualRolloutSessionId", "gradualRolloutRandom",
            ].map(@json.Json::string),
          ),
        ),
      ]),
    )
    try {
      let r = self.send(
        "POST",
        "/client/register",
        Some(payload.stringify()),
        None,
      )
      self.registered = r.status >= 200 && r.status < 300
    } catch {
      error => if @async.is_being_cancelled() { raise error }
    }
  }
  let _ = self.now()
  try {
    let r = self.send("GET", "/client/features", None, self.etag)
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
pub fn Client::evaluate(
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
pub fn Client::is_enabled(
  self : Client,
  name : String,
  ctx : @sdk.Context,
  fallback~ : Bool = false,
) -> Bool {
  self.evaluate(name, ctx, fallback~).decision.enabled
}

///|
pub fn Client::evaluate_many(
  self : Client,
  names : Array[String],
  ctx : @sdk.Context,
  fallback~ : Bool = false,
) -> @sdk.BatchDecision {
  self.store.evaluate_many(
    names,
    ctx.with_defaults(
      self.options.app_name,
      environment=self.options.environment,
    ),
    self.now(),
    fallback~,
  )
}

///|
pub fn Client::get_variant(
  self : Client,
  name : String,
  ctx : @sdk.Context,
) -> @sdk.Variant {
  self.store.get_variant(
    name,
    ctx.with_defaults(
      self.options.app_name,
      environment=self.options.environment,
    ),
    self.now(),
  )
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
    callback(client)
    group.return_immediately()
  }
}
