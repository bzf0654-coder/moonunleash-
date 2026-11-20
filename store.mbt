///|
/// Single-owner state machine. All timestamps are monotonic milliseconds.
/// This type does not start tasks or perform I/O and is not OS-thread-safe.
pub struct SnapshotStore {
  priv mut snapshot : Snapshot?
  priv mut generation : Int64
  priv mut verified_at : Int64?
  priv mut origin : String
  priv mut last_error : String?
  priv mut failures : Int32
  priv mut closed : Bool
  priv stale_after_ms : Int64
  priv max_stale_ms : Int64?
}

///|
pub(all) struct Status {
  ready : Bool
  closed : Bool
  stale : Bool
  generation : Int64
  feature_count : Int32
  source : String
  last_error : String?
  consecutive_failures : Int32
}

///|
pub(all) struct EvaluatedDecision {
  decision : Decision
  generation : Int64
  stale : Bool
}

///|
pub(all) struct BatchDecision {
  decisions : Array[Decision]
  generation : Int64
  stale : Bool
}

///|
pub fn SnapshotStore::new(
  stale_after_ms~ : Int64 = 60000L,
  max_stale_ms? : Int64,
) -> SnapshotStore raise ConfigError {
  if stale_after_ms < 0 || max_stale_ms.map(fn(n) { n < 0 }).unwrap_or(false) {
    raise Invalid("staleness budgets must be nonnegative")
  }
  {
    snapshot: None,
    generation: 0L,
    verified_at: None,
    origin: "none",
    last_error: None,
    failures: 0,
    closed: false,
    stale_after_ms,
    max_stale_ms,
  }
}

///|
/// Installs only a fully parsed/validated snapshot; a failure leaves state intact.
pub fn SnapshotStore::install(
  self : SnapshotStore,
  source : String,
  now_ms : Int64,
  origin~ : String = "bootstrap",
) -> Int64 raise {
  if self.closed {
    raise Invalid("client closed")
  }
  if now_ms < 0 {
    raise Invalid("negative monotonic time")
  }
  let snapshot = Snapshot::parse(source)
  self.commit_snapshot(snapshot, now_ms, origin)
}

///|
fn SnapshotStore::commit_snapshot(
  self : SnapshotStore,
  snapshot : Snapshot,
  now_ms : Int64,
  origin : String,
) -> Int64 raise ConfigError {
  if self.closed || now_ms < 0 {
    raise Invalid("cannot commit closed state or negative monotonic time")
  }
  if self.generation == 9223372036854775807L {
    raise Invalid("snapshot generation exhausted")
  }
  self.snapshot = Some(snapshot)
  self.generation = self.generation + 1L
  self.verified_at = Some(now_ms)
  self.origin = origin
  self.last_error = None
  self.failures = 0
  self.generation
}

///|
/// A 304 can revalidate only an existing snapshot for an already accepted ETag.
pub fn SnapshotStore::revalidate(
  self : SnapshotStore,
  now_ms : Int64,
) -> Unit raise ConfigError {
  if self.closed || self.snapshot is None || self.verified_at is None {
    raise Invalid("cannot revalidate without an open snapshot")
  }
  if now_ms < 0 {
    raise Invalid("negative monotonic time")
  }
  self.verified_at = Some(now_ms)
  self.last_error = None
  self.failures = 0
}

///|
pub fn SnapshotStore::record_failure(
  self : SnapshotStore,
  reason : String,
) -> Unit {
  if !self.closed {
    self.last_error = Some(reason)
    if self.failures < 1000000 {
      self.failures = self.failures + 1
    }
  }
}

///|
/// Conservatively invalidate freshness after an adapter detects clock rollback.
/// The snapshot is retained. A new validated install/update restores readiness;
/// a no-change replay cannot revalidate an untrusted clock.
pub fn SnapshotStore::invalidate_clock(self : SnapshotStore) -> Unit {
  if !self.closed {
    self.verified_at = None
    self.record_failure("clock_rollback")
  }
}

///|
fn SnapshotStore::age(self : SnapshotStore, now_ms : Int64) -> Int64 {
  match self.verified_at {
    Some(t) if now_ms >= t => now_ms - t
    _ => 0L
  }
}

///|
pub fn SnapshotStore::status(self : SnapshotStore, now_ms : Int64) -> Status {
  {
    ready: !self.closed &&
    self.snapshot is Some(_) &&
    self.verified_at is Some(_),
    closed: self.closed,
    stale: self.snapshot is Some(_) &&
    (self.verified_at is None || self.age(now_ms) >= self.stale_after_ms),
    generation: self.generation,
    feature_count: self.snapshot.map(Snapshot::size).unwrap_or(0),
    source: self.origin,
    last_error: self.last_error,
    consecutive_failures: self.failures,
  }
}

///|
fn SnapshotStore::fallback_reason(
  self : SnapshotStore,
  now_ms : Int64,
) -> String? {
  if self.closed {
    return Some("closed")
  }
  if self.snapshot is None {
    return Some("not_ready")
  }
  if self.verified_at is None {
    return Some("clock_untrusted")
  }
  if self.max_stale_ms
    .map(fn(limit) { self.age(now_ms) >= limit })
    .unwrap_or(false) {
    return Some("expired")
  }
  None
}

///|
pub fn SnapshotStore::evaluate(
  self : SnapshotStore,
  name : String,
  ctx : Context,
  now_ms : Int64,
  fallback~ : Bool = false,
) -> EvaluatedDecision {
  let decision = match self.fallback_reason(now_ms) {
    Some(reason) => Decision::{ enabled: fallback, reason, }
    None =>
      match self.snapshot {
        Some(snapshot) => snapshot.evaluate(name, ctx, fallback~)
        None => Decision::{ enabled: fallback, reason: "not_ready", }
      }
  }
  { decision, generation: self.generation, stale: self.status(now_ms).stale, }
}

///|
pub fn SnapshotStore::evaluate_many(
  self : SnapshotStore,
  names : Array[String],
  ctx : Context,
  now_ms : Int64,
  fallback~ : Bool = false,
) -> BatchDecision {
  // Capture exactly one snapshot and generation before any evaluation.
  let snapshot = self.snapshot
  let generation = self.generation
  let reason = self.fallback_reason(now_ms)
  let decisions = names.map(fn(name) {
    match (reason, snapshot) {
      (Some(reason), _) => Decision::{ enabled: fallback, reason, }
      (None, Some(state)) => state.evaluate(name, ctx, fallback~)
      _ => Decision::{ enabled: fallback, reason: "not_ready", }
    }
  })
  { decisions, generation, stale: self.status(now_ms).stale, }
}

///|
pub fn SnapshotStore::get_variant(
  self : SnapshotStore,
  name : String,
  ctx : Context,
  now_ms : Int64,
) -> Variant {
  if self.fallback_reason(now_ms) is Some(_) {
    return {
      name: "disabled",
      enabled: false,
      feature_enabled: false,
      payload: None,
    }
  }
  match self.snapshot {
    Some(state) => state.get_variant(name, ctx)
    None =>
      {
        name: "disabled",
        enabled: false,
        feature_enabled: false,
        payload: None,
      }
  }
}

///|
pub fn SnapshotStore::close(self : SnapshotStore) -> Unit {
  self.closed = true
  self.snapshot = None
}
