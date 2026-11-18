///|
let minimal : String =
  #|{"version":2,"features":[{"name":"off","enabled":false,"strategies":[{"name":"default"}]},{"name":"on","enabled":true,"strategies":[]}]}

///|
test "explicit disabled is never overridden by fallback" {
  let state = @sdk.Snapshot::parse(minimal)
  let ctx = @sdk.Context::new()
  assert_false(state.is_enabled("off", ctx, fallback=true))
  assert_true(state.is_enabled("unknown", ctx, fallback=true))
  assert_false(state.is_enabled("unknown", ctx))
  assert_true(state.is_enabled("on", ctx))
  assert_eq(state.evaluate("off", ctx).reason, "disabled")
  assert_eq(state.evaluate("unknown", ctx).reason, "not_found")
}

///|
test "unknown inverted operator rejects whole snapshot" {
  let source =
    #|{"version":2,"features":[{"name":"danger","enabled":true,"strategies":[{"name":"default","constraints":[{"contextName":"userId","operator":"FUTURE_OP","inverted":true}]}]}]}
  let rejected = try {
    ignore(@sdk.Snapshot::parse(source))
    false
  } catch {
    @sdk.ConfigError::Unsupported(_) => true
    _ => false
  }
  assert_true(rejected)
}

///|
test "duplicate fields and duplicate flags rejected" {
  for
    source in [
      "{\"version\":2,\"version\":1,\"features\":[]}", "{\"version\":2,\"features\":[{\"name\":\"x\",\"enabled\":true},{\"name\":\"x\",\"enabled\":false}]}",
      "{\"version\":2,\"features\":[{\"name\":\"x\",\"enabled\":\"false\"}]}",
    ] {
    let rejected = try {
      ignore(@sdk.Snapshot::parse(source))
      false
    } catch {
      _ => true
    }
    assert_true(rejected, msg=source)
  }
}

///|
test "unsupported dependencies and malformed global variants cannot be ignored" {
  for key in ["dependencies", "variants"] {
    let source = "{\"version\":2,\"features\":[{\"name\":\"x\",\"enabled\":true,\"strategies\":[{\"name\":\"default\",\"variants\":[{\"name\":\"v\",\"weight\":1}]}],\"\{key}\":[{\"name\":\"parent\"}]}]}"
    let rejected = try {
      ignore(@sdk.Snapshot::parse(source))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
test "disabled variant distinguishes enabled feature without variants" {
  let state = @sdk.Snapshot::parse(minimal)
  let ctx = @sdk.Context::new()
  assert_false(state.get_variant("on", ctx).enabled)
  assert_true(state.get_variant("on", ctx).feature_enabled)
  assert_false(state.get_variant("off", ctx).feature_enabled)
}

///|
test "controlled random source and invalid random input" {
  let source =
    #|{"version":2,"features":[{"name":"r","enabled":true,"strategies":[{"name":"gradualRolloutRandom","parameters":{"percentage":"50"}}]}]}
  let state = @sdk.Snapshot::parse(source)
  let ctx = @sdk.Context::new()
  assert_true(state.evaluate("r", ctx, random=fn() { 0.0 }).enabled)
  assert_false(state.evaluate("r", ctx, random=fn() { 0.99 }).enabled)
  assert_false(state.evaluate("r", ctx, random=fn() { -1.0 }).enabled)
  assert_false(state.evaluate("r", ctx, random=fn() { 1.0 }).enabled)
}
