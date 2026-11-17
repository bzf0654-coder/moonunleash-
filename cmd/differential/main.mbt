///|
/// Only file I/O is delegated to the JS host; all flag decisions use MoonBit.
extern "js" fn read_input(path : String) -> String =
  #| (path) => require('node:fs').readFileSync(path, 'utf8')

///|
fn field(value : @json.Json, key : String) -> @json.Json {
  match value {
    Object(obj) => obj.get(key).unwrap_or(@json.null)
    _ => @json.null
  }
}

///|
fn text(value : @json.Json) -> String raise {
  guard value is String(s) else { fail("invalid differential corpus string") }
  s
}

///|
fn main raise {
  guard @env.get_env_var("MOONUNLEASH_DIFF_INPUT") is Some(path) else {
    fail("run via node tools/differential.mjs")
  }
  let input = @json.parse(read_input(path), reject_duplicate_keys=true)
  guard field(input, "groups") is Array(groups) else { fail("missing groups") }
  let results : Array[@json.Json] = []
  for group in groups {
    let state = @sdk.Snapshot::parse(field(group, "state").stringify())
    guard field(group, "cases") is Array(cases) else { fail("missing cases") }
    for c in cases {
      let name = text(field(c, "name"))
      let raw_context = @sdk.Context::parse(field(c, "context").stringify())
      let defaults = field(c, "defaults")
      let context = if defaults is Object(_) {
        raw_context.with_defaults(
          text(field(defaults, "appName")),
          environment=text(field(defaults, "environment")),
        )
      } else {
        raw_context
      }
      let actual = if text(field(c, "kind")) == "variant" {
        state.get_variant(name, context).to_json()
      } else {
        @json.Json::boolean(state.evaluate(name, context).enabled)
      }
      results.push(
        @json.Json::object(Map([("id", field(c, "id")), ("actual", actual)])),
      )
    }
  }
  println(
    @json.Json::object(
      Map([
        ("backend", @json.Json::string("js")),
        ("results", @json.Json::array(results)),
      ]),
    ).stringify(),
  )
}
