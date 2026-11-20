// SPDX-License-Identifier: Apache-2.0
// Bounded classic Unleash bucket accumulation, implemented entirely in MoonBit.

///|
/// Single-owner telemetry accumulator; no I/O, scheduling, or OS-thread safety.
/// A frozen pending string and a separate bounded active bucket are retained.
/// Invalid or excess names silently omit telemetry, not evaluation results.
pub struct Metrics {
  priv mut active : Map[String, (Int64, Int64, Map[String, Int64])]
  priv mut variant_pairs : Int32
  priv started : String
  priv mut start_ms : Int64
  priv mut last_prepare_ms : Int64
  priv mut pending : String?
}

///|
fn metrics_validate_time(now_ms : Int64) -> Unit raise ConfigError {
  if now_ms < 0L || now_ms > 253402300799999L {
    raise Invalid(
      "metrics epoch milliseconds must be within 0..253402300799999",
    )
  }
}

///|
fn metrics_pad(value : Int32, width : Int32) -> String {
  let mut result = value.to_string()
  while result.length() < width {
    result = "0" + result
  }
  result
}

///|
/// Adapts Howard Hinnant's public-domain civil_from_days algorithm:
/// https://howardhinnant.github.io/date_algorithms.html#civil_from_days
/// Specialized to validated nonnegative epoch milliseconds through year 9999.
/// Gregorian civil date from nonnegative epoch days. March-based 400-year eras
/// avoid platform clocks, locale rules, time zones, and floating-point dates.
fn metrics_timestamp(now_ms : Int64) -> String raise ConfigError {
  metrics_validate_time(now_ms)
  let days = (now_ms / 86400000L).to_int() + 719468
  let era = days / 146097
  let day_of_era = days % 146097
  let year_of_era = (
      day_of_era - day_of_era / 1460 + day_of_era / 36524 - day_of_era / 146096
    ) /
    365
  let day_of_year = day_of_era -
    (365 * year_of_era + year_of_era / 4 - year_of_era / 100)
  let march_month = (5 * day_of_year + 2) / 153
  let day = day_of_year - (153 * march_month + 2) / 5 + 1
  let month = march_month + (if march_month < 10 { 3 } else { -9 })
  let year = year_of_era + era * 400 + (if month <= 2 { 1 } else { 0 })
  let time = (now_ms % 86400000L).to_int()
  let date = "\{metrics_pad(year, 4)}-\{metrics_pad(month, 2)}-\{metrics_pad(day, 2)}"
  let clock = "\{metrics_pad(time / 3600000, 2)}:\{metrics_pad(time / 60000 % 60, 2)}:\{metrics_pad(time / 1000 % 60, 2)}"
  "\{date}T\{clock}.\{metrics_pad(time % 1000, 3)}Z"
}

///|
fn metrics_valid_name(name : String) -> Bool {
  // Bound UTF-8 encoding allocation before encoding a caller-controlled name.
  name != "" && name.length() <= 256 && @utf8.encode(name).length() <= 256
}

///|
fn metrics_increment(value : Int64) -> Int64 {
  if value < 9007199254740991L {
    value + 1L
  } else {
    9007199254740991L
  }
}

///|
fn metrics_json_integer(value : Int64) -> @json.Json {
  // Explicit decimal representation keeps the wire value an unquoted integer.
  @json.Json::number(value.to_double(), repr=value.to_string())
}

///|
/// Start a bucket at a validated UTC epoch-millisecond timestamp.
pub fn Metrics::new(now_ms : Int64) -> Metrics raise ConfigError {
  let started = metrics_timestamp(now_ms)
  {
    active: Map([]),
    variant_pairs: 0,
    started,
    start_ms: now_ms,
    last_prepare_ms: now_ms,
    pending: None,
  }
}

///|
/// The immutable construction timestamp, suitable for registration's started.
/// This does not move when active buckets are frozen or acknowledged.
pub fn Metrics::started_at(self : Metrics) -> String {
  self.started
}

///|
/// Record one boolean evaluation and, when supplied, one variant observation.
/// A rejected variant still records yes/no. Existing counters keep incrementing
/// after either cardinality limit, with every counter capped at 2^53 - 1.
pub fn Metrics::count(
  self : Metrics,
  name : String,
  enabled : Bool,
  variant? : String,
) -> Unit {
  if !metrics_valid_name(name) {
    return
  }
  let (yes, no, variants) = match self.active.get(name) {
    Some(counts) => counts
    None => {
      if self.active.length() >= 1000 {
        return
      }
      (0L, 0L, Map([]))
    }
  }
  self.active[name] = (
    if enabled {
      metrics_increment(yes)
    } else {
      yes
    },
    if enabled {
      no
    } else {
      metrics_increment(no)
    },
    variants,
  )
  match variant {
    Some(value) if metrics_valid_name(value) =>
      match variants.get(value) {
        Some(count) => variants[value] = metrics_increment(count)
        None =>
          if self.variant_pairs < 1000 {
            variants[value] = 1L
            self.variant_pairs = self.variant_pairs + 1
          }
      }
    _ => ()
  }
}

///|
/// Freeze a nonempty active bucket, or return the exact pending string on retry.
/// Counts made after freezing belong to a new bucket starting at that stop.
/// Every accepted call, including an empty call or retry, advances the rollback
/// check; empty calls do not move the bucket start. Invalid times change nothing.
pub fn Metrics::prepare(
  self : Metrics,
  now_ms : Int64,
) -> String? raise ConfigError {
  metrics_validate_time(now_ms)
  if now_ms < self.last_prepare_ms {
    raise Invalid("metrics prepare time must not move backward")
  }
  if self.pending is Some(source) {
    self.last_prepare_ms = now_ms
    return Some(source)
  }
  if self.active.is_empty() {
    self.last_prepare_ms = now_ms
    return None
  }
  let start = metrics_timestamp(self.start_ms)
  let stop = metrics_timestamp(now_ms)
  let toggles : Map[String, @json.Json] = Map([])
  for name, counts in self.active {
    let (yes, no, variants) = counts
    let values : Map[String, @json.Json] = Map([])
    for variant, count in variants {
      values[variant] = metrics_json_integer(count)
    }
    toggles[name] = @json.Json::object(
      Map([
        ("yes", metrics_json_integer(yes)),
        ("no", metrics_json_integer(no)),
        ("variants", @json.Json::object(values)),
      ]),
    )
  }
  let source = @json.Json::object(
    Map([
      ("start", @json.Json::string(start)),
      ("stop", @json.Json::string(stop)),
      ("toggles", @json.Json::object(toggles)),
    ]),
  ).stringify()
  // Commit only after timestamp validation and serialization are complete.
  self.active = Map([])
  self.variant_pairs = 0
  self.start_ms = now_ms
  self.last_prepare_ms = now_ms
  self.pending = Some(source)
  Some(source)
}

///|
/// Clear only the pending bucket after the caller accepts the send result.
/// This is idempotent and does not imply exactly-once delivery by a transport.
pub fn Metrics::acknowledge(self : Metrics) -> Unit {
  self.pending = None
}
