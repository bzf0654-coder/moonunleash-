// SPDX-License-Identifier: Apache-2.0
// Local RFC 3339/date-only parsing with Gregorian validation and UTC offsets.
// Wall-clock fallback uses core/env, not a hard-coded date or network service.

///|
fn date_digits(chars : Array[Char], start : Int32, count : Int32) -> Int32? {
  if start < 0 || start + count > chars.length() {
    return None
  }
  let mut value = 0
  for i in start..<(start + count) {
    let c = chars[i]
    if c < '0' || c > '9' {
      return None
    }
    value = value * 10 + c.to_int() - 48
  }
  Some(value)
}

///|
fn date_leap_year(year : Int32) -> Bool {
  year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

///|
fn date_year_ordinal(year : Int32) -> Int32 {
  // Shift both dates by a complete 400-year Gregorian cycle so all operands
  // remain nonnegative, including the ISO year 0000.
  let y = year + 399
  365 * y + y / 4 - y / 100 + y / 400
}

///|
fn parse_iso_timestamp(value : String) -> Int64? {
  if value.length() < 10 || value.length() > 64 {
    return None
  }
  let chars = value.to_array()
  if chars.length() < 10 {
    return None
  }
  if chars[4] != '-' || chars[7] != '-' {
    return None
  }
  guard date_digits(chars, 0, 4) is Some(year) else { return None }
  guard date_digits(chars, 5, 2) is Some(month) else { return None }
  guard date_digits(chars, 8, 2) is Some(day) else { return None }
  let months = [
    31,
    if date_leap_year(year) {
      29
    } else {
      28
    },
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
  if month < 1 || month > 12 || day < 1 || day > months[month - 1] {
    return None
  }
  let mut ordinal = date_year_ordinal(year) - date_year_ordinal(1970) + day - 1
  for i in 0..<(month - 1) {
    ordinal = ordinal + months[i]
  }
  let midnight = ordinal.to_int64() * 86400000L
  if chars.length() == 10 {
    return Some(midnight)
  }
  if chars.length() < 20 ||
    (chars[10] != 'T' && chars[10] != 't' && chars[10] != ' ') ||
    chars[13] != ':' ||
    chars[16] != ':' {
    return None
  }
  guard date_digits(chars, 11, 2) is Some(hour) else { return None }
  guard date_digits(chars, 14, 2) is Some(minute) else { return None }
  guard date_digits(chars, 17, 2) is Some(second) else { return None }
  if hour > 23 || minute > 59 || second > 59 {
    return None
  }
  let mut pos = 19
  let mut millis = 0
  if chars[pos] == '.' {
    pos = pos + 1
    let start = pos
    let mut scale = 100
    while pos < chars.length() && chars[pos] >= '0' && chars[pos] <= '9' {
      if scale > 0 {
        millis = millis + (chars[pos].to_int() - 48) * scale
        scale = scale / 10
      }
      pos = pos + 1
    }
    if pos == start {
      return None
    }
  }
  if pos >= chars.length() {
    return None
  }
  let mut offset = 0
  match chars[pos] {
    'Z' | 'z' => if pos + 1 != chars.length() { return None }
    '+' | '-' => {
      if pos + 6 != chars.length() || chars[pos + 3] != ':' {
        return None
      }
      guard date_digits(chars, pos + 1, 2) is Some(h) else { return None }
      guard date_digits(chars, pos + 4, 2) is Some(m) else { return None }
      if h > 23 || m > 59 {
        return None
      }
      offset = (h * 60 + m) * 60000
      if chars[pos] == '-' {
        offset = -offset
      }
    }
    _ => return None
  }
  Some(
    midnight +
    (hour * 3600000 + minute * 60000 + second * 1000 + millis).to_int64() -
    offset.to_int64(),
  )
}

///|
fn matches_date(operator : String, ctx : Context, expected : String) -> Bool {
  guard parse_iso_timestamp(expected) is Some(expected) else { return false }
  let actual = match field(ctx.data, "currentTime") {
    String(s) if s != "" => parse_iso_timestamp(s)
    Number(n, ..) if n != 0 &&
      n >= -8640000000000000.0 &&
      n <= 8640000000000000.0 => Some(n.to_int64())
    True => Some(1L)
    Null | False | String("") | Number(0, ..) =>
      Some(@env.now().reinterpret_as_int64())
    _ => None
  }
  guard actual is Some(actual) else { return false }
  match operator {
    "DATE_AFTER" => actual > expected
    "DATE_BEFORE" => actual < expected
    _ => false
  }
}
