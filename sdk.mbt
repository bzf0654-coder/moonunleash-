// SPDX-License-Identifier: Apache-2.0
// Adapted in MoonBit from Unleash Node SDK 6.12.2; Copyright 2020 Bricks Software AS.
// Modified: bounded/private snapshots, supported constraints, context defaults,
// and first-match strategy propagation. See THIRD_PARTY.md and NOTICE.

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
  priv regexes : Map[String, @regexp.Regexp?]
  priv cursor : Int64?
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
    "IN"
    | "NOT_IN"
    | "STR_ENDS_WITH"
    | "STR_STARTS_WITH"
    | "STR_CONTAINS"
    | "IN_CIDR" =>
      for v in optional_array(c, "values") {
        guard v is String(_) else {
          raise Invalid("constraint.values: expected strings")
        }
      }
    "NUM_EQ"
    | "NUM_GT"
    | "NUM_GTE"
    | "NUM_LT"
    | "NUM_LTE"
    | "SEMVER_EQ"
    | "SEMVER_GT"
    | "SEMVER_GTE"
    | "SEMVER_LT"
    | "SEMVER_LTE"
    | "DATE_BEFORE"
    | "DATE_AFTER"
    | "REGEX" => {
      guard field(c, "value") is String(_) else {
        raise Invalid("constraint.value: expected string")
      }
    }
    _ => {
      // Unknown operators are well-formed but unsatisfied, even if inverted.
      // This is distinct from malformed data, which still rejects installation.
      for value in optional_array(c, "values") {
        guard value is String(_) else {
          raise Invalid("constraint.values: expected strings")
        }
      }
      match field(c, "value") {
        Null | String(_) => ()
        _ => raise Invalid("constraint.value: expected string")
      }
    }
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
  let root = parse_configuration(source)
  match field(root, "version") {
    Number(v, ..) if v == 1 || v == 2 => ()
    _ => raise Unsupported("state.version must be 1 or 2")
  }
  let features : Map[String, @json.Json] = Map([])
  let segments : Map[String, Array[@json.Json]] = Map([])
  let regexes : Map[String, @regexp.Regexp?] = Map([])
  for segment in optional_array(root, "segments") {
    let (id, cs) = validate_segment_definition(segment)
    if segments.contains(id) {
      raise Invalid("duplicate segment: \{id}")
    }
    for c in cs {
      register_regex(regexes, c)
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
    let name = validate_feature_definition(feature)
    if features.contains(name) {
      raise Invalid("duplicate flag: \{name}")
    }
    for strategy in items(field(feature, "strategies")) {
      for constraint in items(field(strategy, "constraints")) {
        register_regex(regexes, constraint)
      }
    }
    features[name] = feature
  }
  { features, segments, regexes, cursor: None, }
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
/// Return a fresh context with client defaults. Explicit keys, including null
/// and empty strings, override defaults; nested properties are not promoted.
pub fn Context::with_defaults(
  self : Context,
  app_name : String,
  environment~ : String = "default",
) -> Context {
  let merged : Map[String, @json.Json] = Map([
    ("appName", @json.Json::string(app_name)),
    ("environment", @json.Json::string(environment)),
  ])
  guard self.data is Object(fields) else { abort("invalid internal context") }
  for key, value in fields {
    merged[key] = value
  }
  { data: @json.Json::object(merged), }
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
fn Snapshot::matches_constraint(
  self : Snapshot,
  c : @json.Json,
  ctx : Context,
) -> Bool {
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
    "REGEX" => self.matches_regex(c, actual)
    "IN_CIDR" =>
      match actual {
        Some(ip) => values.any(fn(range) { ip_in_range(ip, range) })
        None => false
      }
    "SEMVER_EQ" | "SEMVER_GT" | "SEMVER_GTE" | "SEMVER_LT" | "SEMVER_LTE" =>
      matches_semver(op, actual, str(c, "value"))
    "DATE_BEFORE" | "DATE_AFTER" => matches_date(op, ctx, str(c, "value"))
    "NUM_EQ" | "NUM_GT" | "NUM_GTE" | "NUM_LT" | "NUM_LTE" =>
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
    _ => return false
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
    if !self.matches_constraint(c, ctx) {
      return false
    }
  }
  for id in items(field(strategy, "segments")) {
    let key = match id {
      Number(n, ..) => n.to_int().to_string()
      _ => ""
    }
    guard self.segments.get(key) is Some(cs) else { return false }
    if !cs.all(fn(c) { self.matches_constraint(c, ctx) }) {
      return false
    }
  }
  let p = field(strategy, "parameters")
  match str(strategy, "name") {
    "default" => true
    "remoteAddress" =>
      matches_remote_address(str(p, "IPs"), ctx.get("remoteAddress"))
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
/// Evaluation performs no network/disk I/O. Inject randomness and currentTime
/// in the context for reproducibility; absent date context reads the local clock.
pub fn Snapshot::evaluate(
  self : Snapshot,
  name : String,
  ctx : Context,
  fallback~ : Bool = false,
  random? : () -> Double,
) -> Decision {
  let random = random.unwrap_or(fn() { @random.Rand::chacha8().double() })
  let (decision, _) = self.evaluate_with_strategy(name, ctx, fallback, random)
  decision
}

///|
// Carry the first matching strategy into variant selection without re-evaluation.
fn Snapshot::evaluate_with_strategy(
  self : Snapshot,
  name : String,
  ctx : Context,
  fallback : Bool,
  random : () -> Double,
) -> (Decision, @json.Json?) {
  guard self.features.get(name) is Some(feature) else {
    return ({ enabled: fallback, reason: "not_found", }, None)
  }
  if !boolean(field(feature, "enabled")) {
    return ({ enabled: false, reason: "disabled", }, None)
  }
  if !self.dependencies_satisfied(feature, ctx, random) {
    return ({ enabled: false, reason: "dependency_not_satisfied", }, None)
  }
  let strategies = items(field(feature, "strategies"))
  if strategies.is_empty() {
    return ({ enabled: true, reason: "no_strategies", }, None)
  }
  for strategy in strategies {
    if self.strategy_matches(strategy, ctx, random) {
      return ({ enabled: true, reason: "strategy_match", }, Some(strategy))
    }
  }
  ({ enabled: false, reason: "no_match", }, None)
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
