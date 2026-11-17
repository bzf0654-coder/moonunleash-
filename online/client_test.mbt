///|
let good : String =
  #|{"version":2,"features":[{"name":"checkout","enabled":true,"strategies":[{"name":"default"}]}]}

///|
fn options(timeout_ms~ : Int32 = 500) -> @online.Options raise {
  @online.Options::new(
    "http://127.0.0.1:4242/api/",
    "tests",
    "not-a-real-token",
    allow_http_loopback=true,
    refresh_ms=10,
    timeout_ms~,
  )
}

///|
async test "refresh installs once; 304 revalidates; invalid and HTTP errors preserve snapshot and etag" {
  let mut calls = 0
  let seen : Array[String?] = []
  let responses : Array[@online.Response] = [
    { status: 200, body: good, etag: Some("v1"), },
    { status: 304, body: "", etag: None, },
    { status: 200, body: "broken", etag: Some("bad"), },
    { status: 503, body: "", etag: None, },
    { status: 200, body: good, etag: Some("v2"), },
  ]
  let transport = @online.Transport::{
    request: async fn(verb, url, body, etag) {
      @async.pause()
      if verb == "POST" {
        assert_true(url.has_suffix("/client/register"))
        guard body is Some(payload) else { fail("missing registration body") }
        assert_true(payload.contains("tests"))
        return { status: 202, body: "", etag: None, }
      }
      seen.push(etag)
      let r = responses[calls]
      calls = calls + 1
      r
    },
  }
  let client = @online.Client::new(options(), transport~)
  defer client.close()
  assert_false(client.status().ready)
  assert_true(client.refresh())
  assert_true(client.is_registered())
  assert_eq(client.status().generation, 1L)
  assert_true(client.refresh())
  assert_eq(client.status().generation, 1L)
  assert_false(client.refresh())
  assert_false(client.refresh())
  assert_eq(client.status().generation, 1L)
  assert_true(client.is_enabled("checkout", @sdk.Context::new()))
  assert_eq(client.status().consecutive_failures, 2)
  assert_true(client.refresh())
  assert_eq(client.status().generation, 2L)
  assert_eq(seen, [None, Some("v1"), Some("v1"), Some("v1"), Some("v1")])
}

///|
async test "unsolicited 304 cannot make client ready" {
  let transport = @online.Transport::{
    request: async fn(_, _, _, _) {
      @async.pause()
      { status: 304, body: "", etag: None, }
    },
  }
  let client = @online.Client::new(options(), transport~)
  defer client.close()
  assert_false(client.refresh())
  assert_false(client.status().ready)
  assert_eq(client.status().generation, 0L)
}

///|
async test "timeout remains observable without becoming ready" {
  let transport = @online.Transport::{
    request: async fn(verb, _, _, _) {
      @async.pause()
      if verb == "POST" {
        return { status: 202, body: "", etag: None, }
      }
      @async.sleep(1000)
      { status: 200, body: good, etag: None, }
    },
  }
  let client = @online.Client::new(options(timeout_ms=5), transport~)
  defer client.close()
  assert_false(client.refresh())
  assert_false(client.status().ready)
  assert_eq(client.status().consecutive_failures, 1)
}

///|
async test "scoped poller becomes ready and closes on callback exit" {
  let transport = @online.Transport::{
    request: async fn(verb, _, _, _) {
      @async.pause()
      if verb == "POST" {
        return { status: 202, body: "", etag: None, }
      }
      { status: 200, body: good, etag: Some("v1"), }
    },
  }
  let mut captured : @online.Client? = None
  @online.with_client(
    options(),
    async fn(client) {
      captured = Some(client)
      client.wait_ready(timeout_ms=500)
      assert_true(client.is_enabled("checkout", @sdk.Context::new()))
    },
    transport~,
  )
  guard captured is Some(client) else { fail("callback not entered") }
  assert_true(client.status().closed)
  assert_false(client.refresh())
}

///|
async test "scope cancels in-flight request and executes cleanup" {
  let mut in_flight = false
  let mut cleaned = false
  let transport = @online.Transport::{
    request: async fn(verb, _, _, _) {
      @async.pause()
      if verb == "POST" {
        return { status: 202, body: "", etag: None, }
      }
      in_flight = true
      defer {
        cleaned = true
        in_flight = false
      }
      @async.sleep(60000)
      { status: 200, body: good, etag: None, }
    },
  }
  @online.with_client(
    options(),
    async fn(_) {
      @async.with_timeout(500, async fn() {
        while !in_flight {
          @async.sleep(1)
        }
      })
    },
    transport~,
  )
  assert_true(cleaned)
  assert_false(in_flight)
}

///|
async test "explicit close cancels scoped polling immediately" {
  let mut in_flight = false
  let mut cleaned = false
  let transport = @online.Transport::{
    request: async fn(_, _, _, _) {
      in_flight = true
      defer {
        cleaned = true
        in_flight = false
      }
      @async.sleep(60000)
      { status: 200, body: good, etag: None, }
    },
  }
  @online.with_client(
    options(),
    async fn(client) {
      @async.with_timeout(500, async fn() {
        while !in_flight {
          @async.sleep(1)
        }
      })
      client.close()
      @async.with_timeout(500, async fn() {
        while !cleaned {
          @async.sleep(1)
        }
      })
      assert_true(client.status().closed)
    },
    transport~,
  )
  assert_true(cleaned)
}

///|
async test "wait_ready has a bounded timeout" {
  let client = @online.Client::new(options())
  defer client.close()
  let timed_out = try {
    client.wait_ready(timeout_ms=5)
    false
  } catch {
    _ => true
  }
  assert_true(timed_out)
  assert_false(client.status().ready)
}

///|
test "secure options reject unsafe URLs and header injection" {
  for
    url in [
      "http://evil.example/api", "https://user:secret@example.com/api", "https://example.com/api?token=x",
      "https://example.com/api#x", "https://example.com\\@evil/api",
    ] {
    let rejected = try {
      ignore(
        @online.Options::new(url, "app", "token", allow_http_loopback=true),
      )
      false
    } catch {
      _ => true
    }
    assert_true(rejected, msg=url)
  }
  let rejected = try {
    ignore(
      @online.Options::new(
        "https://example.com/api", "app", "secret\r\nX-Evil: true",
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
