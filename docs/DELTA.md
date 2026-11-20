# Public atomic delta state API

This is local state application, **not an SSE transport**. The built-in HTTP adapter's interoperability target remains full polling/ETag against fixed Unleash OSS v7.4.0. An internal server delta implementation is not used to infer a public streaming endpoint.

## API and ownership

- `Snapshot::from_delta(json)` starts from an empty state and applies the envelope's events. Both hydration and initial feature-update-only batches are supported, as required by unchanged suites 19 and 20.
- `snapshot.apply_delta(json)` returns a new validated snapshot. The old snapshot and its owned configuration remain unchanged.
- `store.apply_delta(json, monotonic_ms)` installs the batch atomically and advances the generation once, regardless of how many events it contains.
- `store.hydrate_delta(json, monotonic_ms)` explicitly resynchronizes/replaces both maps. Its first event must be hydration; this is how a caller deliberately resets a cursor after a stream/server reset.
- `delta_event_id()` on either type reports the last accepted event id. A full install resets the cursor to None.

All five event types are handled: hydration, feature-updated, feature-removed, segment-updated and segment-removed. Feature dependencies, segment references, modern variants and regex caches are validated/resolved using the same implementation as full snapshots. Segment removal can make a strategy unsatisfied until its referenced segment reappears. An absent removal target is harmless.

## Ordering and validation contract

Event ids must be nonnegative JSON-safe integers, at most 9007199254740991, and strictly increase within a batch. Gaps are allowed because server-side scoping may filter events. Old ids at/below the current cursor are structurally validated and skipped, allowing overlapping reconnect deliveries without applying old changes. Duplicate ids or disorder **within** a frame are rejected. A new hydration does not silently roll back a live cursor; use explicit resynchronization for that.

The entire source has the existing 8 MiB UTF-8/64-level JSON limit, duplicate keys are rejected, and a batch has at most 10000 events. Each feature/segment event is structurally validated even if subsequently removed or replayed. Unknown event types reject the batch rather than advancing past unknown semantics. The final configuration also passes full snapshot size/count/semantic validation before installation. Failures do not change snapshot, cursor, generation or freshness. Callers may record an observable synchronization failure separately.

Replays or empty batches on an already installed state revalidate freshness without advancing generation, like accepted no-change responses. They cannot revalidate a clock that has explicitly been invalidated. A newly validated state or explicit hydration can restore readiness. Close and nonnegative monotonic-time requirements apply to both update paths.

The cursor/atomicity checks are deliberate stronger input guarantees than the pinned Node repository reducer, which applies events sequentially and does not validate event ids. They do not change original official case inputs or expectations.

## Regression plan before execution

In addition to all four unchanged official delta cases through the actual public MoonBit API, assert:

1. Immutable old snapshots; hydration replacement of both maps; feature/segment upsert/removal and referenced missing segments fail closed.
2. One generation per multi-event batch and same-generation batch evaluation.
3. Reject a partially valid batch with a later invalid feature, unknown event, invalid id, duplicate/disordered id, duplicate JSON key or invalid segment; keep last-good data/cursor/generation/freshness.
4. Overlapping replays are idempotent and do not reinstall an older hydration; explicit hydration can reset the cursor and removes old flags/segments.
5. Empty/replayed batches, initial empty state, full-install cursor reset, closed stores, negative time and clock invalidation follow the stated lifecycle contract.

## Observed validation (2026-11-20)

All four original official delta cases and five additional lifecycle/atomicity regression tests passed on wasm, wasm-gc and JavaScript. The complete SDK passed **294/294 cases** with **73/63/63** MoonBit tests; native type checking passed. Linux native execution and same-source cloud proof for this increment are still pending.

No expectation is generated from candidate outputs. The conformance executable itself detects delta envelopes and calls `Snapshot::from_delta`; the Node supervisor does not convert events into synthetic full snapshots for the candidate.
