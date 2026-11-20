///|
async fn main {
  @async.with_timeout(15000, run)
}

///|
// Bound the complete sequence, not only individual HTTP requests.
async fn run() -> Unit {
  let args = @env.args()
  guard args.length() == 2 else {
    fail(
      "usage: moon run cmd/http-smoke --target wasm -- http://127.0.0.1:PORT",
    )
  }
  let base = args[1]
  let options = @online.Options::new(
    base + "/flow",
    "http-smoke",
    "not-a-secret",
    allow_http_loopback=true,
    timeout_ms=1000,
  )
  let client = @online.Client::new(options)
  defer client.close()
  let expected = [true, true, false, false, true, false]
  let generations = [1L, 1L, 1L, 1L, 2L, 2L]
  let checks : Array[@json.Json] = []
  for i = 0; i < expected.length(); i = i + 1 {
    let accepted = client.refresh()
    assert_eq(accepted, expected[i])
    assert_true(client.is_registered())
    assert_eq(client.status().generation, generations[i])
    assert_eq(client.is_enabled("checkout", @sdk.Context::new()), i < 4)
    checks.push(
      @json.Json::object(
        Map([
          ("step", @json.Json::number(i.to_double() + 1)),
          ("accepted", @json.Json::boolean(accepted)),
          (
            "generation",
            @json.Json::number(client.status().generation.to_double()),
          ),
          (
            "enabled",
            @json.Json::boolean(
              client.is_enabled("checkout", @sdk.Context::new()),
            ),
          ),
        ]),
      ),
    )
  }
  let small = @online.Client::new(
    @online.Options::new(
      base + "/large",
      "body-limit",
      "not-a-secret",
      allow_http_loopback=true,
      max_response_bytes=128,
      timeout_ms=1000,
    ),
  )
  defer small.close()
  assert_false(small.refresh())
  assert_false(small.status().ready)
  println(
    @json.Json::object(
      Map([
        ("kind", @json.Json::string("real-http-mock-server-smoke")),
        ("checks", @json.Json::array(checks)),
        ("oversize_rejected", @json.Json::boolean(true)),
      ]),
    ).stringify(),
  )
}
