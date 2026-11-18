// SPDX-License-Identifier: Apache-2.0
// Adapted in MoonBit from Unleash Node SDK 6.12.2; Copyright 2020 Bricks Software AS.
// Modified: strict validation, single evaluation, strategy precedence, legacy
// fallback, and documented UTF-8 bucketing. See THIRD_PARTY.md and NOTICE.

///|
/// Variant payloads remain text: JSON payloads are not executed or reinterpreted.
pub(all) struct Payload {
  kind : String
  value : String
}

///|
pub(all) struct Variant {
  name : String
  enabled : Bool
  feature_enabled : Bool
  payload : Payload?
}

///|
pub fn Variant::to_json(self : Variant) -> @json.Json {
  let values : Map[String, @json.Json] = Map([
    ("name", @json.Json::string(self.name)),
    ("enabled", @json.Json::boolean(self.enabled)),
    ("feature_enabled", @json.Json::boolean(self.feature_enabled)),
  ])
  if self.payload is Some(p) {
    values["payload"] = @json.Json::object(
      Map([
        ("type", @json.Json::string(p.kind)),
        ("value", @json.Json::string(p.value)),
      ]),
    )
  }
  @json.Json::object(values)
}

///|
fn validate_variants(variants : Array[@json.Json]) -> Unit raise ConfigError {
  let names : Map[String, Bool] = Map([])
  let mut total = 0
  if variants.length() > 1000 {
    raise Invalid("too many variants")
  }
  for v in variants {
    require_object(v, "variant")
    let name = required_text(v, "name")
    if names.contains(name) {
      raise Invalid("duplicate variant: \{name}")
    }
    names[name] = true
    match field(v, "weight") {
      Number(w, ..) if w >= 0 && w <= 1000000 && w == w.to_int().to_double() =>
        total = total + w.to_int()
      _ => raise Invalid("variant.weight: expected nonnegative bounded integer")
    }
    if total > 1000000 {
      raise Invalid("variant total weight budget exceeded")
    }
    match field(v, "stickiness") {
      Null | String(_) => ()
      _ => raise Invalid("variant.stickiness: expected string")
    }
    match field(v, "payload") {
      Null => ()
      Object(_) => {
        ignore(required_text(field(v, "payload"), "type"))
        guard field(field(v, "payload"), "value") is String(_) else {
          raise Invalid("payload.value: expected string")
        }
      }
      _ => raise Invalid("variant.payload: expected object")
    }
    for o in optional_array(v, "overrides") {
      require_object(o, "variant override")
      ignore(required_text(o, "contextName"))
      for value in optional_array(o, "values") {
        guard value is String(_) else {
          raise Invalid("override.values: expected strings")
        }
      }
    }
  }
}

///|
fn variant_from_definition(v : @json.Json) -> Variant {
  let payload = match field(v, "payload") {
    Object(_) =>
      Some(Payload::{
        kind: str(field(v, "payload"), "type"),
        value: str(field(v, "payload"), "value"),
      })
    _ => None
  }
  { name: str(v, "name"), enabled: true, feature_enabled: true, payload, }
}

///|
/// Evaluates once; first-match strategy variants take precedence over legacy ones.
pub fn Snapshot::get_variant(
  self : Snapshot,
  name : String,
  ctx : Context,
  random? : () -> Double,
) -> Variant {
  let random = random.unwrap_or(fn() { @random.Rand::chacha8().double() })
  let (decision, strategy) = self.evaluate_with_strategy(
    name, ctx, false, random,
  )
  let enabled = decision.enabled
  let disabled = Variant::{
    name: "disabled",
    enabled: false,
    feature_enabled: enabled,
    payload: None,
  }
  if !enabled {
    return disabled
  }
  guard self.features.get(name) is Some(feature) else { return disabled }
  if strategy is Some(strategy) {
    let variants = items(field(strategy, "variants"))
    if !variants.is_empty() {
      let p = field(strategy, "parameters")
      let stickiness = match text(field(variants[0], "stickiness")) {
        Some(value) if value != "" => value
        _ => str(p, "stickiness", default="default")
      }
      if select_variant_definition(
          variants,
          ctx,
          random,
          str(p, "groupId", default="undefined"),
          stickiness,
        )
        is Some(v) {
        return variant_from_definition(v)
      }
    }
  }
  let variants = items(field(feature, "variants"))
  let stickiness = if variants.is_empty() {
    "default"
  } else {
    str(variants[0], "stickiness", default="default")
  }
  match select_variant_definition(variants, ctx, random, name, stickiness) {
    Some(v) => variant_from_definition(v)
    None => disabled
  }
}

///|
// Common selection primitive: strategy groupId and legacy feature name differ.
fn select_variant_definition(
  variants : Array[@json.Json],
  ctx : Context,
  random : () -> Double,
  group_id : String,
  stickiness : String,
) -> @json.Json? {
  let mut total = 0
  for v in variants {
    match field(v, "weight") {
      Number(w, ..) => total = total + w.to_int()
      _ => ()
    }
  }
  if total <= 0 {
    return None
  }
  for v in variants {
    for o in items(field(v, "overrides")) {
      if ctx.get(str(o, "contextName")) is Some(actual) {
        if items(field(o, "values")).any(fn(j) { text(j) == Some(actual) }) {
          return Some(v)
        }
      }
    }
  }
  let mut id : String? = None
  if stickiness == "default" {
    for key in ["userId", "sessionId", "remoteAddress"] {
      if ctx.get(key) is Some(value) && value != "" {
        id = Some(value)
        break
      }
    }
  } else {
    id = ctx.get(stickiness).filter(fn(s) { s != "" })
  }
  let id = match id {
    Some(value) => value
    None => {
      let r = random()
      if r < 0 || r >= 1 || r.is_nan() {
        return None
      }
      (r * 100000 + 0.5).to_int().to_string()
    }
  }
  let target = bucket(id, group_id, total, 86028157U)
  let mut cumulative = 0
  for v in variants {
    let weight = match field(v, "weight") {
      Number(w, ..) => w.to_int()
      _ => 0
    }
    cumulative = cumulative + weight
    if weight > 0 && cumulative >= target {
      return Some(v)
    }
  }
  None
}
