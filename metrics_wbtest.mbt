///|
fn metrics_test_bucket(source : String?) -> @json.Json raise {
  guard source is Some(source) else {
    fail("expected a nonempty metrics bucket")
  }
  @json.parse(source)
}

///|
fn metrics_test_toggle(bucket : @json.Json, name : String) -> @json.Json {
  field(field(bucket, "toggles"), name)
}

///|
test "metrics Gregorian UTC timestamps cover epoch leap days current year and year 9999" {
  for
    (milliseconds, expected) in [
      (0L, "1970-01-01T00:00:00.000Z"),
      (1L, "1970-01-01T00:00:00.001Z"),
      (999L, "1970-01-01T00:00:00.999Z"),
      (1000L, "1970-01-01T00:00:01.000Z"),
      (86400000L, "1970-01-02T00:00:00.000Z"),
      (946684800000L, "2000-01-01T00:00:00.000Z"),
      (951782400000L, "2000-02-29T00:00:00.000Z"),
      (951827696789L, "2000-02-29T12:34:56.789Z"),
      (1709164800000L, "2024-02-29T00:00:00.000Z"),
      (1709251199999L, "2024-02-29T23:59:59.999Z"),
      (1709251200000L, "2024-03-01T00:00:00.000Z"),
      (1767225600000L, "2026-01-01T00:00:00.000Z"),
      (4107542400000L, "2100-03-01T00:00:00.000Z"),
      (253402300799999L, "9999-12-31T23:59:59.999Z"),
    ] {
    assert_eq(metrics_timestamp(milliseconds), expected)
  }
}

///|
test "metrics reject epoch milliseconds outside the supported UTC range" {
  for
    invalid in [
      -9223372036854775808L, -1L, 253402300800000L, 9223372036854775807L,
    ] {
    let constructor_rejected = try {
      ignore(Metrics::new(invalid))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    let formatter_rejected = try {
      ignore(metrics_timestamp(invalid))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(constructor_rejected)
    assert_true(formatter_rejected)
  }
  let metrics = Metrics::new(253402300799999L)
  metrics.count("last", true)
  let bucket = metrics_test_bucket(metrics.prepare(253402300799999L))
  assert_eq(
    field(bucket, "start"),
    @json.Json::string("9999-12-31T23:59:59.999Z"),
  )
  assert_eq(field(bucket, "stop"), field(bucket, "start"))
}

///|
test "metrics registration started timestamp remains the immutable construction date" {
  let metrics = Metrics::new(1767225600123L)
  let started = "2026-01-01T00:00:00.123Z"
  assert_eq(metrics.started_at(), started)
  assert_eq(metrics.prepare(1767225600200L), None)
  assert_eq(metrics.started_at(), started)
  metrics.count("flag", true)
  let frozen = metrics.prepare(1767225601000L)
  assert_eq(metrics.started_at(), started)
  metrics.count("flag", false)
  assert_eq(metrics.prepare(1767225602000L), frozen)
  assert_eq(metrics.started_at(), started)
  metrics.acknowledge()
  let next = metrics_test_bucket(metrics.prepare(1767225603000L))
  assert_eq(
    field(next, "start"),
    @json.Json::string("2026-01-01T00:00:01.000Z"),
  )
  assert_eq(metrics.started_at(), started)
  metrics.acknowledge()
  assert_eq(metrics.started_at(), started)
}

///|
test "metrics count one boolean and optional variant per call in classic bucket JSON" {
  let metrics = Metrics::new(0L)
  metrics.count("on", true)
  metrics.count("on", true, variant="blue")
  metrics.count("on", false, variant="disabled")
  metrics.count("on", false, variant="blue")
  metrics.count("off", false)
  let bucket = metrics_test_bucket(metrics.prepare(1000L))
  assert_eq(
    bucket,
    @json.parse(
      (
        #|{"start":"1970-01-01T00:00:00.000Z","stop":"1970-01-01T00:00:01.000Z","toggles":{"on":{"yes":2,"no":2,"variants":{"blue":2,"disabled":1}},"off":{"yes":0,"no":1,"variants":{}}}}
      ),
    ),
  )
  assert_true(metrics.active.is_empty())
  assert_eq(metrics.variant_pairs, 0)
}

///|
test "metrics empty prepares and acknowledgements do not invent or double count buckets" {
  let metrics = Metrics::new(0L)
  metrics.acknowledge()
  assert_eq(metrics.prepare(10L), None)
  assert_eq(metrics.prepare(10L), None)
  assert_eq(metrics.start_ms, 0L)
  metrics.count("flag", true)
  let first = metrics_test_bucket(metrics.prepare(1000L))
  assert_eq(
    field(first, "start"),
    @json.Json::string("1970-01-01T00:00:00.000Z"),
  )
  metrics.acknowledge()
  metrics.acknowledge()
  assert_eq(metrics.prepare(2000L), None)
  assert_eq(metrics.start_ms, 1000L)
  metrics.count("flag", false)
  let second = metrics_test_bucket(metrics.prepare(3000L))
  assert_eq(
    second,
    @json.parse(
      (
        #|{"start":"1970-01-01T00:00:01.000Z","stop":"1970-01-01T00:00:03.000Z","toggles":{"flag":{"yes":0,"no":1,"variants":{}}}}
      ),
    ),
  )
  metrics.acknowledge()
  assert_eq(metrics.prepare(3000L), None)
}

///|
test "metrics failed-send retries keep frozen bytes and concurrent active counts" {
  let metrics = Metrics::new(0L)
  metrics.count("flag", true, variant="red")
  let frozen = metrics.prepare(1000L)
  assert_eq(
    metrics_test_bucket(frozen),
    @json.parse(
      (
        #|{"start":"1970-01-01T00:00:00.000Z","stop":"1970-01-01T00:00:01.000Z","toggles":{"flag":{"yes":1,"no":0,"variants":{"red":1}}}}
      ),
    ),
  )
  metrics.count("flag", false, variant="blue")
  assert_eq(metrics.prepare(2000L), frozen)
  metrics.count("flag", false, variant="blue")
  metrics.count("other", true)
  assert_eq(metrics.prepare(3000L), frozen)
  assert_eq(metrics.pending, frozen)
  assert_eq(metrics.active.length(), 2)
  metrics.acknowledge()
  assert_eq(metrics.pending, None)
  assert_eq(metrics.active.length(), 2)
  let next = metrics_test_bucket(metrics.prepare(4000L))
  assert_eq(
    next,
    @json.parse(
      (
        #|{"start":"1970-01-01T00:00:01.000Z","stop":"1970-01-01T00:00:04.000Z","toggles":{"flag":{"yes":0,"no":2,"variants":{"blue":2}},"other":{"yes":1,"no":0,"variants":{}}}}
      ),
    ),
  )
  metrics.acknowledge()
  assert_eq(metrics.prepare(5000L), None)
}

///|
test "metrics backward negative and oversized prepare times preserve active state atomically" {
  let metrics = Metrics::new(100L)
  metrics.count("flag", true, variant="blue")
  for invalid in [-1L, 99L, 253402300800000L, 9223372036854775807L] {
    let rejected = try {
      ignore(metrics.prepare(invalid))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(rejected)
    assert_eq(metrics.pending, None)
    assert_eq(metrics.start_ms, 100L)
    assert_eq(metrics.last_prepare_ms, 100L)
    assert_eq(metrics.variant_pairs, 1)
    assert_eq(metrics.active.length(), 1)
  }
  assert_eq(
    metrics_test_bucket(metrics.prepare(200L)),
    @json.parse(
      (
        #|{"start":"1970-01-01T00:00:00.100Z","stop":"1970-01-01T00:00:00.200Z","toggles":{"flag":{"yes":1,"no":0,"variants":{"blue":1}}}}
      ),
    ),
  )
}

///|
test "metrics validate pending retry times before returning frozen data without data loss" {
  let metrics = Metrics::new(100L)
  metrics.count("flag", true, variant="red")
  let frozen = metrics.prepare(200L)
  metrics.count("flag", false, variant="blue")
  assert_eq(metrics.prepare(400L), frozen)
  for invalid in [-1L, 199L, 399L, 253402300800000L] {
    let rejected = try {
      ignore(metrics.prepare(invalid))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(rejected)
    assert_eq(metrics.pending, frozen)
    assert_eq(metrics.start_ms, 200L)
    assert_eq(metrics.last_prepare_ms, 400L)
    assert_eq(metrics.active.length(), 1)
    assert_eq(metrics.variant_pairs, 1)
  }
  metrics.acknowledge()
  let bucket = metrics_test_bucket(metrics.prepare(400L))
  assert_eq(
    field(bucket, "start"),
    @json.Json::string("1970-01-01T00:00:00.200Z"),
  )
  assert_eq(
    metrics_test_toggle(bucket, "flag"),
    @json.parse("{\"yes\":0,\"no\":1,\"variants\":{\"blue\":1}}"),
  )
}

///|
test "metrics rollback protection also applies to empty prepares" {
  let metrics = Metrics::new(0L)
  assert_eq(metrics.prepare(100L), None)
  let rejected = try {
    ignore(metrics.prepare(99L))
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(rejected)
  assert_eq(metrics.last_prepare_ms, 100L)
  assert_eq(metrics.start_ms, 0L)
  assert_true(metrics.active.is_empty())
  metrics.count("flag", true)
  let bucket = metrics_test_bucket(metrics.prepare(100L))
  assert_eq(
    field(bucket, "start"),
    @json.Json::string("1970-01-01T00:00:00.000Z"),
  )
  assert_eq(
    field(bucket, "stop"),
    @json.Json::string("1970-01-01T00:00:00.100Z"),
  )
}

///|
test "metrics toggle cap omits new names but keeps existing boolean and variant counters" {
  let metrics = Metrics::new(0L)
  for i in 0..<1000 {
    metrics.count("flag-\{i}", true)
  }
  metrics.count("overflow", true, variant="blue")
  metrics.count("flag-0", false, variant="blue")
  assert_eq(metrics.active.length(), 1000)
  assert_false(metrics.active.contains("overflow"))
  assert_eq(metrics.variant_pairs, 1)
  let bucket = metrics_test_bucket(metrics.prepare(1L))
  assert_eq(
    metrics_test_toggle(bucket, "flag-0"),
    @json.parse("{\"yes\":1,\"no\":1,\"variants\":{\"blue\":1}}"),
  )
  assert_eq(metrics_test_toggle(bucket, "overflow"), @json.null)
  // A pending serialized bucket does not consume the fresh active name budget.
  for i in 0..<1000 {
    metrics.count("next-\{i}", true, variant="blue")
  }
  metrics.count("next-overflow", true, variant="blue")
  assert_eq(metrics.active.length(), 1000)
  assert_eq(metrics.variant_pairs, 1000)
  assert_false(metrics.active.contains("next-overflow"))
  metrics.acknowledge()
  let next = metrics_test_bucket(metrics.prepare(2L))
  assert_eq(metrics_test_toggle(next, "flag-0"), @json.null)
  assert_eq(
    metrics_test_toggle(next, "next-0"),
    @json.parse("{\"yes\":1,\"no\":0,\"variants\":{\"blue\":1}}"),
  )
}

///|
test "metrics variant cap counts toggle variant pairs globally without skipping yes no" {
  let metrics = Metrics::new(0L)
  for i in 0..<999 {
    metrics.count("a", true, variant="v\{i}")
  }
  metrics.count("b", false, variant="shared")
  metrics.count("a", true, variant="overflow")
  metrics.count("b", false, variant="shared")
  metrics.count("a", false, variant="v0")
  metrics.count("c", true, variant="shared")
  assert_eq(metrics.variant_pairs, 1000)
  let bucket = metrics_test_bucket(metrics.prepare(1L))
  let a = metrics_test_toggle(bucket, "a")
  assert_eq(field(a, "yes"), @json.Json::number(1000.0))
  assert_eq(field(a, "no"), @json.Json::number(1.0))
  assert_eq(field(field(a, "variants"), "v0"), @json.Json::number(2.0))
  assert_eq(field(field(a, "variants"), "overflow"), @json.null)
  assert_eq(
    metrics_test_toggle(bucket, "b"),
    @json.parse("{\"yes\":0,\"no\":2,\"variants\":{\"shared\":2}}"),
  )
  assert_eq(
    metrics_test_toggle(bucket, "c"),
    @json.parse("{\"yes\":1,\"no\":0,\"variants\":{}}"),
  )
  assert_eq(metrics.variant_pairs, 0)
  metrics.count("next", true, variant="new")
  assert_eq(metrics.variant_pairs, 1)
  metrics.acknowledge()
  let next = metrics_test_bucket(metrics.prepare(2L))
  assert_eq(
    metrics_test_toggle(next, "next"),
    @json.parse("{\"yes\":1,\"no\":0,\"variants\":{\"new\":1}}"),
  )
}

///|
test "metrics names use nonempty 256 byte UTF8 limits not character counts" {
  let metrics = Metrics::new(0L)
  let ascii = "a".repeat(256)
  let unicode = "界".repeat(85) + "a"
  let emoji = "🌍".repeat(64)
  let variant = "é".repeat(128)
  metrics.count("", true, variant="valid")
  metrics.count("a".repeat(257), true)
  metrics.count("界".repeat(86), false)
  metrics.count(emoji + "x", true)
  assert_eq(metrics.prepare(0L), None)
  metrics.count(ascii, true, variant~)
  metrics.count(unicode, true, variant="é".repeat(129))
  metrics.count(unicode, false, variant="")
  metrics.count(emoji, false, variant=emoji)
  assert_eq(metrics.active.length(), 3)
  assert_eq(metrics.variant_pairs, 2)
  let bucket = metrics_test_bucket(metrics.prepare(1L))
  let ascii_toggle = metrics_test_toggle(bucket, ascii)
  assert_eq(field(ascii_toggle, "yes"), @json.Json::number(1.0))
  assert_eq(
    field(field(ascii_toggle, "variants"), variant),
    @json.Json::number(1.0),
  )
  assert_eq(
    metrics_test_toggle(bucket, unicode),
    @json.parse("{\"yes\":1,\"no\":1,\"variants\":{}}"),
  )
  let emoji_toggle = metrics_test_toggle(bucket, emoji)
  assert_eq(field(emoji_toggle, "no"), @json.Json::number(1.0))
  assert_eq(
    field(field(emoji_toggle, "variants"), emoji),
    @json.Json::number(1.0),
  )
}

///|
test "metrics JSON serialization escapes names without changing their keys" {
  let metrics = Metrics::new(0L)
  let name = "flag\"\\\n🌍"
  let variant = "blue\"\\\t"
  metrics.count(name, true, variant~)
  let bucket = metrics_test_bucket(metrics.prepare(1L))
  let toggle = metrics_test_toggle(bucket, name)
  assert_eq(field(toggle, "yes"), @json.Json::number(1.0))
  assert_eq(field(field(toggle, "variants"), variant), @json.Json::number(1.0))
}

///|
test "metrics yes no and variant counters saturate at the safe JSON integer maximum" {
  let metrics = Metrics::new(0L)
  metrics.active["limit"] = (
    9007199254740990L,
    9007199254740990L,
    Map([("blue", 9007199254740990L)]),
  )
  metrics.variant_pairs = 1
  for _ in 0..<2 {
    metrics.count("limit", true, variant="blue")
    metrics.count("limit", false, variant="blue")
  }
  let bucket = metrics_test_bucket(metrics.prepare(1L))
  assert_eq(
    metrics_test_toggle(bucket, "limit"),
    @json.parse(
      (
        #|{"yes":9007199254740991,"no":9007199254740991,"variants":{"blue":9007199254740991}}
      ),
    ),
  )
  assert_eq(metrics_increment(9007199254740990L), 9007199254740991L)
  assert_eq(metrics_increment(9007199254740991L), 9007199254740991L)
  assert_eq(
    metrics_json_integer(9007199254740991L).stringify(),
    "9007199254740991",
  )
}
