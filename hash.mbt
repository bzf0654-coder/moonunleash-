// SPDX-License-Identifier: Apache-2.0
// Unleash normalization adapted from Node SDK 6.12.2;
// Copyright 2020 Bricks Software AS. Modified: MoonBit UTF-8 byte hashing.
// The MurmurHash3 algorithm itself is public domain (Austin Appleby).
// See THIRD_PARTY.md and NOTICE for attribution and changes.

///|
/// MurmurHash3 x86_32 over UTF-8, with explicit unsigned wrapping arithmetic.
fn murmur32(text : String, seed : UInt32) -> UInt32 {
  let data = @utf8.encode(text)
  let mut h = seed
  let mut offset = 0
  while offset + 4 <= data.length() {
    let mut k = data[offset].to_uint() |
      (data[offset + 1].to_uint() << 8) |
      (data[offset + 2].to_uint() << 16) |
      (data[offset + 3].to_uint() << 24)
    k = k * 0xcc9e2d51U
    k = (k << 15) | (k >> 17)
    k = k * 0x1b873593U
    h = h ^ k
    h = (h << 13) | (h >> 19)
    h = h * 5U + 0xe6546b64U
    offset = offset + 4
  }
  let mut tail = 0U
  for i = offset; i < data.length(); i = i + 1 {
    tail = tail | (data[i].to_uint() << ((i - offset) * 8))
  }
  if offset < data.length() {
    tail = tail * 0xcc9e2d51U
    tail = (tail << 15) | (tail >> 17)
    tail = tail * 0x1b873593U
    h = h ^ tail
  }
  h = h ^ data.length().reinterpret_as_uint()
  h = h ^ (h >> 16)
  h = h * 0x85ebca6bU
  h = h ^ (h >> 13)
  h = h * 0xc2b2ae35U
  h ^ (h >> 16)
}

///|
fn bucket(id : String, group : String, scale : Int32, seed : UInt32) -> Int32 {
  (murmur32("\{group}:\{id}", seed) % scale.reinterpret_as_uint()).reinterpret_as_int() +
  1
}
