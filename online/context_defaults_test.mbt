///|
async test "every online evaluation entry applies defaults without overriding callers" {
  let source =
    #|{"version":2,"features":[{"name":"default-env","enabled":true,"strategies":[{"name":"default","constraints":[{"contextName":"appName","operator":"IN","values":["tests"]},{"contextName":"environment","operator":"IN","values":["default"]}]}],"variants":[{"name":"yes","weight":1000}]},{"name":"production-env","enabled":true,"strategies":[{"name":"default","constraints":[{"contextName":"appName","operator":"IN","values":["tests"]},{"contextName":"environment","operator":"IN","values":["production"]}]}],"variants":[{"name":"yes","weight":1000}]}]}
  let state = @sdk.Snapshot::parse(source)
  let empty = @sdk.Context::new()
  assert_false(state.is_enabled("default-env", empty))
  let transport = @online.Transport::{
    request: async fn(verb, url, _, _) {
      @async.pause()
      if verb == "POST" {
        assert_eq(url, "http://127.0.0.1:4242/api/client/register")
        { status: 202, body: "", etag: None, }
      } else {
        // Evaluation environment does not select a server/token environment.
        assert_eq(url, "http://127.0.0.1:4242/api/client/features")
        { status: 200, body: source, etag: None, }
      }
    },
  }
  for environment in ["default", "production"] {
    let config = @online.Options::new(
      "http://127.0.0.1:4242/api",
      "tests",
      "not-a-real-token",
      environment~,
      allow_http_loopback=true,
    )
    let client = @online.Client::new(config, transport~)
    defer client.close()
    assert_true(client.refresh())
    let name = if environment == "default" {
      "default-env"
    } else {
      "production-env"
    }
    assert_true(client.evaluate(name, empty).decision.enabled)
    assert_true(client.is_enabled(name, empty))
    let batch = client.evaluate_many(["default-env", "production-env"], empty)
    assert_eq(batch.generation, 1L)
    assert_eq(batch.decisions[0].enabled, environment == "default")
    assert_eq(batch.decisions[1].enabled, environment == "production")
    assert_true(client.get_variant(name, empty).enabled)
    assert_eq(client.get_variant(name, empty).name, "yes")
    let override_json = "{\"appName\":\"other\"}"
    let override_ctx = @sdk.Context::parse(override_json)
    assert_false(client.evaluate(name, override_ctx).decision.enabled)
    assert_false(client.is_enabled(name, override_ctx))
    assert_false(client.get_variant(name, override_ctx).enabled)
    assert_true(
      client.evaluate_many(["default-env", "production-env"], override_ctx).decisions.all(fn(
          d,
        ) {
          !d.enabled
        },
      ),
    )
    let env_json = "{\"environment\":\"default\"}"
    let env_ctx = @sdk.Context::parse(env_json)
    assert_true(client.is_enabled("default-env", env_ctx))
    assert_false(client.is_enabled("production-env", env_ctx))
    assert_false(state.is_enabled("default-env", empty))
  }
  for bad in ["", "bad\nenvironment", "x".repeat(129)] {
    let rejected = try {
      ignore(
        @online.Options::new(
          "https://localhost/api",
          "tests",
          "not-a-real-token",
          environment=bad,
        ),
      )
      false
    } catch {
      @sdk.ConfigError::Invalid(_) => true
      _ => false
    }
    assert_true(rejected)
  }
}
