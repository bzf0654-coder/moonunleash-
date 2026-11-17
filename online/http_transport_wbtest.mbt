///|
test "streaming transport preserves authority and exact request path" {
  let cases = [
    (
      "https://example.test:4242/api/client/features", "https://example.test:4242",
      "/api/client/features",
    ),
    (
      "http://localhost:4242/nested/api/client/register", "http://localhost:4242",
      "/nested/api/client/register",
    ),
    (
      "https://[::1]:4242/one%20two/client/features", "https://[::1]:4242", "/one%20two/client/features",
    ),
    ("https://example.test", "https://example.test", "/"),
    ("https://example.test//nested/", "https://example.test", "//nested/"),
  ]
  for (url, origin, path) in cases {
    let (actual_origin, actual_path) = http_target(url)
    assert_eq(actual_origin, origin)
    assert_eq(actual_path, path)
  }
  for url in ["relative/path", "ftp://example.test/path", "https:///path"] {
    let rejected = try {
      ignore(http_target(url))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}
