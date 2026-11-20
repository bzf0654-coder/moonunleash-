// SPDX-License-Identifier: Apache-2.0
// Adapted from Unleash Node SDK 6.12.2; Copyright 2020 Bricks Software AS.
// Modified: bounded validation, snapshot-owned lookups and injected randomness.
// Dependencies have one supported parent level; a parent with dependencies is
// unsatisfied, not recursively traversed. This also terminates cycles safely.

///|
fn validate_dependencies(feature : @json.Json) -> Unit raise ConfigError {
  let dependencies = optional_array(feature, "dependencies")
  if dependencies.length() > 100 {
    raise Invalid("too many feature dependencies")
  }
  for dependency in dependencies {
    require_object(dependency, "dependency")
    ignore(required_text(dependency, "feature"))
    match field(dependency, "enabled") {
      Null | True | False => ()
      _ => raise Invalid("dependency.enabled: expected boolean")
    }
    let variants = optional_array(dependency, "variants")
    if variants.length() > 1000 {
      raise Invalid("too many dependency variants")
    }
    for variant in variants {
      guard variant is String(_) else {
        raise Invalid("dependency.variants: expected strings")
      }
    }
  }
}

///|
fn Snapshot::dependencies_satisfied(
  self : Snapshot,
  feature : @json.Json,
  ctx : Context,
  random : () -> Double,
) -> Bool {
  for dependency in items(field(feature, "dependencies")) {
    let name = str(dependency, "feature")
    guard self.features.get(name) is Some(parent) else { return false }
    // A missing parent, nested dependency or cycle fails even for enabled=false.
    if !items(field(parent, "dependencies")).is_empty() {
      return false
    }
    let expected_enabled = match field(dependency, "enabled") {
      False => false
      _ => true
    }
    let variants = items(field(dependency, "variants"))
    if expected_enabled && !variants.is_empty() {
      let variant = self.get_variant(name, ctx, random~)
      // The contract checks feature_enabled and the selected name, not the
      // variant's enabled field ("disabled" can itself be an allowed name).
      if !variant.feature_enabled ||
        !variants.any(fn(v) { text(v) == Some(variant.name) }) {
        return false
      }
    } else {
      let (decision, _) = self.evaluate_with_strategy(name, ctx, false, random)
      if decision.enabled != expected_enabled {
        return false
      }
    }
  }
  true
}
