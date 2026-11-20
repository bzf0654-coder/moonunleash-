///|
fn field(value : @json.Json, key : String) -> @json.Json {
  match value {
    Object(obj) => obj.get(key).unwrap_or(@json.null)
    _ => @json.null
  }
}

///|
fn number(n : Int32) -> @json.Json {
  @json.Json::number(n.to_double())
}

///|
fn str(s : String) -> @json.Json {
  @json.Json::string(s)
}

///|
fn text(value : @json.Json) -> String raise {
  guard value is String(s) else { fail("expected string in official fixture") }
  s
}

///|
fn main raise {
  let all_cases : Array[@json.Json] = []
  let suites : Array[@json.Json] = []
  let mut passed = 0
  let mut failed = 0
  let mut not_run = 0
  let mut required_suites = 0
  for fixture in @specdata.suites() {
    let spec = @json.parse(fixture.source)
    let snapshot : Result[@sdk.Snapshot, String] = if fixture.required {
      required_suites = required_suites + 1
      let state = field(spec, "state")
      Ok(
        if field(state, "events") is Array(_) {
          @sdk.Snapshot::from_delta(state.stringify())
        } else {
          @sdk.Snapshot::parse(state.stringify())
        },
      ) catch {
        @sdk.ConfigError::Invalid(detail) => Err("invalid: " + detail)
        @sdk.ConfigError::Unsupported(detail) => Err("unsupported: " + detail)
        _ => Err("snapshot_parse_error")
      }
    } else {
      Err("out_of_declared_scope")
    }
    let mut suite_passed = 0
    let mut suite_failed = 0
    let mut suite_not_run = 0
    // Unknown groups are included in inventory, never silently counted as pass.
    guard spec is Object(obj) else { fail("spec root must be object") }
    for kind, values in obj {
      if !kind.to_lower().has_suffix("tests") {
        continue
      }
      guard values is Array(cases) else { fail("case group must be array") }
      for i = 0; i < cases.length(); i = i + 1 {
        let c = cases[i]
        let expected = field(c, "expectedResult")
        let supported_group = kind == "tests" || kind == "variantTests"
        let result : Result[@json.Json, String] = if !fixture.required ||
          !supported_group {
          Err("not_run")
        } else {
          match snapshot {
            Err(reason) => Err(reason)
            Ok(state) =>
              try {
                let name = text(field(c, "toggleName"))
                let ctx = @sdk.Context::parse(field(c, "context").stringify())
                Ok(
                  if kind == "variantTests" {
                    state.get_variant(name, ctx).to_json()
                  } else {
                    @json.Json::boolean(state.evaluate(name, ctx).enabled)
                  },
                )
              } catch {
                _ => Err("case_evaluation_error")
              }
          }
        }
        let (status, actual, reason) = if !fixture.required {
          not_run = not_run + 1
          suite_not_run = suite_not_run + 1
          ("NotRun", @json.null, "out_of_declared_scope")
        } else {
          match result {
            Ok(actual) if actual == expected => {
              passed = passed + 1
              suite_passed = suite_passed + 1
              ("Pass", actual, "")
            }
            Ok(actual) => {
              failed = failed + 1
              suite_failed = suite_failed + 1
              ("Fail", actual, "result_mismatch")
            }
            Err(reason) => {
              failed = failed + 1
              suite_failed = suite_failed + 1
              ("Fail", @json.null, reason)
            }
          }
        }
        all_cases.push(
          @json.Json::object(
            Map([
              ("file", str(fixture.file)),
              ("kind", str(kind)),
              ("index", number(i)),
              ("description", field(c, "description")),
              ("required", @json.Json::boolean(fixture.required)),
              ("status", str(status)),
              ("expected", expected),
              ("actual", actual),
              ("reason", str(reason)),
            ]),
          ),
        )
      }
    }
    suites.push(
      @json.Json::object(
        Map([
          ("file", str(fixture.file)),
          ("required", @json.Json::boolean(fixture.required)),
          ("passed", number(suite_passed)),
          ("failed", number(suite_failed)),
          ("notRun", number(suite_not_run)),
        ]),
      ),
    )
  }
  println(
    @json.Json::object(
      Map([
        ("schemaVersion", number(1)),
        ("revision", str(@specdata.revision())),
        ("backend", str(backend)),
        (
          "summary",
          @json.Json::object(
            Map([
              ("suites", number(suites.length())),
              ("requiredSuites", number(required_suites)),
              ("passed", number(passed)),
              ("failed", number(failed)),
              ("notRun", number(not_run)),
            ]),
          ),
        ),
        ("suites", @json.Json::array(suites)),
        ("cases", @json.Json::array(all_cases)),
      ]),
    ).stringify(indent=2),
  )
  if failed > 0 {
    @env.exit(1)
  }
}
