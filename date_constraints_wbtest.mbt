///|
test "ISO dates normalize UTC offsets milliseconds and Gregorian leap years" {
  for
    value in [
      "1970-01-01", "1970-01-01T00:00:00Z", "1970-01-01T08:00:00+08:00", "1969-12-31T18:30:00-05:30",
    ] {
    assert_eq(parse_iso_timestamp(value), Some(0L), msg=value)
  }
  assert_eq(parse_iso_timestamp("1969-12-31T23:59:59.999Z"), Some(-1L))
  assert_eq(parse_iso_timestamp("1970-01-01T00:00:00.123456Z"), Some(123L))
  assert_eq(parse_iso_timestamp("2000-01-01"), Some(946684800000L))
  assert_eq(parse_iso_timestamp("2000-02-29"), Some(951782400000L))
  assert_eq(parse_iso_timestamp("0000-01-01"), Some(-62167219200000L))
  for
    value in [
      "", "🔥🔥🔥🔥🔥", "2023-02-29", "1900-02-29", "2024-02-30", "2024-00-01",
      "2024-13-01", "2024-01-00", "1970-01-01T24:00:00Z", "1970-01-01T00:60:00Z",
      "1970-01-01T00:00:60Z", "1970-01-01T00:00:00.Z", "1970-01-01T00:00:00+24:00",
      "1970-01-01T00:00:00Zjunk",
    ] {
    assert_eq(parse_iso_timestamp(value), None, msg=value)
  }
}

///|
test "date comparisons use explicit currentTime and strict before after boundaries" {
  let ctx = Context::parse("{\"currentTime\":\"1970-01-01T08:00:00+08:00\"}")
  assert_false(matches_date("DATE_AFTER", ctx, "1970-01-01T00:00:00Z"))
  assert_false(matches_date("DATE_BEFORE", ctx, "1970-01-01T00:00:00Z"))
  assert_true(matches_date("DATE_AFTER", ctx, "1969-12-31T23:59:59.999Z"))
  assert_true(matches_date("DATE_BEFORE", ctx, "1970-01-01T00:00:00.001Z"))
  assert_false(
    matches_date(
      "DATE_AFTER",
      Context::parse("{\"currentTime\":\"bad\"}"),
      "1970-01-01",
    ),
  )
  assert_true(matches_date("DATE_AFTER", Context::new(), "0000-01-01"))
  assert_true(matches_date("DATE_BEFORE", Context::new(), "9999-12-31"))
}
