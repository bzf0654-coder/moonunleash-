// SPDX-License-Identifier: Apache-2.0

///|
fn online_metrics_field(value : @json.Json, key : String) -> @json.Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(@json.Json::null())
    _ => @json.Json::null()
  }
}

///|
fn online_metrics_number(value : @json.Json, expected : Double) -> Unit raise {
  guard value is Number(actual, ..) else { fail("expected numeric counter") }
  assert_eq(actual, expected)
}

///|
async test "metrics count each public result once and register stable ISO identity" {
  let sent : Array[String] = []
  let registrations : Array[@json.Json] = []
  let transport = @online.Transport::{
    request: async fn(verb, url, body, _) {
      @async.pause()
      if verb == "GET" {
        return { status: 200, body: good, etag: Some("v1"), }
      }
      guard body is Some(payload) else { fail("POST body required") }
      if url.has_suffix("/client/register") {
        registrations.push(@json.parse(payload))
      } else {
        assert_true(url.has_suffix("/client/metrics"))
        sent.push(payload)
      }
      { status: 202, body: "", etag: None, }
    },
  }
  let client = @online.Client::new(options(), transport~)
  defer client.close()
  assert_true(client.refresh())
  assert_eq(client.last_registration_status(), Some(202))
  assert_eq(client.last_poll_status(), Some(200))
  assert_true(client.is_enabled("checkout", @sdk.Context::new()))
  ignore(client.evaluate("checkout", @sdk.Context::new()))
  ignore(client.get_variant("checkout", @sdk.Context::new()))
  ignore(client.evaluate_many(["checkout", "missing"], @sdk.Context::new()))
  assert_true(client.flush_metrics())
  assert_eq(client.last_metrics_status(), Some(202))
  assert_eq(client.metrics_error(), None)
  assert_eq(registrations.length(), 1)
  let registered = registrations[0]
  assert_eq(
    online_metrics_field(registered, "instanceId"),
    @json.Json::string(client.instance_id()),
  )
  online_metrics_number(online_metrics_field(registered, "interval"), 0.01)
  guard online_metrics_field(registered, "started") is String(started) else {
    fail("RFC3339 required")
  }
  assert_true(started.has_suffix("Z"))
  assert_true(started.contains("T"))
  guard online_metrics_field(registered, "strategies") is Array(strategies) else {
    fail("strategies required")
  }
  assert_true(strategies.contains(@json.Json::string("remoteAddress")))
  assert_eq(sent.length(), 1)
  let payload = @json.parse(sent[0])
  assert_eq(
    online_metrics_field(payload, "instanceId"),
    online_metrics_field(registered, "instanceId"),
  )
  let toggles = online_metrics_field(
    online_metrics_field(payload, "bucket"),
    "toggles",
  )
  let checkout = online_metrics_field(toggles, "checkout")
  online_metrics_number(online_metrics_field(checkout, "yes"), 4)
  online_metrics_number(online_metrics_field(checkout, "no"), 0)
  online_metrics_number(
    online_metrics_field(online_metrics_field(checkout, "variants"), "disabled"),
    1,
  )
  let missing = online_metrics_field(toggles, "missing")
  online_metrics_number(online_metrics_field(missing, "no"), 1)
  assert_eq(
    online_metrics_field(missing, "variants"),
    @json.Json::object(Map([])),
  )
  assert_true(client.flush_metrics())
  assert_eq(sent.length(), 1)
}

///|
async test "metrics errors retain frozen pending counts while active calls and busy flush survive" {
  let sent : Array[String] = []
  let statuses = [503, 204, 202, 202]
  let mut captured : @online.Client? = None
  let transport = @online.Transport::{
    request: async fn(verb, url, body, _) {
      @async.pause()
      if verb == "GET" {
        return { status: 200, body: good, etag: Some("v1"), }
      }
      if url.has_suffix("/client/register") {
        return { status: 202, body: "", etag: None, }
      }
      guard body is Some(payload) else { fail("missing metrics") }
      sent.push(payload)
      if sent.length() == 1 {
        guard captured is Some(client) else { fail("client not captured") }
        assert_true(client.is_enabled("checkout", @sdk.Context::new()))
        assert_false(client.flush_metrics())
      }
      { status: statuses[sent.length() - 1], body: "", etag: None, }
    },
  }
  let client = @online.Client::new(options(), transport~)
  captured = Some(client)
  defer client.close()
  assert_true(client.refresh())
  assert_true(client.is_enabled("checkout", @sdk.Context::new()))
  assert_false(client.flush_metrics())
  assert_eq(client.metrics_error(), Some("metrics_http_503"))
  assert_false(client.flush_metrics())
  assert_eq(client.metrics_error(), Some("metrics_http_204"))
  assert_true(client.flush_metrics())
  assert_eq(sent.length(), 3)
  assert_eq(sent[0], sent[1])
  assert_eq(sent[0], sent[2])
  assert_true(client.flush_metrics())
  assert_eq(sent.length(), 4)
  for payload in [sent[0], sent[3]] {
    let toggles = online_metrics_field(
      online_metrics_field(@json.parse(payload), "bucket"),
      "toggles",
    )
    online_metrics_number(
      online_metrics_field(online_metrics_field(toggles, "checkout"), "yes"),
      1,
    )
  }
  assert_eq(client.status().generation, 1L)
  assert_eq(client.status().consecutive_failures, 0)
  assert_true(client.status().ready)
  client.close()
  assert_false(client.flush_metrics())
}

///|
async test "disabled metrics performs no metrics request or implicit registration on flush" {
  let mut calls = 0
  let transport = @online.Transport::{
    request: async fn(_, _, _, _) {
      @async.pause()
      calls = calls + 1
      { status: 202, body: "", etag: None, }
    },
  }
  let disabled = @online.Options::new(
    "http://127.0.0.1:4242/api",
    "tests",
    "token",
    allow_http_loopback=true,
    disable_metrics=true,
  )
  let client = @online.Client::new(disabled, transport~)
  defer client.close()
  ignore(client.evaluate("missing", @sdk.Context::new()))
  assert_true(client.flush_metrics())
  assert_eq(calls, 0)
  assert_eq(client.last_metrics_status(), None)
}

///|
async test "scoped metrics sender is cancelled on callback exit without leaking tasks" {
  let mut in_flight = false
  let mut cleaned = false
  let transport = @online.Transport::{
    request: async fn(verb, url, _, _) {
      if verb == "GET" {
        return { status: 200, body: good, etag: Some("v1"), }
      }
      if url.has_suffix("/client/register") {
        return { status: 202, body: "", etag: None, }
      }
      in_flight = true
      defer {
        in_flight = false
        cleaned = true
      }
      @async.sleep(60000)
      { status: 202, body: "", etag: None, }
    },
  }
  let settings = @online.Options::new(
    "http://127.0.0.1:4242/api",
    "tests",
    "token",
    allow_http_loopback=true,
    refresh_ms=10000,
    metrics_ms=1,
  )
  @online.with_client(
    settings,
    async fn(client) {
      client.wait_ready(timeout_ms=1000)
      assert_true(client.is_enabled("checkout", @sdk.Context::new()))
      @async.with_timeout(1000, async fn() {
        while !in_flight {
          @async.sleep(1)
        }
      })
    },
    transport~,
  )
  assert_false(in_flight)
  assert_true(cleaned)
}

///|
test "metrics identity and scheduling options reject invalid values" {
  for id in ["", "bad\r\nId", "x".repeat(129)] {
    let rejected = try {
      ignore(
        @online.Options::new(
          "http://127.0.0.1/api",
          "tests",
          "token",
          allow_http_loopback=true,
          instance_id=id,
        ),
      )
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  let rejected = try {
    ignore(
      @online.Options::new(
        "http://127.0.0.1/api",
        "tests",
        "token",
        allow_http_loopback=true,
        metrics_ms=0,
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
