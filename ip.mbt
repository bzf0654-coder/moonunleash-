// SPDX-License-Identifier: Apache-2.0
// Portable IPv4/IPv6 and CIDR bit-prefix matching (no DNS/network access).
// Legacy strategy adapter aligned with Unleash Node SDK 6.12.2;
// Copyright 2020 Bricks Software AS. The address parser is implemented in MoonBit.

///|
fn address_parts(value : String, separator : String) -> Array[String] {
  let parts = []
  for part in value.split(separator) {
    parts.push(part.to_owned())
  }
  parts
}

///|
fn address_decimal(value : String, max_digits : Int32) -> Int32? {
  if value == "" || value.length() > max_digits {
    return None
  }
  let mut result = 0
  for c in value.to_array() {
    if c < '0' || c > '9' {
      return None
    }
    result = result * 10 + c.to_int() - 48
  }
  Some(result)
}

///|
fn parse_ipv4(value : String) -> Array[Int32]? {
  let parts = address_parts(value, ".")
  if parts.length() != 4 {
    return None
  }
  let bytes = []
  for part in parts {
    guard address_decimal(part, 3) is Some(n) && n <= 255 else { return None }
    bytes.push(n)
  }
  Some(bytes)
}

///|
fn ipv6_words(value : String) -> Array[Int32]? {
  if value == "" {
    return Some([])
  }
  let parts = address_parts(value, ":")
  let words = []
  for i in 0..<parts.length() {
    let part = parts[i]
    if part.contains(".") {
      if i + 1 != parts.length() {
        return None
      }
      guard parse_ipv4(part) is Some(bytes) else { return None }
      words.push(bytes[0] * 256 + bytes[1])
      words.push(bytes[2] * 256 + bytes[3])
    } else {
      if part == "" || part.length() > 4 {
        return None
      }
      let mut word = 0
      for c in part.to_array() {
        let digit = if c >= '0' && c <= '9' {
          c.to_int() - 48
        } else if c >= 'a' && c <= 'f' {
          c.to_int() - 87
        } else if c >= 'A' && c <= 'F' {
          c.to_int() - 55
        } else {
          return None
        }
        word = word * 16 + digit
      }
      words.push(word)
    }
  }
  Some(words)
}

///|
fn parse_ip(value : String) -> Array[Int32]? {
  if value == "" || value.length() > 160 {
    return None
  }
  let zones = address_parts(value, "%")
  if zones.length() > 2 {
    return None
  }
  if zones.length() == 2 {
    if zones[1] == "" ||
      !zones[0].contains(":") ||
      !zones[1]
      .to_array()
      .all(fn(c) {
        (c >= '0' && c <= '9') ||
        (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        c == '_' ||
        c == '-' ||
        c == '.'
      }) {
      return None
    }
  }
  let value = zones[0]
  if !value.contains(":") {
    return parse_ipv4(value)
  }
  let sides = address_parts(value, "::")
  let words = []
  if sides.length() == 1 {
    guard ipv6_words(value) is Some(parsed) && parsed.length() == 8 else {
      return None
    }
    for word in parsed {
      words.push(word)
    }
  } else if sides.length() == 2 {
    guard ipv6_words(sides[0]) is Some(left) else { return None }
    guard ipv6_words(sides[1]) is Some(right) else { return None }
    if left.length() + right.length() >= 8 || sides[0].contains(".") {
      return None
    }
    for word in left {
      words.push(word)
    }
    for _ in 0..<(8 - left.length() - right.length()) {
      words.push(0)
    }
    for word in right {
      words.push(word)
    }
  } else {
    return None
  }
  let bytes = []
  for word in words {
    bytes.push(word / 256)
    bytes.push(word % 256)
  }
  Some(bytes)
}

///|
fn ip_in_range(actual : String, range : String) -> Bool {
  guard parse_ip(actual) is Some(actual) else { return false }
  let range = address_parts(range, "/")
  if range.length() < 1 || range.length() > 2 {
    return false
  }
  guard parse_ip(range[0]) is Some(network) else { return false }
  if actual.length() != network.length() {
    return false
  }
  let mut remaining = actual.length() * 8
  if range.length() == 2 {
    guard address_decimal(range[1], 3) is Some(prefix) && prefix <= remaining else {
      return false
    }
    remaining = prefix
  }
  for i in 0..<actual.length() {
    if remaining >= 8 {
      if actual[i] != network[i] {
        return false
      }
      remaining = remaining - 8
    } else if remaining > 0 {
      let divisor = match remaining {
        1 => 128
        2 => 64
        3 => 32
        4 => 16
        5 => 8
        6 => 4
        _ => 2
      }
      return actual[i] / divisor == network[i] / divisor
    } else {
      return true
    }
  }
  true
}

///|
fn matches_remote_address(ips : String, actual : String?) -> Bool {
  if ips == "" {
    return false
  }
  guard actual is Some(actual) && actual != "" else { return false }
  // Legacy strategy: exact strings (including IPv6) or IPv4 subnets. The modern
  // IN_CIDR operator below also supports IPv6 prefix ranges.
  ips
  .split(",")
  .any(fn(range) {
    let range = range.trim().to_owned()
    if range == actual {
      true
    } else {
      match parse_ip(actual) {
        Some(bytes) if bytes.length() == 4 => ip_in_range(actual, range)
        _ => false
      }
    }
  })
}
