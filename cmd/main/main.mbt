///|
/// Offline, deterministic example: no service, token, Docker or network required.
fn main raise {
  let source =
    #|{"version":2,"features":[{"name":"checkout","enabled":true,"strategies":[{"name":"flexibleRollout","parameters":{"rollout":"50","stickiness":"userId","groupId":"checkout"}}],"variants":[{"name":"control","weight":50},{"name":"treatment","weight":50}]}]}
  let state = @sdk.Snapshot::parse(source)
  let results : Array[@json.Json] = []
  for i = 1; i <= 10; i = i + 1 {
    let user = "user-\{i}"
    let ctx = @sdk.Context::new(user_id=user)
    let result = state.evaluate("checkout", ctx)
    results.push(
      @json.Json::object(
        Map([
          ("user", @json.Json::string(user)),
          ("enabled", @json.Json::boolean(result.enabled)),
          ("reason", @json.Json::string(result.reason)),
          ("variant", state.get_variant("checkout", ctx).to_json()),
        ]),
      ),
    )
  }
  println(
    @json.Json::object(
      Map([
        ("example", @json.Json::string("offline-stable-rollout")),
        ("results", @json.Json::array(results)),
      ]),
    ).stringify(indent=2),
  )
}
