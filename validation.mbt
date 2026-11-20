// SPDX-License-Identifier: Apache-2.0
// Shared structural validation for full responses and atomic delta events.

///|
fn parse_configuration(source : String) -> @json.Json raise {
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
  root
}

///|
fn validate_segment_definition(
  segment : @json.Json,
) -> (String, Array[@json.Json]) raise ConfigError {
  require_object(segment, "segment")
  let id = match field(segment, "id") {
    Number(n, ..) if n >= 0 && n == n.to_int().to_double() =>
      n.to_int().to_string()
    _ => raise Invalid("segment.id: expected nonnegative integer")
  }
  let constraints = optional_array(segment, "constraints")
  for constraint in constraints {
    validate_constraint(constraint)
  }
  (id, constraints)
}

///|
fn validate_feature_definition(
  feature : @json.Json,
) -> String raise ConfigError {
  require_object(feature, "feature")
  let name = required_text(feature, "name")
  guard field(feature, "enabled") is (True | False) else {
    raise Invalid("\{name}.enabled: expected boolean")
  }
  validate_dependencies(feature)
  validate_variants(optional_array(feature, "variants"))
  for strategy in optional_array(feature, "strategies") {
    require_object(strategy, "strategy")
    let kind = required_text(strategy, "name")
    match kind {
      "default"
      | "userWithId"
      | "remoteAddress"
      | "flexibleRollout"
      | "gradualRolloutUserId"
      | "gradualRolloutSessionId"
      | "gradualRolloutRandom" => ()
      _ => raise Unsupported("strategy: \{kind}")
    }
    match field(strategy, "parameters") {
      Null => ()
      Object(params) =>
        for _, value in params {
          guard value is String(_) else {
            raise Invalid("strategy parameters: expected strings")
          }
        }
      _ => raise Invalid("strategy.parameters: expected object")
    }
    let variants = optional_array(strategy, "variants")
    validate_variants(variants)
    for variant in variants {
      match field(variant, "weightType") {
        Null | String("fix") | String("variable") => ()
        _ => raise Invalid("variant.weightType: expected fix or variable")
      }
    }
    let constraints = optional_array(strategy, "constraints")
    if constraints.length() > 100 {
      raise Invalid("too many strategy constraints")
    }
    for constraint in constraints {
      validate_constraint(constraint)
    }
    for id in optional_array(strategy, "segments") {
      guard id is Number(n, ..) && n >= 0 && n == n.to_int().to_double() else {
        raise Invalid("strategy.segments: expected integer ids")
      }
    }
  }
  name
}
