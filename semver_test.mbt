///|
fn semver_check(
  operator : String,
  actual : String,
  value : String,
) -> Bool raise {
  let state = @sdk.Snapshot::parse(
    "{\"version\":2,\"features\":[{\"name\":\"versioned\",\"enabled\":true,\"strategies\":[{\"name\":\"default\",\"constraints\":[{\"contextName\":\"version\",\"operator\":\"\{operator}\",\"value\":\"\{value}\"}]}]}]}",
  )
  state.is_enabled(
    "versioned",
    @sdk.Context::parse("{\"properties\":{\"version\":\"\{actual}\"}}"),
  )
}

///|
test "semantic versions follow complete prerelease precedence and ignore build metadata" {
  let versions = [
    "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta", "1.0.0-beta.2",
    "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0",
  ]
  for i in 0..<(versions.length() - 1) {
    assert_true(
      semver_check("SEMVER_LT", versions[i], versions[i + 1]),
      msg=versions[i] + " < " + versions[i + 1],
    )
    assert_true(semver_check("SEMVER_GT", versions[i + 1], versions[i]))
  }
  assert_true(semver_check("SEMVER_EQ", "1.2.3+001.linux", "1.2.3+other"))
  assert_true(semver_check("SEMVER_GTE", "2.0.0", "2.0.0"))
  assert_true(semver_check("SEMVER_LTE", "2.0.0", "2.0.0"))
  assert_false(semver_check("SEMVER_GT", "2.0.0+new", "2.0.0+old"))
  assert_true(semver_check("SEMVER_GT", "1.10.0", "1.9.9"))
  assert_true(
    semver_check(
      "SEMVER_GT", "1.0.0-alpha.999999999999999999999999999999", "1.0.0-alpha.999999999999999999999999999998",
    ),
  )
}

///|
test "invalid semantic versions fail without coercion or prefix stripping" {
  for
    value in [
      "", "1", "1.2", "1.2.3.4", "01.2.3", "1.02.3", "1.2.03", "1.2.3-01", "1.2.3-",
      "1.2.3+", "1.2.3-alpha..1", "1.2.3+build..1", "1.2.3+a+b", "1.2.3-β", "v1.2.3",
      "=1.2.3", " 1.2.3", "1.2.3 ", "9007199254740992.0.0",
    ] {
    assert_false(semver_check("SEMVER_EQ", value, "1.2.3"), msg=value)
    assert_false(semver_check("SEMVER_GT", "9.0.0", value), msg=value)
  }
}
