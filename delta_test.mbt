///|
fn delta_frame(events : Array[String]) -> String {
  let source = StringBuilder()
  source.write_string("{\"events\":[")
  for i in 0..<events.length() {
    if i != 0 {
      source.write_string(",")
    }
    source.write_string(events[i])
  }
  source.write_string("]}")
  source.to_string()
}

///|
fn feature_event(id : Int32, name : String, enabled : Bool) -> String {
  "{\"eventId\":\{id},\"type\":\"feature-updated\",\"feature\":{\"name\":\"\{name}\",\"enabled\":\{enabled},\"strategies\":[]}}"
}

///|
fn delta_rejected(
  store : @sdk.SnapshotStore,
  source : String,
  now : Int64,
) -> Bool {
  try {
    ignore(store.apply_delta(source, now))
    false
  } catch {
    _ => true
  }
}

///|
test "delta snapshots are immutable and hydration replaces both state maps" {
  let first = @sdk.Snapshot::from_delta(
    (
      #|{"events":[{"eventId":1,"type":"hydration","features":[{"name":"old","enabled":true,"strategies":[]},{"name":"segmented","enabled":true,"strategies":[{"name":"default","segments":[1]}]}],"segments":[{"id":1,"constraints":[{"contextName":"userId","operator":"IN","values":["a"]}]}]}]}
    ),
  )
  let a = @sdk.Context::new(user_id="a")
  let b = @sdk.Context::new(user_id="b")
  let next = first.apply_delta(
    delta_frame([
      feature_event(2, "new", true),
      "{\"eventId\":3,\"type\":\"feature-removed\",\"featureName\":\"old\",\"project\":\"default\"}",
      "{\"eventId\":4,\"type\":\"segment-updated\",\"segment\":{\"id\":1,\"constraints\":[{\"contextName\":\"userId\",\"operator\":\"IN\",\"values\":[\"b\"]}]}}",
    ]),
  )
  assert_true(first.is_enabled("old", a))
  assert_false(first.is_enabled("new", a))
  assert_true(first.is_enabled("segmented", a))
  assert_false(first.is_enabled("segmented", b))
  assert_false(next.is_enabled("old", a))
  assert_true(next.is_enabled("new", a))
  assert_false(next.is_enabled("segmented", a))
  assert_true(next.is_enabled("segmented", b))
  assert_eq(next.delta_event_id(), Some(4L))
  let removed = next.apply_delta(
    "{\"events\":[{\"eventId\":5,\"type\":\"segment-removed\",\"segmentId\":1}]}",
  )
  assert_false(removed.is_enabled("segmented", b))
  assert_false(removed.get_variant("segmented", b).feature_enabled)
  assert_true(next.is_enabled("segmented", b))
  let replaced = removed.apply_delta(
    (
      #|{"events":[{"eventId":8,"type":"hydration","features":[{"name":"fresh","enabled":true,"strategies":[]}],"segments":[]}]}
    ),
  )
  assert_true(replaced.is_enabled("fresh", a))
  assert_false(replaced.is_enabled("new", a))
  assert_false(replaced.is_enabled("segmented", a))
  assert_eq(replaced.size(), 1)
}

///|
test "multi-event delta installs exactly one generation for a consistent batch" {
  let store = @sdk.SnapshotStore::new()
  assert_eq(
    store.apply_delta(delta_frame([feature_event(1, "on", true)]), 0L),
    1L,
  )
  assert_eq(
    store.apply_delta(
      delta_frame([feature_event(2, "on", false), feature_event(3, "off", true)]),
      1L,
    ),
    2L,
  )
  let batch = store.evaluate_many(["on", "off"], @sdk.Context::new(), 1L)
  assert_eq(batch.generation, 2L)
  assert_eq(batch.decisions.map(fn(d) { d.enabled }), [false, true])
  assert_eq(store.delta_event_id(), Some(3L))
  assert_eq(store.status(1L).source, "delta")
}

///|
test "malformed delta frames preserve last good generation cursor and freshness" {
  let store = @sdk.SnapshotStore::new(stale_after_ms=100L)
  ignore(store.apply_delta(delta_frame([feature_event(1, "on", true)]), 0L))
  let first = feature_event(2, "on", false)
  let malformed = [
    "{\"eventId\":3,\"type\":\"feature-updated\",\"feature\":{\"name\":\"bad\",\"enabled\":\"true\"}}",
    "{\"eventId\":3,\"type\":\"future-event\"}", "{\"eventId\":3,\"type\":\"segment-updated\",\"segment\":{\"id\":true}}",
    "{\"eventId\":3,\"type\":\"hydration\",\"features\":{}}", "{\"eventId\":3,\"type\":\"segment-removed\",\"segmentId\":-1}",
    "{\"eventId\":2,\"type\":\"feature-removed\",\"featureName\":\"on\"}", "{\"eventId\":1,\"type\":\"feature-removed\",\"featureName\":\"on\"}",
    "{\"eventId\":3,\"eventId\":4,\"type\":\"feature-removed\",\"featureName\":\"on\"}",
  ]
  for bad in malformed {
    assert_true(delta_rejected(store, delta_frame([first, bad]), 90L), msg=bad)
    assert_true(store.evaluate("on", @sdk.Context::new(), 99L).decision.enabled)
    assert_eq(store.status(99L).generation, 1L)
    assert_eq(store.delta_event_id(), Some(1L))
    assert_true(store.status(100L).stale)
  }
  for id in ["-1", "1.5", "9007199254740992", "null", "true"] {
    assert_true(
      delta_rejected(
        store,
        "{\"events\":[{\"eventId\":\{id},\"type\":\"feature-removed\",\"featureName\":\"on\"}]}",
        90L,
      ),
      msg=id,
    )
  }
  assert_true(delta_rejected(store, "{}", 90L))
  assert_true(delta_rejected(store, "{\"events\":null}", 90L))
  // A stale id is not permission to ignore a malformed feature payload.
  assert_true(
    delta_rejected(
      store, "{\"events\":[{\"eventId\":0,\"type\":\"feature-updated\",\"feature\":{\"name\":\"on\",\"enabled\":1}}]}",
      90L,
    ),
  )
  assert_eq(store.delta_event_id(), Some(1L))
  assert_true(store.status(100L).stale)
}

///|
test "delta replay overlap is idempotent and explicit hydration resets the cursor" {
  let store = @sdk.SnapshotStore::new(stale_after_ms=10L)
  let initial = delta_frame([feature_event(1, "on", true)])
  ignore(store.apply_delta(initial, 0L))
  store.record_failure("temporary")
  assert_eq(store.apply_delta(initial, 100L), 1L)
  assert_false(store.status(109L).stale)
  assert_eq(store.status(109L).consecutive_failures, 0)
  let overlap = delta_frame([
    "{\"eventId\":0,\"type\":\"hydration\",\"features\":[],\"segments\":[]}",
    feature_event(1, "on", false),
    feature_event(2, "off", true),
  ])
  assert_eq(store.apply_delta(overlap, 110L), 2L)
  assert_true(store.evaluate("on", @sdk.Context::new(), 110L).decision.enabled)
  assert_true(store.evaluate("off", @sdk.Context::new(), 110L).decision.enabled)
  assert_eq(store.delta_event_id(), Some(2L))
  let hydration =
    #|{"events":[{"eventId":0,"type":"hydration","features":[{"name":"fresh","enabled":true,"strategies":[]}],"segments":[]}]}
  assert_eq(store.hydrate_delta(hydration, 120L), 3L)
  assert_eq(store.delta_event_id(), Some(0L))
  assert_false(store.evaluate("on", @sdk.Context::new(), 120L).decision.enabled)
  assert_true(
    store.evaluate("fresh", @sdk.Context::new(), 120L).decision.enabled,
  )
  assert_eq(store.install(minimal, 121L), 4L)
  assert_eq(store.delta_event_id(), None)
}

///|
test "empty delta and invalidated clock follow lifecycle without false freshness" {
  let store = @sdk.SnapshotStore::new()
  assert_eq(store.apply_delta("{\"events\":[]}", 0L), 1L)
  assert_true(store.status(0L).ready)
  assert_eq(store.status(0L).feature_count, 0)
  assert_eq(store.apply_delta("{\"events\":[]}", 1L), 1L)
  let initial = delta_frame([feature_event(1, "on", true)])
  assert_eq(store.apply_delta(initial, 2L), 2L)
  store.invalidate_clock()
  assert_true(delta_rejected(store, initial, 3L))
  assert_false(store.status(3L).ready)
  assert_eq(store.delta_event_id(), Some(1L))
  assert_eq(
    store.apply_delta(delta_frame([feature_event(2, "on", true)]), 4L),
    3L,
  )
  assert_true(store.status(4L).ready)
  assert_true(delta_rejected(store, initial, -1L))
  let invalid_hydration = try {
    ignore(store.hydrate_delta(initial, 5L))
    false
  } catch {
    _ => true
  }
  assert_true(invalid_hydration)
  store.close()
  assert_true(delta_rejected(store, initial, 5L))
  let closed_hydration = try {
    ignore(
      store.hydrate_delta(
        "{\"events\":[{\"eventId\":0,\"type\":\"hydration\",\"features\":[],\"segments\":[]}]}",
        5L,
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(closed_hydration)
}
