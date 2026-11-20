///|
test "IP parser handles canonical compression embedded IPv4 and valid zones" {
  assert_eq(parse_ip("::1"), parse_ip("0:0:0:0:0:0:0:1"))
  assert_eq(parse_ip("2001:DB8::ABCD"), parse_ip("2001:db8:0:0:0:0:0:abcd"))
  assert_eq(parse_ip("::ffff:192.0.2.1"), parse_ip("0:0:0:0:0:ffff:c000:201"))
  assert_eq(parse_ip("fe80::1%eth0"), parse_ip("fe80::1"))
  assert_eq(parse_ip("127.0.0.1"), Some([127, 0, 0, 1]))
  for
    value in [
      "", "...", "127.1", "256.0.0.1", "-1.0.0.0", "1.2.3.4.5", "1.2.3.4 ", "1::2::3",
      "1:2:3", "1:2:3:4:5:6:7:8:9", "1:2:3:4:5:6:7:", "2001:::1", "gggg::1", "192.0.2.1::",
      "::ffff:999.0.0.1", "fe80::1%", "127.0.0.1%eth0",
    ] {
    assert_eq(parse_ip(value), None, msg=value)
  }
}

///|
test "CIDR matches bit prefixes rather than text and separates address families" {
  assert_true(ip_in_range("192.168.1.255", "192.168.1.128/25"))
  assert_false(ip_in_range("192.168.1.127", "192.168.1.128/25"))
  assert_true(ip_in_range("192.168.1.42", "192.168.1.99/24"))
  assert_true(ip_in_range("255.255.255.255", "0.0.0.0/0"))
  assert_false(ip_in_range("128.0.0.0", "0.0.0.0/1"))
  assert_true(ip_in_range("127.255.255.255", "0.0.0.0/1"))
  assert_true(ip_in_range("2001:db8::a", "2001:DB8:0:0:0:0:0:a/128"))
  assert_true(ip_in_range("2001:db8:ffff::1", "2001:db8::/32"))
  assert_false(ip_in_range("2001:db9::1", "2001:db8::/32"))
  assert_true(ip_in_range("ffff::1", "::/0"))
  assert_false(ip_in_range("127.0.0.1", "::/0"))
  assert_false(ip_in_range("::ffff:127.0.0.1", "127.0.0.0/8"))
  for
    range in [
      "127.invalid", "127.0.0.1/-1", "127.0.0.1/33", "127.0.0.1/24/8", "127.0.0.1/",
      "127.0.0.1/a",
    ] {
    assert_false(ip_in_range("127.0.0.1", range), msg=range)
  }
  assert_false(ip_in_range("::1", "::/129"))
  assert_false(ip_in_range("invalid", "0.0.0.0/0"))
}

///|
test "legacy remote strategy supports exact matches and IPv4 CIDR without DNS" {
  assert_true(
    matches_remote_address("127.0.0.1, 192.168.1.0/24", Some("192.168.1.42")),
  )
  assert_true(matches_remote_address("2001:db8::1", Some("2001:db8::1")))
  assert_false(matches_remote_address("2001:db8::/32", Some("2001:db8::1")))
  assert_false(matches_remote_address("127.0.0.1", None))
  assert_false(matches_remote_address("", Some("")))
}
