///|
/// Invalid input and unsupported semantics are distinct, observable failures.
#derive(@debug.Debug)
pub(all) suberror ConfigError {
  Invalid(String)
  Unsupported(String)
}

///|
/// A diagnostic safe to display without serializing the original configuration.
pub fn ConfigError::message(self : ConfigError) -> String {
  match self {
    Invalid(detail) => "invalid configuration: \{detail}"
    Unsupported(detail) => "unsupported configuration: \{detail}"
  }
}

///|
pub extend ConfigError with @debug.Debug::{to_repr}

///|
pub extend Decision with @debug.Debug::{to_repr}

///|
pub extend Decision with Eq::{equal, not_equal}

///|
/// Private owned JSON: callers cannot mutate installed configuration.
pub struct Snapshot {
  priv features : Map[String, @json.Json]
  priv segments : Map[String, Array[@json.Json]]
}

///|
pub struct Context {
  priv data : @json.Json
}

///|
#derive(Eq, @debug.Debug)
pub(all) struct Decision {
  enabled : Bool
  reason : String
}

///|
fn field(value : @json.Json, key : String) -> @json.Json {
  match value {
    Object(obj) => obj.get(key).unwrap_or(@json.null)
    _ => @json.null
  }
}

///|
fn text(value : @json.Json) -> String? {
  match value {
    String(s) => Some(s)
    _ => None
  }
}

///|
fn str(value : @json.Json, key : String, default~ : String = "") -> String {
  text(field(value, key)).unwrap_or(default)
}

///|
fn items(value : @json.Json) -> Array[@json.Json] {
  match value {
    Array(xs) => xs
    _ => []
  }
}

///|
fn boolean(value : @json.Json) -> Bool {
  match value {
    True => true
    _ => false
  }
}

///|
fn numeric(value : String) -> Double? {
  try {
    let n = @string.parse_double(value.trim())
    if n.is_nan() || n.is_inf() {
      None
    } else {
      Some(n)
    }
  } catch {
    _ => None
  }
}

///|
fn require_object(value : @json.Json, path : String) -> Unit raise ConfigError {
  guard value is Object(_) else { raise Invalid("\{path}: expected object") }
}

///|
fn optional_array(
  value : @json.Json,
  key : String,
) -> Array[@json.Json] raise ConfigError {
  match field(value, key) {
    Null => []
    Array(xs) => xs
    _ => raise Invalid("\{key}: expected array")
  }
}

///|
fn required_text(value : @json.Json, key : String) -> String raise ConfigError {
  match text(field(value, key)) {
    Some(s) if s != "" => s
    _ => raise Invalid("\{key}: expected nonempty string")
  }
}

///|
fn validate_constraint(c : @json.Json) -> Unit raise ConfigError {
  require_object(c, "constraint")
  ignore(required_text(c, "contextName"))
  let op = required_text(c, "operator")
  match op {
    "IN" | "NOT_IN" | "STR_ENDS_WITH" | "STR_STARTS_WITH" | "STR_CONTAINS" =>
      for v in optional_array(c, "values") {
        guard v is String(_) else {
          raise Invalid("constraint.values: expected strings")
        }
      }
    "NUM_EQ" | "NUM_GT" | "NUM_GTE" | "NUM_LT" | "NUM_LTE" => {
      guard field(c, "value") is String(_) else {
        raise Invalid("constraint.value: expected string")
      }
    }
    _ => raise Unsupported("constraint operator: \{op}")
  }
  for key in ["inverted", "caseInsensitive"] {
    match field(c, key) {
      Null | True | False => ()
      _ => raise Invalid("\{key}: expected boolean")
    }
  }
}

///|
/// Parses a supported full-state response. Nothing is published on failure.
pub fn Snapshot::parse(source : String) -> Snapshot raise {
  if source.length() > 8 * 1024 * 1024 ||
    @utf8.encode(source).length() > 8 * 1024 * 1024 {
    raise Invalid("response exceeds 8 MiB UTF-8 budget")
  }
  let root = @json.parse(
    source,
    max_nesting_depth=64,
    reject_duplicate_keys=true,
  )
  require_object(root, "state")
  match field(root, "version") {
    Number(v, ..) if v == 1 || v == 2 => ()
    _ => raise Unsupported("state.version must be 1 or 2")
  }
  let features : Map[String, @json.Json] = Map([])
  let segments : Map[String, Array[@json.Json]] = Map([])
  for segment in optional_array(root, "segments") {
    require_object(segment, "segment")
    let id = match field(segment, "id") {
      Number(n, ..) if n >= 0 && n == n.to_int().to_double() =>
        n.to_int().to_string()
      _ => raise Invalid("segment.id: expected nonnegative integer")
    }
    if segments.contains(id) {
      raise Invalid("duplicate segment: \{id}")
    }
    let cs = optional_array(segment, "constraints")
    for c in cs {
      validate_constraint(c)
    }
    segments[id] = cs
  }
  guard field(root, "features") is Array(fs) else {
    raise Invalid("features: expected array")
  }
  if fs.length() > 10000 || segments.length() > 10000 {
    raise Invalid("configuration count budget exceeded")
  }
  for feature in fs {
    require_object(feature, "feature")
    let name = required_text(feature, "name")
    if features.contains(name) {
      raise Invalid("duplicate flag: \{name}")
    }
    guard field(feature, "enabled") is (True | False) else {
      raise Invalid("\{name}.enabled: expected boolean")
    }
    if optional_array(feature, "dependencies").length() > 0 {
      raise Unsupported("\{name}.dependencies")
    }
    validate_variants(optional_array(feature, "variants"))
    for strategy in optional_array(feature, "strategies") {
      require_object(strategy, "strategy")
      let kind = required_text(strategy, "name")
      match kind {
        "default"
        | "userWithId"
        | "flexibleRollout"
        | "gradualRolloutUserId"
        | "gradualRolloutSessionId"
        | "gradualRolloutRandom" => ()
        _ => raise Unsupported("strategy: \{kind}")
      }
      match field(strategy, "parameters") {
        Null => ()
        Object(params) =>
          for _, v in params {
            guard v is String(_) else {
              raise Invalid("strategy parameters: expected strings")
            }
          }
        _ => raise Invalid("strategy.parameters: expected object")
      }
      if optional_array(strategy, "variants").length() > 0 {
        raise Unsupported("strategy variants")
      }
      let cs = optional_array(strategy, "constraints")
      if cs.length() > 100 {
        raise Invalid("too many strategy constraints")
      }
      for c in cs {
        validate_constraint(c)
      }
      for id in optional_array(strategy, "segments") {
        guard id is Number(n, ..) && n >= 0 && n == n.to_int().to_double() else {
          raise Invalid("strategy.segments: expected integer ids")
        }
      }
    }
    features[name] = feature
  }
  { features, segments, }
}

///|
pub fn Context::parse(source : String) -> Context raise {
  let data = @json.parse(
    source,
    max_nesting_depth=32,
    reject_duplicate_keys=true,
  )
  require_object(data, "context")
  match field(data, "properties") {
    Null | Object(_) => ()
    _ => raise Invalid("context.properties: expected object")
  }
  { data, }
}

///|
pub fn Context::new(user_id? : String) -> Context {
  let values : Map[String, @json.Json] = Map([])
  if user_id is Some(id) {
    values["userId"] = @json.Json::string(id)
  }
  { data: @json.Json::object(values), }
}

///|
fn Context::get(self : Context, name : String) -> String? {
  // Reserved fields cannot be overridden through properties.
  match name {
    "userId"
    | "sessionId"
    | "remoteAddress"
    | "appName"
    | "environment"
    | "currentTime" => text(field(self.data, name))
    _ => text(field(field(self.data, "properties"), name))
  }
}

///|
fn matches_constraint(c : @json.Json, ctx : Context) -> Bool {
  let op = str(c, "operator")
  let actual = ctx.get(str(c, "contextName"))
  let insensitive = boolean(field(c, "caseInsensitive"))
  let values = items(field(c, "values"))
    .filter_map(text)
    .map(fn(s) { s.trim().to_owned() })
    .filter(fn(s) { s != "" })
  let result = match op {
    "IN" | "NOT_IN" => {
      let found = match actual {
        Some(a) => values.contains(a)
        None => false
      }
      if op == "IN" {
        found
      } else {
        !found
      }
    }
    "STR_ENDS_WITH" | "STR_STARTS_WITH" | "STR_CONTAINS" =>
      match actual {
        None => false
        Some(raw) => {
          let a = if insensitive { raw.to_lower() } else { raw }
          values.any(fn(raw_value) {
            let v = if insensitive { raw_value.to_lower() } else { raw_value }
            match op {
              "STR_ENDS_WITH" => a.has_suffix(v)
              "STR_STARTS_WITH" => a.has_prefix(v)
              _ => a.contains(v)
            }
          })
        }
      }
    _ =>
      match (actual.bind(numeric), numeric(str(c, "value"))) {
        (Some(a), Some(b)) =>
          match op {
            "NUM_EQ" => a == b
            "NUM_GT" => a > b
            "NUM_GTE" => a >= b
            "NUM_LT" => a < b
            "NUM_LTE" => a <= b
            _ => false
          }
        _ => false
      }
  }
  if boolean(field(c, "inverted")) {
    !result
  } else {
    result
  }
}

///|
fn Snapshot::strategy_matches(
  self : Snapshot,
  strategy : @json.Json,
  ctx : Context,
  random : () -> Double,
) -> Bool {
  for c in items(field(strategy, "constraints")) {
    if !matches_constraint(c, ctx) {
      return false
    }
  }
  for id in items(field(strategy, "segments")) {
    let key = match id {
      Number(n, ..) => n.to_int().to_string()
      _ => ""
    }
    guard self.segments.get(key) is Some(cs) else { return false }
    if !cs.all(fn(c) { matches_constraint(c, ctx) }) {
      return false
    }
  }
  let p = field(strategy, "parameters")
  match str(strategy, "name") {
    "default" => true
    "userWithId" =>
      match ctx.get("userId") {
        None => false
        Some(id) => str(p, "userIds").split(",").any(fn(s) { s.trim() == id })
      }
    kind => {
      let percentage = numeric(
        str(p, if kind == "flexibleRollout" { "rollout" } else { "percentage" }),
      ).unwrap_or(0)
      if percentage <= 0 {
        return false
      }
      let stickiness = match kind {
        "gradualRolloutUserId" => "userId"
        "gradualRolloutSessionId" => "sessionId"
        "gradualRolloutRandom" => "random"
        _ => str(p, "stickiness", default="default")
      }
      let id = match stickiness {
        "default" =>
          match ctx.get("userId") {
            Some(id) if id != "" => Some(id)
            _ => ctx.get("sessionId").filter(fn(s) { s != "" })
          }
        "random" => None
        other => ctx.get(other).filter(fn(s) { s != "" })
      }
      match id {
        Some(id) =>
          bucket(id, str(p, "groupId"), 100, 0U).to_double() <= percentage
        None if stickiness == "random" || stickiness == "default" => {
          let r = random()
          r >= 0 && r < 1 && (r * 100).to_int().to_double() + 1 <= percentage
        }
        _ => false
      }
    }
  }
}

///|
/// Evaluation performs no I/O. Inject a random source for reproducible tests.
pub fn Snapshot::evaluate(
  self : Snapshot,
  name : String,
  ctx : Context,
  fallback~ : Bool = false,
  random? : () -> Double,
) -> Decision {
  guard self.features.get(name) is Some(feature) else {
    return { enabled: fallback, reason: "not_found", }
  }
  if !boolean(field(feature, "enabled")) {
    return { enabled: false, reason: "disabled", }
  }
  let strategies = items(field(feature, "strategies"))
  if strategies.is_empty() {
    return { enabled: true, reason: "no_strategies", }
  }
  let random = random.unwrap_or(fn() { @random.Rand::chacha8().double() })
  let enabled = strategies.any(fn(s) { self.strategy_matches(s, ctx, random) })
  { enabled, reason: if enabled { "strategy_match" } else { "no_match" }, }
}

///|
pub fn Snapshot::is_enabled(
  self : Snapshot,
  name : String,
  ctx : Context,
  fallback~ : Bool = false,
) -> Bool {
  self.evaluate(name, ctx, fallback~).enabled
}

///|
pub fn Snapshot::size(self : Snapshot) -> Int32 {
  self.features.length()
}
