///|
test "semantic version parser preserves core and prerelease identifiers" {
  guard parse_semver("1.0.0-alpha.1") is Some(version) else {
    fail("valid prerelease rejected")
  }
  assert_eq(version.core, ["1", "0", "0"])
  assert_eq(version.prerelease, ["alpha", "1"])
  assert_eq(compare_semver("1.0.0-alpha", "1.0.0-alpha.1"), Some(-1))
  assert_eq(compare_semver("2.0.0-beta.1", "2.0.0-alpha.1"), Some(1))
}
