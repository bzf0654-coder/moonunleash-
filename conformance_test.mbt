///|
fn get(value : @json.Json, key : String) -> @json.Json {
  match value {
    Object(m) => m.get(key).unwrap_or(@json.null)
    _ => @json.null
  }
}

///|
fn run_boolean_spec(source : String) -> Unit raise {
  let spec = @json.parse(source)
  let snapshot = @sdk.Snapshot::parse(get(spec, "state").stringify())
  let cases = match get(spec, "tests") {
    Array(xs) => xs
    Null => []
    _ => fail("Invalid boolean cases")
  }
  for c in cases {
    guard get(c, "toggleName") is String(name) else {
      fail("Missing toggleName")
    }
    let ctx = @sdk.Context::parse(get(c, "context").stringify())
    let expected = match get(c, "expectedResult") {
      True => true
      False => false
      _ => fail("Bad expectation")
    }
    let decision = snapshot.evaluate(name, ctx)
    assert_true(decision.enabled == expected, msg=c.stringify())
  }
  if get(spec, "variantTests") is Array(cases) {
    for c in cases {
      guard get(c, "toggleName") is String(name) else {
        fail("Missing toggleName")
      }
      let ctx = @sdk.Context::parse(get(c, "context").stringify())
      let actual = snapshot.get_variant(name, ctx).to_json()
      assert_true(actual == get(c, "expectedResult"), msg=c.stringify())
    }
  }
}

///|
test "official 01 basic flags" {
  run_boolean_spec(fixture_01)
}

///|
test "official 02 user with id" {
  run_boolean_spec(fixture_02)
}

///|
test "official 03 legacy user rollout" {
  run_boolean_spec(fixture_03)
}

///|
test "official 04 legacy session rollout" {
  run_boolean_spec(fixture_04)
}

///|
test "official 05 random rollout" {
  run_boolean_spec(fixture_05)
}

///|
test "official 07 multiple strategies" {
  run_boolean_spec(fixture_07)
}

///|
test "official 08 global variants" {
  run_boolean_spec(fixture_08)
}

///|
test "official 09 constraints" {
  run_boolean_spec(fixture_09)
}

///|
test "official 10 flexible rollout" {
  run_boolean_spec(fixture_10)
}

///|
test "official 11 constraint edges" {
  run_boolean_spec(fixture_11)
}

///|
test "official 12 custom stickiness" {
  run_boolean_spec(fixture_12)
}

///|
test "official 16 strategy variants" {
  run_boolean_spec(fixture_16)
}

///|
test "official 18 UTF8 names" {
  run_boolean_spec(fixture_18)
}
