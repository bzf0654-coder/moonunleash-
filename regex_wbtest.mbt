///|
fn regex_check(
  pattern : String,
  actual : String,
  insensitive~ : Bool = false,
) -> Bool {
  match compile_unleash_regex(pattern, insensitive) {
    Some(regex) => regex.execute(actual[:]).matched()
    None => false
  }
}

///|
test "native regex adapter implements lexical scopes ASCII classes and Unicode literals" {
  assert_true(regex_check("^(?i)abc$", "AbC"))
  assert_true(regex_check("^(a(?i)b|c)d$", "aBd"))
  assert_false(regex_check("^(a(?i)b|c)d$", "aBD"))
  assert_true(regex_check("^(?i)a(?-i)b$", "Ab"))
  assert_false(regex_check("^(?i)a(?-i)b$", "AB"))
  assert_true(regex_check("^(?U)a.*b$", "ab"))
  assert_true(regex_check("^[[:alpha:]]+$", "AbC"))
  assert_false(regex_check("^[[:alpha:]]+$", "é"))
  assert_true(regex_check("^[[:^alpha:]]+$", "🔥123"))
  assert_true(regex_check("^[^^]+$", "letters"))
  assert_false(regex_check("^[^^]+$", "a^b"))
  assert_true(regex_check("^\\s$", "\u000c"))
  assert_false(regex_check("^\\s$", "\u000b"))
  assert_false(regex_check("^\\s$", "\u00a0"))
  assert_true(regex_check("^[[:space:]]$", "\u000b"))
  assert_true(regex_check("^\\S$", "\u00a0"))
  assert_true(regex_check("\\bcat\\b", "écaté"))
  assert_true(regex_check("^\\x{1f525}$", "🔥"))
  assert_true(regex_check("^\\x61$", "a"))
  assert_true(regex_check("^\\141$", "a"))
  assert_true(regex_check("^\\Q(a+b)*\\E$", "(a+b)*"))
  assert_false(regex_check("^\\Q(a+b)*\\E$", "ab"))
  assert_true(regex_check("(?m)\\Afoo\\z", "foo"))
  assert_false(regex_check("(?m)\\Afoo\\z", "foo\n"))
  assert_true(regex_check("^abc$", "ABC", insensitive=true))
}

///|
test "unscoped regex flags preserve alternation branches and enclosing scope" {
  let pattern = "^(?:a(?i)b|c)$"
  assert_eq(regex_rewrite(pattern), Some("^(?:a(?i:b)|(?i:c))$"))
  for actual in ["ab", "aB", "c", "C"] {
    assert_true(regex_check(pattern, actual), msg=actual)
  }
  for actual in ["aC", "AB"] {
    assert_false(regex_check(pattern, actual), msg=actual)
  }
  let nested = "^(?:x(?:a(?i)b|c)d|e)$"
  for actual in ["xaBd", "xCd", "e"] {
    assert_true(regex_check(nested, actual), msg=actual)
  }
  for actual in ["xaCd", "xCD", "E"] {
    assert_false(regex_check(nested, actual), msg=actual)
  }
  let toggled = "^(?:a(?i)b(?-i)c|d|(?i)e)$"
  for actual in ["aBc", "d", "e", "E"] {
    assert_true(regex_check(toggled, actual), msg=actual)
  }
  for actual in ["aBC", "D"] {
    assert_false(regex_check(toggled, actual), msg=actual)
  }
  let scoped = "^(?i:a(?-i)b|c)d$"
  for actual in ["Abd", "cd"] {
    assert_true(regex_check(scoped, actual), msg=actual)
  }
  for actual in ["aBd", "Cd", "cD"] {
    assert_false(regex_check(scoped, actual), msg=actual)
  }
}

///|
test "hex and octal regex escapes retain case folding and atom boundaries" {
  for pattern in ["^\\x61$", "^\\141$"] {
    assert_true(regex_check(pattern, "A", insensitive=true), msg=pattern)
    assert_false(regex_check(pattern, "A"), msg=pattern)
  }
  assert_true(regex_check("^(?i:\\x61|\\141)$", "A"))
  assert_true(regex_check("^\\x{e9}$", "É", insensitive=true))
  assert_true(regex_check("^\\x{3b1}$", "Α", insensitive=true))
  assert_true(regex_check("^[\\x61-\\x63]$", "B", insensitive=true))
  assert_true(regex_check("^[\\141-\\143]$", "C", insensitive=true))
  assert_true(regex_check("^\\x61+$", "AA", insensitive=true))
}

///|
test "unsupported regex features and oversized compiler expansion never reach matching" {
  for
    pattern in [
      "(?=a)a", "(?!a)b", "(?<=a)b", "(?<!a)b", "(a)\\1", "(?<a>x)\\k<a>", "a{1001}",
      "(a{1000}){1000}", "(broken", "[broken",
    ] {
    assert_true(compile_unleash_regex(pattern, false) is None, msg=pattern)
  }
  let nested = StringBuilder()
  for _ in 0..<65 {
    nested.write_string("(")
  }
  nested.write_string("a")
  for _ in 0..<65 {
    nested.write_string(")")
  }
  assert_true(compile_unleash_regex(nested.to_string(), false) is None)
  assert_true(regex_check("^a{1000}$", "a".repeat(1000)))
}

///|
test "regex snapshots retain a bounded eager cache and support uncached expressions" {
  let source = StringBuilder()
  source.write_string("{\"version\":2,\"features\":[")
  for i in 0..<101 {
    if i != 0 {
      source.write_string(",")
    }
    source.write_string(
      "{\"name\":\"flag-\{i}\",\"enabled\":true,\"strategies\":[{\"name\":\"default\",\"constraints\":[{\"contextName\":\"userId\",\"operator\":\"REGEX\",\"value\":\"^user-\{i}$\"}]}]}",
    )
  }
  source.write_string("]}")
  let snapshot = Snapshot::parse(source.to_string())
  assert_eq(snapshot.regexes.length(), 100)
  assert_true(snapshot.is_enabled("flag-100", Context::new(user_id="user-100")))
  assert_false(snapshot.is_enabled("flag-100", Context::new(user_id="user-1")))
  assert_eq(snapshot.regexes.length(), 100)
}
