///|
test "clock rollback invalidates freshness until full accepted snapshot" {
  let store = @sdk.SnapshotStore::new()
  ignore(store.install(minimal, 1000L))
  store.invalidate_clock()
  assert_false(store.status(900L).ready)
  assert_true(store.status(900L).stale)
  assert_eq(
    store.evaluate("on", @sdk.Context::new(), 900L).decision.reason,
    "clock_untrusted",
  )
  let rejected = try {
    store.revalidate(900L)
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_eq(store.status(900L).generation, 1L)
  ignore(store.install(minimal, 900L))
  assert_true(store.status(901L).ready)
  assert_eq(store.status(901L).generation, 2L)
}
