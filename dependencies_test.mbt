///|
fn dependency_snapshot(features : String) -> @sdk.Snapshot raise {
  @sdk.Snapshot::parse("{\"version\":2,\"features\":[\{features}]}")
}

///|
test "dependencies use AND and never invert missing parents or caller fallback" {
  let state = dependency_snapshot(
    (
      #|{"name":"on","enabled":true,"strategies":[]},{"name":"off","enabled":false,"strategies":[]},{"name":"both","enabled":true,"dependencies":[{"feature":"on"},{"feature":"off","enabled":false}],"strategies":[]},{"name":"fail","enabled":true,"dependencies":[{"feature":"on"},{"feature":"off"}],"strategies":[]},{"name":"missing","enabled":true,"dependencies":[{"feature":"absent","enabled":false}],"strategies":[]}
    ),
  )
  let ctx = @sdk.Context::new()
  assert_true(state.is_enabled("both", ctx))
  assert_false(state.is_enabled("fail", ctx, fallback=true))
  assert_false(state.is_enabled("missing", ctx, fallback=true))
  assert_eq(state.evaluate("missing", ctx).reason, "dependency_not_satisfied")
  assert_false(state.get_variant("missing", ctx).feature_enabled)
}

///|
test "nested dependencies and cycles are bounded unsatisfied configurations" {
  let state = dependency_snapshot(
    (
      #|{"name":"leaf","enabled":true,"strategies":[]},{"name":"parent","enabled":true,"dependencies":[{"feature":"leaf"}],"strategies":[]},{"name":"nested","enabled":true,"dependencies":[{"feature":"parent","enabled":false}],"strategies":[]},{"name":"self","enabled":true,"dependencies":[{"feature":"self"}],"strategies":[]},{"name":"a","enabled":true,"dependencies":[{"feature":"b"}],"strategies":[]},{"name":"b","enabled":true,"dependencies":[{"feature":"a"}],"strategies":[]}
    ),
  )
  let ctx = @sdk.Context::new()
  assert_true(state.is_enabled("parent", ctx))
  for name in ["nested", "self", "a", "b"] {
    assert_false(state.is_enabled(name, ctx, fallback=true), msg=name)
    assert_false(state.get_variant(name, ctx).feature_enabled, msg=name)
  }
}

///|
test "dependency variant names check feature enabled and ignore whitelist on negative parent" {
  let state = dependency_snapshot(
    (
      #|{"name":"empty","enabled":true,"strategies":[]},{"name":"off","enabled":false,"strategies":[]},{"name":"named-disabled","enabled":true,"dependencies":[{"feature":"empty","variants":["disabled"]}],"strategies":[]},{"name":"off-disabled","enabled":true,"dependencies":[{"feature":"off","variants":["disabled"]}],"strategies":[]},{"name":"negative","enabled":true,"dependencies":[{"feature":"off","enabled":false,"variants":["not-selected"]}],"strategies":[]}
    ),
  )
  let ctx = @sdk.Context::new()
  assert_true(state.is_enabled("named-disabled", ctx))
  assert_false(state.is_enabled("off-disabled", ctx))
  assert_true(state.is_enabled("negative", ctx))
}

///|
test "parent variant dependency propagates one injected random source" {
  let state = dependency_snapshot(
    (
      #|{"name":"parent","enabled":true,"strategies":[{"name":"gradualRolloutRandom","parameters":{"percentage":"50"},"variants":[{"name":"p","weight":1000}]}]},{"name":"child","enabled":true,"dependencies":[{"feature":"parent","variants":["p"]}],"strategies":[],"variants":[{"name":"c","weight":1000}]}
    ),
  )
  let mut draws = 0
  let v = state.get_variant("child", @sdk.Context::new(), random=fn() {
    draws = draws + 1
    if draws == 1 {
      0.1
    } else {
      0.9
    }
  })
  assert_eq(v.name, "c")
  assert_true(v.enabled && v.feature_enabled)
  assert_eq(draws, 3)
}

///|
test "invalid dependency update retains last good snapshot atomically" {
  let store = @sdk.SnapshotStore::new()
  ignore(store.install(minimal, 0L))
  for
    dependency in [
      "null", "[]", "{}", "{\"feature\":\"\"}", "{\"feature\":\"on\",\"enabled\":\"false\"}",
      "{\"feature\":\"on\",\"variants\":[1]}", "{\"feature\":\"on\",\"variants\":{}}",
    ] {
    let rejected = try {
      ignore(
        store.install(
          "{\"version\":2,\"features\":[{\"name\":\"x\",\"enabled\":true,\"dependencies\":[\{dependency}]}]}",
          1L,
        ),
      )
      false
    } catch {
      _ => true
    }
    assert_true(rejected, msg=dependency)
    assert_eq(store.status(1L).generation, 1L)
    assert_true(store.evaluate("on", @sdk.Context::new(), 1L).decision.enabled)
  }
}
