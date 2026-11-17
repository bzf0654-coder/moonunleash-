///|
test "failed update preserves prior snapshot and generation" {
  let store = @sdk.SnapshotStore::new(stale_after_ms=100L)
  let ctx = @sdk.Context::new()
  assert_eq(store.evaluate("on", ctx, 0L).decision.reason, "not_ready")
  assert_eq(store.install(minimal, 0L), 1L)
  assert_true(store.evaluate("on", ctx, 99L).decision.enabled)
  assert_false(store.status(99L).stale)
  assert_true(store.status(100L).stale)
  let rejected = try {
    ignore(store.install("invalid", 101L))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  store.record_failure("invalid_response")
  assert_true(store.evaluate("on", ctx, 200L).decision.enabled)
  assert_eq(store.status(200L).generation, 1L)
  assert_eq(store.status(200L).consecutive_failures, 1)
  store.revalidate(200L)
  assert_false(store.status(200L).stale)
  assert_eq(store.status(200L).generation, 1L)
  assert_eq(store.status(200L).consecutive_failures, 0)
}

///|
test "explicit max stale policy and idempotent close" {
  let store = @sdk.SnapshotStore::new(stale_after_ms=10L, max_stale_ms=20L)
  let ctx = @sdk.Context::new()
  ignore(store.install(minimal, 100L))
  assert_true(store.evaluate("on", ctx, 119L).decision.enabled)
  assert_eq(store.evaluate("on", ctx, 120L).decision.reason, "expired")
  let batch = store.evaluate_many(["on", "off", "unknown"], ctx, 119L)
  assert_eq(batch.generation, 1L)
  assert_eq(batch.decisions.map(fn(d) { d.enabled }), [true, false, false])
  store.close()
  store.close()
  assert_true(store.status(121L).closed)
  assert_eq(store.evaluate("on", ctx, 121L).decision.reason, "closed")
  let rejected = try {
    ignore(store.install(minimal, 121L))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
test "cannot revalidate before initial snapshot" {
  let store = @sdk.SnapshotStore::new()
  let rejected = try {
    store.revalidate(1L)
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
