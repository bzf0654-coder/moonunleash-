// SPDX-License-Identifier: Apache-2.0
// Delta reducer behavior aligned with Unleash Node SDK 6.12.2 repository reducer;
// Copyright 2020 Bricks Software AS. Modified: bounded validation, atomic copy-on-
// write snapshots, replay handling, ordered cursors and no network/SSE transport.

///|
fn delta_events(source : String) -> Array[@json.Json] raise {
  let root = parse_configuration(source)
  guard field(root, "events") is Array(events) else {
    raise Invalid("delta.events: expected array")
  }
  if events.length() > 10000 {
    raise Invalid("delta event count budget exceeded")
  }
  events
}

///|
fn delta_event_id(event : @json.Json) -> Int64 raise ConfigError {
  require_object(event, "delta event")
  match field(event, "eventId") {
    Number(n, ..) if n >= 0 &&
      n <= 9007199254740991.0 &&
      n == n.to_int64().to_double() => n.to_int64()
    _ => raise Invalid("delta.eventId: expected nonnegative safe integer")
  }
}

///|
fn configuration_json(
  features : Array[@json.Json],
  segments : Array[@json.Json],
) -> @json.Json {
  @json.Json::object(
    Map([
      ("version", @json.Json::number(2.0)),
      ("features", @json.Json::array(features)),
      ("segments", @json.Json::array(segments)),
    ]),
  )
}

///|
/// Builds from an empty state using the public delta hydration/events envelope.
/// A feature-update-only initial batch is allowed by official suite 20.
pub fn Snapshot::from_delta(source : String) -> Snapshot raise {
  Snapshot::parse("{\"version\":2,\"features\":[]}").apply_delta_events(
    delta_events(source),
  )
}

///|
/// Last accepted delta event id; a full-state snapshot has no stream cursor.
pub fn Snapshot::delta_event_id(self : Snapshot) -> Int64? {
  self.cursor
}

///|
/// Returns a new fully validated snapshot, never mutating this snapshot.
/// Within a batch ids must increase (gaps are allowed). Replayed old events are
/// structurally validated and ignored; a failed event rejects the entire batch.
pub fn Snapshot::apply_delta(
  self : Snapshot,
  source : String,
) -> Snapshot raise {
  self.apply_delta_events(delta_events(source))
}

///|
fn Snapshot::apply_delta_events(
  self : Snapshot,
  events : Array[@json.Json],
) -> Snapshot raise {
  let mut features : Map[String, @json.Json] = Map([])
  let mut segments : Map[String, @json.Json] = Map([])
  for name, feature in self.features {
    features[name] = feature
  }
  for id, constraints in self.segments {
    segments[id] = @json.Json::object(
      Map([
        ("id", @json.parse(id)),
        ("constraints", @json.Json::array(constraints)),
      ]),
    )
  }
  let mut previous : Int64? = None
  let mut cursor = self.cursor
  for event in events {
    let id = delta_event_id(event)
    if previous.map(fn(p) { id <= p }).unwrap_or(false) {
      raise Invalid("delta event ids must increase within a batch")
    }
    previous = Some(id)
    let replay = self.cursor.map(fn(p) { id <= p }).unwrap_or(false)
    match required_text(event, "type") {
      "hydration" => {
        guard field(event, "features") is Array(hydrated_features) else {
          raise Invalid("hydration.features: expected array")
        }
        let hydrated_segments = optional_array(event, "segments")
        // Validate even a stale hydration rather than ignoring malformed input.
        let snapshot = Snapshot::parse(
          configuration_json(hydrated_features, hydrated_segments).stringify(),
        )
        if !replay {
          features = Map([])
          segments = Map([])
          for name, feature in snapshot.features {
            features[name] = feature
          }
          for segment in hydrated_segments {
            let (key, _) = validate_segment_definition(segment)
            segments[key] = segment
          }
        }
      }
      "feature-updated" => {
        let feature = field(event, "feature")
        let name = validate_feature_definition(feature)
        if !replay {
          features[name] = feature
        }
      }
      "feature-removed" => {
        let name = required_text(event, "featureName")
        if !replay {
          features.remove(name)
        }
      }
      "segment-updated" => {
        let segment = field(event, "segment")
        let (key, _) = validate_segment_definition(segment)
        if !replay {
          segments[key] = segment
        }
      }
      "segment-removed" => {
        let key = match field(event, "segmentId") {
          Number(n, ..) if n >= 0 && n == n.to_int().to_double() =>
            n.to_int().to_string()
          _ => raise Invalid("delta.segmentId: expected nonnegative integer")
        }
        if !replay {
          segments.remove(key)
        }
      }
      kind => raise Unsupported("delta event type: \{kind}")
    }
    if !replay {
      cursor = Some(id)
    }
  }
  if cursor == self.cursor {
    return self
  }
  let feature_values = []
  let segment_values = []
  for _, feature in features {
    feature_values.push(feature)
  }
  for _, segment in segments {
    segment_values.push(segment)
  }
  // Enforce the same final total-size/count limits and compile bounded regex
  // caches before publishing any of the batch's changes or its new cursor.
  let validated = Snapshot::parse(
    configuration_json(feature_values, segment_values).stringify(),
  )
  { ..validated, cursor, }
}

///|
/// Atomically installs one accepted batch. Replays/empty batches revalidate an
/// existing state without advancing its generation. No tasks or SSE are started.
pub fn SnapshotStore::apply_delta(
  self : SnapshotStore,
  source : String,
  now_ms : Int64,
) -> Int64 raise {
  if self.closed {
    raise Invalid("client closed")
  }
  if now_ms < 0 {
    raise Invalid("negative monotonic time")
  }
  let next = match self.snapshot {
    Some(snapshot) => snapshot.apply_delta(source)
    None => Snapshot::from_delta(source)
  }
  if self.snapshot is Some(previous) && next.cursor == previous.cursor {
    self.revalidate(now_ms)
    return self.generation
  }
  self.commit_snapshot(next, now_ms, "delta")
}

///|
/// Explicit resynchronization: the first event must be hydration. This may
/// reset a cursor after a server/stream restart and replaces both state maps.
pub fn SnapshotStore::hydrate_delta(
  self : SnapshotStore,
  source : String,
  now_ms : Int64,
) -> Int64 raise {
  if self.closed {
    raise Invalid("client closed")
  }
  if now_ms < 0 {
    raise Invalid("negative monotonic time")
  }
  let events = delta_events(source)
  if events.is_empty() || str(events[0], "type") != "hydration" {
    raise Invalid("delta resynchronization requires initial hydration")
  }
  let next = Snapshot::parse("{\"version\":2,\"features\":[]}").apply_delta_events(
    events,
  )
  self.commit_snapshot(next, now_ms, "delta_hydration")
}

///|
pub fn SnapshotStore::delta_event_id(self : SnapshotStore) -> Int64? {
  self.snapshot.bind(Snapshot::delta_event_id)
}
