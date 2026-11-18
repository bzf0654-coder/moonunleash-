///|
let strategy_ab : String =
  #|{"name":"flexibleRollout","parameters":{"rollout":"100","stickiness":"userId","groupId":"recommendation-ab-v1"},"constraints":[{"contextName":"plan","operator":"IN","values":["enterprise"]}],"variants":[{"name":"control","weight":500,"weightType":"fix","stickiness":"userId","payload":{"type":"string","value":"baseline"}},{"name":"treatment","weight":500,"weightType":"variable","stickiness":"userId","payload":{"type":"string","value":"model-v2"}}]}

///|
fn strategy_snapshot(
  strategies : String,
  legacy~ : String = "[]",
  enabled~ : Bool = true,
) -> @sdk.Snapshot raise {
  @sdk.Snapshot::parse(
    "{\"version\":2,\"features\":[{\"name\":\"recommendation-ab\",\"enabled\":\{enabled},\"strategies\":\{strategies},\"variants\":\{legacy}}]}",
  )
}

///|
fn strategy_context(
  user : String,
  plan~ : String = "enterprise",
) -> @sdk.Context raise {
  @sdk.Context::parse(
    "{\"userId\":\"\{user}\",\"properties\":{\"plan\":\"\{plan}\"}}",
  )
}

///|
test "proposal strategy variants return exact reference A/B results" {
  let state = strategy_snapshot("[\{strategy_ab}]")
  for
    (user, expected, payload) in [
      ("user-1", "control", "baseline"),
      ("user-2", "treatment", "model-v2"),
    ] {
    let ctx = strategy_context(user)
    let v = state.get_variant("recommendation-ab", ctx)
    assert_eq(v.name, expected)
    assert_true(v.enabled && v.feature_enabled)
    guard v.payload is Some(p) else { fail("missing variant payload") }
    assert_eq(p.kind, "string")
    assert_eq(p.value, payload)
    assert_eq(
      state.get_variant("recommendation-ab", ctx).to_json(),
      v.to_json(),
    )
  }
  for
    ctx in [
      strategy_context("user-1", plan="free"),
      @sdk.Context::parse("{\"properties\":{\"plan\":\"enterprise\"}}"),
    ] {
    let v = state.get_variant("recommendation-ab", ctx)
    assert_false(v.enabled || v.feature_enabled)
  }
  let off = strategy_snapshot("[\{strategy_ab}]", enabled=false)
  assert_false(
    off.get_variant("recommendation-ab", strategy_context("user-1")).feature_enabled,
  )
  assert_false(state.get_variant("unknown", strategy_context("user-1")).enabled)
  let zero_strategy =
    #|{"name":"flexibleRollout","parameters":{"rollout":"0","stickiness":"userId","groupId":"recommendation-ab-v1"},"variants":[{"name":"control","weight":500},{"name":"treatment","weight":500}]}
  let zero = strategy_snapshot(
    "[\{zero_strategy}]",
    legacy="[{\"name\":\"legacy\",\"weight\":1000}]",
  )
  let v = zero.get_variant("recommendation-ab", strategy_context("user-1"))
  assert_eq(v.name, "disabled")
  assert_false(v.enabled || v.feature_enabled)
}

///|
test "first enabled strategy stops even if it has no variants" {
  let ctx = strategy_context("user-1")
  let state = strategy_snapshot("[{\"name\":\"default\"},\{strategy_ab}]")
  let v = state.get_variant("recommendation-ab", ctx)
  assert_eq(v.name, "disabled")
  assert_false(v.enabled)
  assert_true(v.feature_enabled)
  let legacy = "[{\"name\":\"legacy\",\"weight\":1000}]"
  let state = strategy_snapshot(
    "[{\"name\":\"default\"},\{strategy_ab}]",
    legacy~,
  )
  assert_eq(state.get_variant("recommendation-ab", ctx).name, "legacy")
  let failed_first = "{\"name\":\"default\",\"constraints\":[{\"contextName\":\"plan\",\"operator\":\"IN\",\"values\":[\"free\"]}]}"
  let state = strategy_snapshot("[\{failed_first},\{strategy_ab}]", legacy~)
  assert_eq(state.get_variant("recommendation-ab", ctx).name, "control")
}

///|
test "strategy variant selection failure falls back to legacy variants" {
  let legacy = "[{\"name\":\"legacy\",\"weight\":1000}]"
  for variants in ["[]", "[{\"name\":\"zero\",\"weight\":0}]"] {
    let state = strategy_snapshot(
      "[{\"name\":\"default\",\"variants\":\{variants}}]",
      legacy~,
    )
    assert_eq(
      state.get_variant("recommendation-ab", @sdk.Context::new()).name,
      "legacy",
    )
  }
  let state = strategy_snapshot("[\{strategy_ab}]", legacy~)
  assert_eq(
    state.get_variant("recommendation-ab", strategy_context("user-2")).name,
    "treatment",
  )
}

///|
test "strategy and variant random evaluation share one matched strategy" {
  let source =
    #|[{"name":"gradualRolloutRandom","parameters":{"percentage":"50","groupId":"r"},"variants":[{"name":"one","weight":1},{"name":"two","weight":1}]}]
  let state = strategy_snapshot(source)
  let mut calls = 0
  let v = state.get_variant("recommendation-ab", @sdk.Context::new(), random=fn() {
    calls = calls + 1
    if calls == 1 {
      0.0
    } else {
      0.99
    }
  })
  assert_true(v.enabled && v.feature_enabled)
  assert_eq(calls, 2)
}

///|
test "strategy variant groupId not feature name determines cohort" {
  let source = "{\"version\":2,\"features\":[{\"name\":\"first\",\"enabled\":true,\"strategies\":[\{strategy_ab}]},{\"name\":\"second\",\"enabled\":true,\"strategies\":[\{strategy_ab}]}]}"
  let state = @sdk.Snapshot::parse(source)
  for user in ["user-1", "user-2", "user-3", "user-4"] {
    let ctx = strategy_context(user)
    assert_eq(
      state.get_variant("first", ctx).to_json(),
      state.get_variant("second", ctx).to_json(),
    )
  }
}

///|
test "malformed strategy variants reject rather than silently fall through" {
  for
    variants in [
      "{}", "[{\"name\":\"v\",\"weight\":-1}]", "[{\"name\":\"v\",\"weight\":1},{\"name\":\"v\",\"weight\":1}]",
      "[{\"name\":\"v\",\"weight\":1,\"weightType\":\"future\"}]", "[{\"name\":\"v\",\"weight\":1,\"payload\":{\"type\":\"json\",\"value\":42}}]",
    ] {
    let rejected = try {
      ignore(
        strategy_snapshot("[{\"name\":\"default\",\"variants\":\{variants}}]"),
      )
      false
    } catch {
      @sdk.ConfigError::Invalid(_) => true
      _ => false
    }
    assert_true(rejected, msg=variants)
  }
}
