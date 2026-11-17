///|
test "context defaults preserve explicit values and original private context" {
  let source =
    #|{"version":2,"features":[{"name":"gate","enabled":true,"strategies":[{"name":"default","constraints":[{"contextName":"appName","operator":"IN","values":["tests"]},{"contextName":"environment","operator":"IN","values":["default"]}]}]},{"name":"tier","enabled":true,"strategies":[{"name":"default","constraints":[{"contextName":"tier","operator":"IN","values":["enterprise"]}]}]},{"name":"user","enabled":true,"strategies":[{"name":"userWithId","parameters":{"userIds":"u-7"}}]}]}
  let state = @sdk.Snapshot::parse(source)
  let original = @sdk.Context::new(user_id="u-7")
  let enhanced = original.with_defaults("tests")
  assert_false(state.is_enabled("gate", original))
  assert_true(state.is_enabled("gate", enhanced))
  assert_true(state.is_enabled("user", enhanced))
  assert_false(state.is_enabled("gate", original))
  // Applying other defaults must not replace keys that are now explicit.
  assert_true(
    state.is_enabled(
      "gate",
      enhanced.with_defaults("other", environment="production"),
    ),
  )
  for
    input in [
      "{\"appName\":\"\"}", "{\"appName\":null}", "{\"environment\":\"\"}", "{\"environment\":null}",
    ] {
    assert_false(
      state.is_enabled(
        "gate",
        @sdk.Context::parse(input).with_defaults("tests"),
      ),
    )
  }
  let custom =
    #|{"properties":{"tier":"enterprise","appName":"spoof","environment":"spoof"}}
  let ctx = @sdk.Context::parse(custom)
  let with_defaults = ctx.with_defaults("tests")
  assert_true(state.is_enabled("tier", with_defaults))
  assert_true(state.is_enabled("gate", with_defaults))
  assert_false(state.is_enabled("gate", ctx))
}
