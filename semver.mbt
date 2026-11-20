// SPDX-License-Identifier: Apache-2.0
// Semantic Versioning 2.0.0 comparison, implemented in MoonBit.
// Specification: https://semver.org/spec/v2.0.0.html
// Numeric identifiers are compared as digit strings to avoid integer overflow.

///|
priv struct SemVersion {
  core : Array[String]
  prerelease : Array[String]
}

///|
fn version_parts(value : String) -> Array[String] {
  let parts = []
  for part in value.split(".") {
    parts.push(part.to_owned())
  }
  parts
}

///|
fn version_digits(value : String) -> Bool {
  value != "" && value.to_array().all(fn(c) { c >= '0' && c <= '9' })
}

///|
fn version_identifier(value : String) -> Bool {
  value != "" &&
  value
  .to_array()
  .all(fn(c) {
    (c >= '0' && c <= '9') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= 'a' && c <= 'z') ||
    c == '-'
  })
}

///|
fn parse_semver(value : String) -> SemVersion? {
  if value == "" || value.length() > 256 {
    return None
  }
  let mut main = ""
  let mut build = ""
  let mut has_build = false
  for c in value.to_array() {
    if c == '+' {
      if has_build {
        return None
      }
      has_build = true
    } else if has_build {
      build = build + "\{c}"
    } else {
      main = main + "\{c}"
    }
  }
  if has_build && (build == "" || !version_parts(build).all(version_identifier)) {
    return None
  }
  let mut core_text = ""
  let mut pre_text = ""
  let mut has_pre = false
  for c in main.to_array() {
    if c == '-' && !has_pre {
      has_pre = true
    } else if has_pre {
      pre_text = pre_text + "\{c}"
    } else {
      core_text = core_text + "\{c}"
    }
  }
  let core = version_parts(core_text)
  if core.length() != 3 {
    return None
  }
  for part in core {
    if !version_digits(part) ||
      (part.length() > 1 && part.has_prefix("0")) ||
      part.length() > 16 ||
      (
        part.length() == 16 &&
        compare_version_lexical(part, "9007199254740991") > 0
      ) {
      return None
    }
  }
  if has_pre && pre_text == "" {
    return None
  }
  let prerelease = if has_pre { version_parts(pre_text) } else { [] }
  for part in prerelease {
    if !version_identifier(part) ||
      (version_digits(part) && part.length() > 1 && part.has_prefix("0")) {
      return None
    }
  }
  Some({ core, prerelease, })
}

///|
fn compare_version_lexical(a : String, b : String) -> Int32 {
  let left = a.to_array()
  let right = b.to_array()
  for i in 0..<left.length() {
    if i >= right.length() {
      return 1
    }
    if left[i] < right[i] {
      return -1
    }
    if left[i] > right[i] {
      return 1
    }
  }
  if left.length() < right.length() {
    -1
  } else {
    0
  }
}

///|
fn compare_version_number(a : String, b : String) -> Int32 {
  if a.length() < b.length() {
    -1
  } else if a.length() > b.length() {
    1
  } else {
    compare_version_lexical(a, b)
  }
}

///|
fn compare_semver(a : String, b : String) -> Int32? {
  guard parse_semver(a) is Some(a) else { return None }
  guard parse_semver(b) is Some(b) else { return None }
  for i in 0..<3 {
    let cmp = compare_version_number(a.core[i], b.core[i])
    if cmp != 0 {
      return Some(cmp)
    }
  }
  if a.prerelease.is_empty() && b.prerelease.is_empty() {
    return Some(0)
  }
  if a.prerelease.is_empty() {
    return Some(1)
  }
  if b.prerelease.is_empty() {
    return Some(-1)
  }
  for i in 0..<a.prerelease.length() {
    if i >= b.prerelease.length() {
      return Some(1)
    }
    let left = a.prerelease[i]
    let right = b.prerelease[i]
    if left == right {
      continue
    }
    let left_number = version_digits(left)
    let right_number = version_digits(right)
    let cmp = if left_number && right_number {
      compare_version_number(left, right)
    } else if left_number {
      -1
    } else if right_number {
      1
    } else {
      compare_version_lexical(left, right)
    }
    return Some(cmp)
  }
  if a.prerelease.length() < b.prerelease.length() {
    Some(-1)
  } else {
    Some(0)
  }
}

///|
fn matches_semver(operator : String, actual : String?, value : String) -> Bool {
  guard actual is Some(actual) else { return false }
  guard compare_semver(actual, value) is Some(cmp) else { return false }
  match operator {
    "SEMVER_EQ" => cmp == 0
    "SEMVER_LT" => cmp < 0
    "SEMVER_LTE" => cmp <= 0
    "SEMVER_GT" => cmp > 0
    "SEMVER_GTE" => cmp >= 0
    _ => false
  }
}
