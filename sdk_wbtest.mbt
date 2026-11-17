///|
test "MurmurHash3 independent published x86_32 vectors" {
  assert_eq(murmur32("", 0U), 0U)
  assert_eq(murmur32("foo", 0U), 0xf6a5c420U)
  assert_eq(murmur32("hello", 0U), 0x248bfa47U)
}

///|
test "UTF-8 byte hash matches pinned primitive vectors, not raw JS strings" {
  // Reproduce with tools/hash-diagnostic.mjs (murmurhash3js 3.0.1 byte view).
  for
    (input, strategy_hash, variant_hash) in [
      ("共享组-🌍:用户甲", 1483014240U, 3371132993U),
      ("全局变体-ø:用户乙", 1829003578U, 3555707867U),
      ("checkout:é", 2987043074U, 3485684207U),
      ("checkout:é", 4260123421U, 3211497284U),
      ("checkout:😊", 3006800575U, 2543312902U),
    ] {
    assert_eq(murmur32(input, 0U), strategy_hash)
    assert_eq(murmur32(input, 86028157U), variant_hash)
  }
  assert_eq(bucket("用户甲", "共享组-🌍", 100, 0U), 41)
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
