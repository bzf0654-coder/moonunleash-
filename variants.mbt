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
/// Evaluates the flag once, then selects its global variant with the variant seed.
pub fn Snapshot::get_variant(
  self : Snapshot,
  name : String,
  ctx : Context,
  random? : () -> Double,
) -> Variant {
  let random = random.unwrap_or(fn() { @random.Rand::chacha8().double() })
  let enabled = self.evaluate(name, ctx, random~).enabled
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
  let variants = items(field(feature, "variants"))
  let mut total = 0
  for v in variants {
    match field(v, "weight") {
      Number(w, ..) => total = total + w.to_int()
      _ => ()
    }
  }
  if total <= 0 {
    return disabled
  }
  for v in variants {
    for o in items(field(v, "overrides")) {
      if ctx.get(str(o, "contextName")) is Some(actual) {
        if items(field(o, "values")).any(fn(j) { text(j) == Some(actual) }) {
          return variant_from_definition(v)
        }
      }
    }
  }
  let stickiness = str(variants[0], "stickiness", default="default")
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
        return disabled
      }
      (r * 100000 + 0.5).to_int().to_string()
    }
  }
  let target = bucket(id, name, total, 86028157U)
  let mut cumulative = 0
  for v in variants {
    let weight = match field(v, "weight") {
      Number(w, ..) => w.to_int()
      _ => 0
    }
    cumulative = cumulative + weight
    if weight > 0 && cumulative >= target {
      return variant_from_definition(v)
    }
  }
  disabled
}
