///|
test "MurmurHash3 independent published x86_32 vectors" {
  assert_eq(murmur32("", 0U), 0U)
  assert_eq(murmur32("foo", 0U), 0xf6a5c420U)
  assert_eq(murmur32("hello", 0U), 0x248bfa47U)
}

///|
test "bucket range and Unicode determinism" {
  for scale in [1, 2, 100, 1000] {
    for user in ["", "user-42", "中文用户", "😊"] {
      let n = bucket(user, "checkout", scale, 86028157U)
      assert_true(n >= 1 && n <= scale)
      assert_eq(n, bucket(user, "checkout", scale, 86028157U))
    }
  }
}
