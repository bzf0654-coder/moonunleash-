// Actual SDK -> actual Unleash acceptance. No mock responses or Node proxy.

///|
struct Observations {
  mut full_body : String
  mut before_install_generation : Int64
  mut polls : Int32
  mut saw_304 : Bool
}

///|
fn required_env(name : String) -> String raise {
  match @env.get_env_var(name) {
    Some(value) => value
    None => fail("required acceptance environment: \{name}")
  }
}

///|
fn object(fields : Array[(String, @json.Json)]) -> @json.Json {
  @json.Json::object(Map(fields))
}

///|
fn optional_string(value : String?) -> @json.Json {
  match value {
    Some(text) => @json.Json::string(text)
    None => @json.Json::null()
  }
}

///|
fn field(value : @json.Json, name : String) -> @json.Json {
  match value {
    Object(fields) => fields.get(name).unwrap_or(@json.Json::null())
    _ => @json.Json::null()
  }
}

///|
fn parent_enabled(body : String, expected : Bool) -> Bool raise {
  if body == "" {
    return false
  }
  match field(@json.parse(body), "features") {
    Array(features) =>
      features.any(fn(feature) {
        field(feature, "name") == @json.Json::string("ci-parent") &&
        field(feature, "enabled") == @json.Json::boolean(expected)
      })
    _ => false
  }
}

///|
// Separate loopback control plane. Never sends a /client request to Node.
async fn control(base : String, operation : String, body : @json.Json) -> Unit {
  @async.with_timeout(130000, async fn() {
    let rest = match base.split_once("://") {
      Some(("http", value)) => value
      _ => fail("control endpoint must be loopback HTTP")
    }
    let (host, prefix) = match rest.split_once("/") {
      Some((host, path)) => (host.to_owned(), "/\{path}")
      None => fail("control nonce path required")
    }
    assert_true(host.has_prefix("127.0.0.1:"))
    let headers : @http.Headers = Map([
      (@http.CaseInsensitiveString("Content-Type"), "application/json"),
    ])
    let conn = @http.ClientConnection("http://\{host}", headers~)
    defer conn.close()
    conn.request(Post, prefix + "/" + operation)
    conn.write(@utf8.encode(body.stringify()))
    let response = conn.end_request()
    while conn.read() is Some(_) {

    }
    assert_eq(response.code, 200, msg="control operation \{operation}")
  })
}

///|
async fn checkpoint(base : String, operation : String) -> Unit {
  control(base, operation, object([]))
}

///|
async fn wait_parent(
  seen : Observations,
  client : @online.Client,
  expected : Bool,
) -> Unit {
  @async.with_timeout(30000, async fn() {
    // A transport observation precedes SnapshotStore installation. Wait for both
    // the expected real response AND its subsequent committed generation.
    while !parent_enabled(seen.full_body, expected) ||
          client.status().generation <= seen.before_install_generation {
      @async.sleep(20)
    }
  })
}

///|
fn recommendation_state(
  body : String,
  enabled : Bool,
  rollout : String,
) -> Bool raise {
  if body == "" {
    return false
  }
  match field(@json.parse(body), "features") {
    Array(features) =>
      features.any(fn(feature) {
        if field(feature, "name") != @json.Json::string("recommendation-ab") ||
          field(feature, "enabled") != @json.Json::boolean(enabled) {
          return false
        }
        if !enabled {
          return true
        }
        match field(feature, "strategies") {
          Array(strategies) if strategies.length() == 1 =>
            field(field(strategies[0], "parameters"), "rollout") ==
            @json.Json::string(rollout)
          _ => false
        }
      })
    _ => false
  }
}

///|
async fn wait_recommendation(
  seen : Observations,
  client : @online.Client,
  enabled : Bool,
  rollout : String,
) -> Unit {
  @async.with_timeout(30000, async fn() {
    while !recommendation_state(seen.full_body, enabled, rollout) ||
          client.status().generation <= seen.before_install_generation {
      @async.sleep(20)
    }
  })
}

///|
fn recommendation_result(value : @sdk.Variant) -> @json.Json {
  object([
    ("name", @json.Json::string(value.name)),
    ("enabled", @json.Json::boolean(value.enabled)),
    ("feature_enabled", @json.Json::boolean(value.feature_enabled)),
    (
      "payload",
      optional_string(value.payload.map(fn(payload) { payload.value })),
    ),
  ])
}

///|
fn check_variant(
  value : @sdk.Variant,
  name : String,
  payload : String,
) -> Unit raise {
  assert_true(value.enabled)
  assert_true(value.feature_enabled)
  assert_eq(value.name, name)
  guard value.payload is Some(actual) else { fail("variant payload missing") }
  assert_eq(actual.kind, "string")
  assert_eq(actual.value, payload)
}

///|
fn check_disabled(value : @sdk.Variant) -> Unit raise {
  assert_false(value.enabled)
  assert_false(value.feature_enabled)
  assert_eq(value.name, "disabled")
  assert_true(value.payload is None)
}

///|
fn status_json(client : @online.Client) -> @json.Json {
  let status = client.status()
  object([
    ("ready", @json.Json::boolean(status.ready)),
    ("generation", @json.Json::number(status.generation.to_double())),
    ("failures", @json.Json::number(status.consecutive_failures.to_double())),
    ("error", optional_string(status.last_error)),
  ])
}

///|
async fn main {
  let base = required_env("REAL_SERVER_URL")
  let control_url = required_env("REAL_CONTROL_URL")
  let app_name = required_env("REAL_APP_NAME")
  let instance_id = required_env("REAL_INSTANCE_ID")
  let options = @online.Options::new(
    base,
    app_name,
    required_env("REAL_BACKEND_TOKEN"),
    environment="development",
    instance_id~,
    refresh_ms=100,
    timeout_ms=1000,
    metrics_ms=3600000,
    allow_http_loopback=true,
  )
  let seen : Observations = {
    full_body: "",
    before_install_generation: 0L,
    polls: 0,
    saw_304: false,
  }
  let mut observed_client : @online.Client? = None
  let direct = @online.Transport::http(options)
  let transport = @online.Transport::{
    request: async fn(verb, url, body, etag) {
      // The request uses the SDK's REAL HTTP adapter, direct to Unleash.
      let response = (direct.request)(verb, url, body, etag)
      // Copies only: never change, replace, synthesize, or route the Response via Node.
      control(
        control_url,
        "wire",
        object([
          ("method", @json.Json::string(verb)),
          ("url", @json.Json::string(url)),
          ("requestBody", optional_string(body)),
          ("ifNoneMatch", optional_string(etag)),
          ("status", @json.Json::number(response.status.to_double())),
          ("responseBody", @json.Json::string(response.body)),
          ("responseETag", optional_string(response.etag)),
        ]),
      )
      if url.has_suffix("/client/features") {
        if response.status == 200 {
          seen.before_install_generation = match observed_client {
            Some(client) => client.status().generation
            None => 0L
          }
          seen.full_body = response.body
        }
        if response.status == 304 {
          seen.saw_304 = true
        }
        seen.polls = seen.polls + 1
      }
      response
    },
  }
  @online.with_client(
    options,
    async fn(client) {
      observed_client = Some(client)
      client.wait_ready(timeout_ms=30000)
      assert_true(client.is_registered())
      assert_eq(client.instance_id(), instance_id)
      assert_eq(client.last_registration_status(), Some(202))
      checkpoint(control_url, "registered")
      @async.with_timeout(30000, async fn() {
        while !seen.saw_304 {
          @async.sleep(20)
        }
      })
      wait_parent(seen, client, true)
      let allowed = @sdk.Context::new(user_id="allowed-user")
      let denied = @sdk.Context::new(user_id="denied-user")

      // The application example is evaluated from REAL received response bytes,
      // without mutating JSON or adding calls to the client's two-flag metrics.
      let enterprise = @sdk.Context::parse(
        "{\"userId\":\"user-1\",\"properties\":{\"plan\":\"enterprise\"}}",
      )
      let enterprise_2 = @sdk.Context::parse(
        "{\"userId\":\"user-2\",\"properties\":{\"plan\":\"enterprise\"}}",
      )
      let free = @sdk.Context::parse(
        "{\"userId\":\"user-1\",\"properties\":{\"plan\":\"free\"}}",
      )
      let missing_user = @sdk.Context::parse(
        "{\"properties\":{\"plan\":\"enterprise\"}}",
      )
      wait_recommendation(seen, client, true, "100")
      let recommendation = @sdk.Snapshot::parse(seen.full_body)
      let control_variant = recommendation.get_variant(
        "recommendation-ab", enterprise,
      )
      let treatment_variant = recommendation.get_variant(
        "recommendation-ab", enterprise_2,
      )
      let free_variant = recommendation.get_variant("recommendation-ab", free)
      let missing_variant = recommendation.get_variant(
        "recommendation-ab", missing_user,
      )
      let unknown_variant = recommendation.get_variant(
        "unknown-feature", enterprise,
      )
      check_variant(control_variant, "control", "baseline")
      check_variant(treatment_variant, "treatment", "model-v2")
      check_disabled(free_variant)
      check_disabled(missing_variant)
      check_disabled(unknown_variant)
      control(
        control_url,
        "recommendation",
        object([
          (
            "cases",
            @json.Json::array([
              recommendation_result(control_variant),
              recommendation_result(treatment_variant),
              recommendation_result(free_variant),
              recommendation_result(missing_variant),
              recommendation_result(unknown_variant),
            ]),
          ),
        ]),
      )
      // The Node Admin control switches the actual flag off, then sets its
      // actual strategy to rollout=0 and re-enables it. No synthetic snapshots.
      wait_recommendation(seen, client, false, "100")
      let off_variant = @sdk.Snapshot::parse(seen.full_body).get_variant(
        "recommendation-ab", enterprise,
      )
      check_disabled(off_variant)
      control(
        control_url,
        "recommendation-off",
        object([
          ("cases", @json.Json::array([recommendation_result(off_variant)])),
        ]),
      )
      wait_recommendation(seen, client, true, "0")
      let zero_variant = @sdk.Snapshot::parse(seen.full_body).get_variant(
        "recommendation-ab", enterprise,
      )
      check_disabled(zero_variant)
      control(
        control_url,
        "recommendation-zero",
        object([
          ("cases", @json.Json::array([recommendation_result(zero_variant)])),
        ]),
      )

      // Fixed public calls. Wait predicates never evaluate, so counts are independent.
      // Baseline: parent yes=2 blue=1; child yes=3 no=1 gold=1.
      check_variant(
        client.get_variant("ci-parent", allowed),
        "blue",
        "parent-blue",
      )
      check_variant(
        client.get_variant("ci-child", allowed),
        "gold",
        "child-gold",
      )
      assert_false(client.is_enabled("ci-child", denied))
      let evaluated = client.evaluate("ci-child", allowed)
      assert_true(evaluated.decision.enabled)
      assert_true(evaluated.decision.reason != "")
      let batch = client.evaluate_many(["ci-parent", "ci-child"], allowed)
      assert_eq(batch.decisions.length(), 2)
      assert_true(batch.decisions[0].enabled)
      assert_true(batch.decisions[1].enabled)
      checkpoint(control_url, "baseline")

      checkpoint(control_url, "off")
      wait_parent(seen, client, false)
      assert_false(client.is_enabled("ci-parent", allowed))
      check_disabled(client.get_variant("ci-child", allowed))
      checkpoint(control_url, "off-seen")
      checkpoint(control_url, "on")
      wait_parent(seen, client, true)
      check_variant(
        client.get_variant("ci-child", allowed),
        "gold",
        "child-gold",
      )
      checkpoint(control_url, "on-seen")
      assert_true(client.flush_metrics())
      assert_eq(client.last_metrics_status(), Some(202))
      assert_eq(client.metrics_error(), None)
      // Node independently checks exact counters and WAITS FOR REAL DB PERSISTENCE.
      checkpoint(control_url, "persisted")

      let generation = client.status().generation
      checkpoint(control_url, "stop")
      @async.with_timeout(30000, async fn() {
        while client.status().consecutive_failures == 0 {
          @async.sleep(20)
        }
      })
      let outage = client.status()
      assert_true(outage.ready)
      assert_eq(outage.generation, generation)
      assert_true(outage.last_error is Some(_))
      check_variant(
        client.get_variant("ci-child", allowed),
        "gold",
        "child-gold",
      )
      assert_true(client.is_enabled("ci-parent", allowed))
      control(control_url, "outage-seen", status_json(client))

      let polls_before_restart = seen.polls
      checkpoint(control_url, "start")
      // No refresh() call: recovery must be by the same scoped background poller.
      @async.with_timeout(60000, async fn() {
        while seen.polls <= polls_before_restart ||
              client.status().consecutive_failures != 0 {
          @async.sleep(20)
        }
      })
      assert_true(client.status().ready)
      assert_eq(client.status().last_error, None)
      assert_eq(client.instance_id(), instance_id)
      control(control_url, "recovered", status_json(client))
      checkpoint(control_url, "off-again")
      wait_parent(seen, client, false)
      check_disabled(client.get_variant("ci-child", allowed))
      checkpoint(control_url, "off-again-seen")
      checkpoint(control_url, "on-again")
      wait_parent(seen, client, true)
      check_variant(
        client.get_variant("ci-child", allowed),
        "gold",
        "child-gold",
      )
      checkpoint(control_url, "on-again-seen")
      // Exit-time flush. Cumulative: parent yes=3 no=1 blue=1;
      // child yes=6 no=3 gold=4 disabled=2. Internal parent evaluation adds nothing.
      assert_true(client.flush_metrics())
      assert_eq(client.last_metrics_status(), Some(202))
      assert_eq(client.metrics_error(), None)
      checkpoint(control_url, "final-persisted")
      checkpoint(control_url, "complete")
      println(
        object([
          ("kind", @json.Json::string("real-unleash-7.4.0-client-complete")),
          ("appName", @json.Json::string(app_name)),
          ("instanceId", @json.Json::string(instance_id)),
          ("status", status_json(client)),
        ]).stringify(),
      )
    },
    transport~,
  )
}
