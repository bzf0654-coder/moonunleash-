// SPDX-License-Identifier: Apache-2.0
// RE2-facing syntax adapter over pinned, MoonBit-native moonbitlang/regexp.
// No host JavaScript RegExp, subprocess or FFI participates in evaluation.
// Backreferences/look-around are rejected before the VM can select its
// exponential backreference execution path. See docs/REGEX.md for limits.

///|
fn regex_ascii_member(name : String, n : Int32) -> Bool {
  let digit = n >= 48 && n <= 57
  let lower = n >= 97 && n <= 122
  let upper = n >= 65 && n <= 90
  match name {
    "alnum" => digit || lower || upper
    "alpha" => lower || upper
    "ascii" => true
    "blank" => n == 9 || n == 32
    "cntrl" => n < 32 || n == 127
    "digit" => digit
    "graph" => n >= 33 && n <= 126
    "lower" => lower
    "print" => n >= 32 && n <= 126
    "punct" => n >= 33 && n <= 126 && !(digit || lower || upper)
    "space" => (n >= 9 && n <= 13) || n == 32
    "upper" => upper
    "word" => digit || lower || upper || n == 95
    "xdigit" => digit || (n >= 65 && n <= 70) || (n >= 97 && n <= 102)
    "perl_space" => n == 9 || n == 10 || n == 12 || n == 13 || n == 32
    _ => false
  }
}

///|
fn regex_hex_escape(n : Int32) -> String {
  let hex = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f",
  ]
  "\\u0" + hex[n / 256] + hex[n / 16 % 16] + hex[n % 16]
}

///|
fn regex_ascii_ranges(name : String, negative : Bool) -> String? {
  match name {
    "alnum"
    | "alpha"
    | "ascii"
    | "blank"
    | "cntrl"
    | "digit"
    | "graph"
    | "lower"
    | "print"
    | "punct"
    | "space"
    | "upper"
    | "word"
    | "xdigit"
    | "perl_space" => ()
    _ => return None
  }
  let out = StringBuilder()
  let mut start = -1
  for n in 0..<129 {
    let included = n < 128 && regex_ascii_member(name, n) != negative
    if included && start < 0 {
      start = n
    }
    if !included && start >= 0 {
      out.write_string(regex_hex_escape(start))
      if start + 1 < n {
        out.write_string("-")
        out.write_string(regex_hex_escape(n - 1))
      }
      start = -1
    }
  }
  if negative {
    out.write_string("\\u0080-\\u{10ffff}")
  }
  Some(out.to_string())
}

///|
fn regex_rewrite(pattern : String) -> String? {
  if pattern.length() > 4096 {
    return None
  }
  let chars = pattern.to_array()
  let out = StringBuilder()
  // An unscoped RE2 flag applies through the enclosing group's remainder.
  // Keep each synthetic flag scope so an alternation can close/reopen it:
  // a(?i)b|c must become a(?i:b)|(?i:c), not a(?i:b|c).
  let scopes : Array[Array[String]] = [[]]
  let mut depth = 0
  let mut in_class = false
  let mut class_first = false
  let mut class_allow_caret = false
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '\\' {
      if i + 1 >= chars.length() {
        return None
      }
      let escape = chars[i + 1]
      if escape >= '0' && escape <= '9' {
        if escape > '7' {
          return None
        }
        let mut j = i + 1
        let mut value = 0
        while j < chars.length() &&
              j < i + 4 &&
              chars[j] >= '0' &&
              chars[j] <= '7' {
          value = value * 8 + chars[j].to_int() - 48
          j = j + 1
        }
        // A single nonzero digit is an unsupported backreference, not octal.
        if escape != '0' && j == i + 2 {
          return None
        }
        // The VM folds character classes, but not standalone Unicode escapes.
        let escaped = regex_hex_escape(value)
        out.write_string(if in_class { escaped } else { "[" + escaped + "]" })
        i = j
        class_first = false
        continue
      }
      if escape == 'k' || escape == 'g' || escape == 'C' {
        return None
      }
      if escape == 's' || escape == 'S' {
        guard regex_ascii_ranges("perl_space", escape == 'S') is Some(ranges) else {
          return None
        }
        if !in_class {
          out.write_string("[")
        }
        out.write_string(ranges)
        if !in_class {
          out.write_string("]")
        }
        i = i + 2
        class_first = false
        continue
      }
      if escape == 'a' {
        out.write_string("\\u0007")
        i = i + 2
        class_first = false
        continue
      }
      if escape == 'A' || escape == 'z' {
        if in_class {
          return None
        }
        out.write_string(if escape == 'A' { "(?-m:^)" } else { "(?-m:$)" })
        i = i + 2
        continue
      }
      if escape == 'Q' && !in_class {
        i = i + 2
        while i < chars.length() {
          if chars[i] == '\\' && i + 1 < chars.length() && chars[i + 1] == 'E' {
            i = i + 2
            break
          }
          if "\\.+*?()|[]{}^$".to_array().contains(chars[i]) {
            out.write_string("\\")
          }
          out.write_char(chars[i])
          i = i + 1
        }
        continue
      }
      if escape == 'x' {
        // A singleton class preserves the active inline/global case folding.
        if !in_class {
          out.write_string("[")
        }
        let mut j = i + 2
        if j < chars.length() && chars[j] == '{' {
          out.write_string("\\u{")
          j = j + 1
          let start = j
          while j < chars.length() && chars[j] != '}' {
            let h = chars[j]
            if !((h >= '0' && h <= '9') ||
              (h >= 'a' && h <= 'f') ||
              (h >= 'A' && h <= 'F')) {
              return None
            }
            out.write_char(h)
            j = j + 1
          }
          if j >= chars.length() || j == start || j - start > 6 {
            return None
          }
          out.write_string("}")
          i = j + 1
        } else {
          if j + 2 > chars.length() {
            return None
          }
          out.write_string("\\u00")
          for k in j..<(j + 2) {
            let h = chars[k]
            if !((h >= '0' && h <= '9') ||
              (h >= 'a' && h <= 'f') ||
              (h >= 'A' && h <= 'F')) {
              return None
            }
            out.write_char(h)
          }
          i = j + 2
        }
        if !in_class {
          out.write_string("]")
        }
        class_first = false
        continue
      }
      // Reject unknown ASCII-letter escapes instead of treating them literally.
      if ((escape >= 'a' && escape <= 'z') || (escape >= 'A' && escape <= 'Z')) &&
        !"dDwWpPtnrfvbB".to_array().contains(escape) {
        return None
      }
      out.write_string("\\")
      out.write_char(escape)
      i = i + 2
      class_first = false
      continue
    }
    if in_class {
      if c == '[' && i + 1 < chars.length() && chars[i + 1] == ':' {
        let mut j = i + 2
        let negative = j < chars.length() && chars[j] == '^'
        if negative {
          j = j + 1
        }
        let name = StringBuilder()
        while j < chars.length() && chars[j] != ':' && j - i < 20 {
          name.write_char(chars[j])
          j = j + 1
        }
        if j + 1 >= chars.length() || chars[j] != ':' || chars[j + 1] != ']' {
          return None
        }
        guard regex_ascii_ranges(name.to_string(), negative) is Some(ranges) else {
          return None
        }
        out.write_string(ranges)
        i = j + 2
        class_first = false
        continue
      }
      if c == ']' {
        if class_first {
          out.write_string("\\]")
          class_first = false
        } else {
          out.write_string("]")
          in_class = false
        }
      } else {
        out.write_char(c)
        if c != '^' || !class_first || !class_allow_caret {
          class_first = false
        }
        class_allow_caret = false
      }
      i = i + 1
      continue
    }
    if c == '[' {
      in_class = true
      class_first = true
      class_allow_caret = true
      out.write_string("[")
      i = i + 1
      continue
    }
    if c == '(' {
      if i + 1 < chars.length() && chars[i + 1] == '?' {
        let mut j = i + 2
        // RE2 accepts both Python-style and angle-bracket named captures.
        if j < chars.length() && chars[j] == 'P' {
          j = j + 1
        }
        if j < chars.length() && chars[j] == '<' {
          j = j + 1
          if j >= chars.length() || chars[j] == '=' || chars[j] == '!' {
            return None
          }
          out.write_string("(?<")
          while j < chars.length() && chars[j] != '>' {
            out.write_char(chars[j])
            j = j + 1
          }
          if j >= chars.length() {
            return None
          }
          out.write_string(">")
          scopes.push([])
          depth = depth + 1
          i = j + 1
        } else {
          j = i + 2
          let positive = StringBuilder()
          let negative = StringBuilder()
          let mut neg = false
          let mut saw_flag = false
          while j < chars.length() {
            match chars[j] {
              'i' | 'm' | 's' as flag => {
                if neg {
                  negative.write_char(flag)
                } else {
                  positive.write_char(flag)
                }
                saw_flag = true
                j = j + 1
              }
              'U' => {
                saw_flag = true
                j = j + 1
              } // Greediness does not affect Boolean membership.
              '-' if !neg => {
                neg = true
                j = j + 1
              }
              _ => break
            }
          }
          if j >= chars.length() ||
            (chars[j] != ')' && chars[j] != ':') ||
            (chars[j] == ')' && !saw_flag) {
            return None
          }
          let flags = positive.to_string() +
            (if negative.to_string() == "" {
              ""
            } else {
              "-" + negative.to_string()
            })
          let opening = "(?" + flags + ":"
          out.write_string(opening)
          if chars[j] == ')' {
            scopes[scopes.length() - 1].push(opening)
          } else {
            scopes.push([])
          }
          depth = depth + 1
          i = j + 1
        }
      } else {
        out.write_string("(")
        scopes.push([])
        depth = depth + 1
        i = i + 1
      }
      if depth > 64 {
        return None
      }
      continue
    }
    if c == ')' {
      if scopes.length() == 1 {
        return None
      }
      let synthetic = scopes[scopes.length() - 1]
      for _ in synthetic {
        out.write_string(")")
      }
      out.write_string(")")
      ignore(scopes.pop())
      depth = depth - synthetic.length() - 1
      i = i + 1
      continue
    }
    if c == '|' {
      let synthetic = scopes[scopes.length() - 1]
      for _ in synthetic {
        out.write_string(")")
      }
      out.write_string("|")
      for opening in synthetic {
        out.write_string(opening)
      }
    } else {
      out.write_char(c)
    }
    i = i + 1
  }
  if in_class || scopes.length() != 1 {
    return None
  }
  for _ in scopes[0] {
    out.write_string(")")
  }
  Some(out.to_string())
}

///|
// Bound recursive parsing and counted-repeat expansion before the library's
// UInt repeat parser/compiler can allocate an excessive instruction program.
fn regex_compilation_budget(pattern : String) -> Bool {
  let chars = pattern.to_array()
  let costs = [0]
  let atoms = [0]
  let mut in_class = false
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    let top = costs.length() - 1
    if c == '\\' {
      if i + 1 >= chars.length() {
        return false
      }
      let kind = chars[i + 1]
      i = i + 2
      if (kind == 'u' || kind == 'p' || kind == 'P') &&
        i < chars.length() &&
        chars[i] == '{' {
        while i < chars.length() && chars[i] != '}' {
          i = i + 1
        }
        if i >= chars.length() {
          return false
        }
        i = i + 1
      } else if kind == 'u' {
        i = i + 4
      }
      if !in_class {
        costs[top] = costs[top] + 1
        atoms[top] = 1
      }
    } else if in_class {
      if c == ']' {
        in_class = false
        costs[top] = costs[top] + 1
        atoms[top] = 1
      }
      i = i + 1
    } else if c == '[' {
      in_class = true
      i = i + 1
    } else if c == '(' {
      i = i + 1
      if i < chars.length() && chars[i] == '?' {
        while i < chars.length() && chars[i] != ':' && chars[i] != '>' {
          i = i + 1
        }
        if i >= chars.length() {
          return false
        }
        i = i + 1
      }
      costs.push(0)
      atoms.push(0)
      if costs.length() > 65 {
        return false
      }
    } else if c == ')' {
      if top == 0 {
        return false
      }
      let group_cost = costs[top] + 4
      ignore(costs.pop())
      ignore(atoms.pop())
      costs[top - 1] = costs[top - 1] + group_cost
      atoms[top - 1] = group_cost
      i = i + 1
    } else if c == '{' &&
      i + 1 < chars.length() &&
      chars[i + 1] >= '0' &&
      chars[i + 1] <= '9' {
      let mut j = i + 1
      let mut n = 0
      let mut max_repeat = 0
      while j < chars.length() && chars[j] != '}' {
        let d = chars[j]
        if d == ',' {
          max_repeat = n
          n = 0
        } else if d >= '0' && d <= '9' {
          n = n * 10 + d.to_int() - 48
          if n > 1000 {
            return false
          }
        } else {
          return false
        }
        j = j + 1
      }
      if j >= chars.length() {
        return false
      }
      if n > max_repeat {
        max_repeat = n
      }
      let expanded = atoms[top] * max_repeat + 4
      costs[top] = costs[top] - atoms[top] + expanded
      atoms[top] = expanded
      i = j + 1
    } else {
      match c {
        '*' | '+' | '?' => {
          costs[top] = costs[top] + 2
          atoms[top] = atoms[top] + 2
        }
        '|' => {
          costs[top] = costs[top] + 2
          atoms[top] = 0
        }
        _ => {
          costs[top] = costs[top] + 1
          atoms[top] = 1
        }
      }
      i = i + 1
    }
    if costs[costs.length() - 1] > 20000 {
      return false
    }
  }
  !in_class && costs.length() == 1
}

///|
fn compile_unleash_regex(
  pattern : String,
  insensitive : Bool,
) -> @regexp.Regexp? {
  guard regex_rewrite(pattern) is Some(pattern) &&
    regex_compilation_budget(pattern) else {
    return None
  }
  Some(@regexp.compile(pattern[:], flags=if insensitive { "i" } else { "" })) catch {
    _ => None
  }
}

///|
fn regex_key(c : @json.Json) -> String {
  (if boolean(field(c, "caseInsensitive")) { "i:" } else { "0:" }) +
  str(c, "value")
}

///|
fn register_regex(cache : Map[String, @regexp.Regexp?], c : @json.Json) -> Unit {
  if str(c, "operator") != "REGEX" || cache.length() >= 100 {
    return
  }
  let key = regex_key(c)
  if !cache.contains(key) {
    cache[key] = compile_unleash_regex(
      str(c, "value"),
      boolean(field(c, "caseInsensitive")),
    )
  }
}

///|
fn Snapshot::matches_regex(
  self : Snapshot,
  c : @json.Json,
  actual : String?,
) -> Bool {
  guard actual is Some(actual) else { return false }
  let compiled = match self.regexes.get(regex_key(c)) {
    Some(compiled) => compiled
    None =>
      compile_unleash_regex(
        str(c, "value"),
        boolean(field(c, "caseInsensitive")),
      )
  }
  match compiled {
    Some(regex) => regex.execute(actual[:]).matched()
    None => false
  }
}
