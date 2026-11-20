///|
async fn main {
  @async.with_timeout(30000, run)
}

///|
// Bound the whole example, including registration and scoped shutdown.
async fn run() -> Unit {
  let url = match @env.get_env_var("UNLEASH_URL") {
    Some(value) => value
    None =>
      raise @sdk.ConfigError::Invalid(
        "set UNLEASH_URL to your server API base URL",
      )
  }
  let token = match @env.get_env_var("UNLEASH_API_TOKEN") {
    Some(value) => value
    None =>
      raise @sdk.ConfigError::Invalid(
        "set UNLEASH_API_TOKEN in the environment, not in source",
      )
  }
  let name = @env.get_env_var("UNLEASH_FLAG").unwrap_or("checkout")
  let user = @env.get_env_var("UNLEASH_USER_ID").unwrap_or("demo-user")
  let app_name = @env.get_env_var("UNLEASH_APP_NAME").unwrap_or(
    "moonunleash-live-demo",
  )
  let environment = @env.get_env_var("UNLEASH_CONTEXT_ENVIRONMENT").unwrap_or(
    "default",
  )
  let options = @online.Options::new(
    url,
    app_name,
    token,
    environment~,
    allow_http_loopback=@env.get_env_var("UNLEASH_ALLOW_HTTP_LOOPBACK") ==
      Some("1"),
  )
  @online.with_client(options, async fn(client) {
    client.wait_ready(timeout_ms=15000)
    let ctx = @sdk.Context::new(user_id=user)
    let result = client.evaluate(name, ctx)
    println(
      @json.Json::object(
        Map([
          ("flag", @json.Json::string(name)),
          ("enabled", @json.Json::boolean(result.decision.enabled)),
          ("reason", @json.Json::string(result.decision.reason)),
          ("generation", @json.Json::number(result.generation.to_double())),
          ("stale", @json.Json::boolean(result.stale)),
          ("registered", @json.Json::boolean(client.is_registered())),
          ("variant", client.get_variant(name, ctx).to_json()),
        ]),
      ).stringify(indent=2),
    )
  })
}
