# Classic metrics contract

MoonUnleash collects classic Unleash evaluation counters entirely in MoonBit. The pure accumulator is [metrics.mbt](<../metrics.mbt>); HTTP delivery and task lifetime are implemented in the [online package](<../online/client.mbt>). This implementation is not a durable queue.

## What is counted

Only calls on the online `Client` collect telemetry. Pure `Snapshot` / `SnapshotStore` evaluation remains side-effect free with respect to telemetry.

- `is_enabled` and `evaluate`: one `yes` or `no` for that requested name.
- `evaluate_many`: one `yes` or `no` for each requested array entry, including repeated names. The original same-generation evaluation contract is retained.
- `get_variant`: one boolean observation using `feature_enabled`, plus one observation for the returned variant name, including `disabled`.
- Internal dependency/parent evaluations do not create extra counters.
- Fallback evaluations before readiness, missing features, and stale-state evaluations are counted according to their public results. Calls after close do not add counters.

A boolean decision does not expose a variant and does not add a variant observation. There is no second evaluation just to manufacture a variant for telemetry.

## Bounded, retryable buckets

`Metrics::new(epoch_ms)` starts an active bucket. `count` adds counters, `prepare(epoch_ms)` freezes a nonempty bucket, and `acknowledge` removes only the frozen pending bucket. `started_at()` is the immutable RFC3339 construction time, suitable for registration metadata.

The wire bucket is `{start, stop, toggles: {name: {yes, no, variants}}}`. Start and stop are UTC RFC3339 strings with three millisecond digits. The formatter is portable integer Gregorian arithmetic, without FFI or host date parsing. Accepted time range is `0..253402300799999` Unix milliseconds (1970 through 9999).

There is at most one immutable pending JSON bucket and one active bucket. Calls made while an HTTP request is outstanding continue into the active bucket. Retrying returns the exact frozen pending data; acknowledgement never clears the active counts. An empty prepare emits no bucket and does not advance the bucket start.

Each active bucket permits at most **1,000 distinct toggle names and 1,000 total toggle/variant-name pairs**. Names must be nonempty and at most **256 UTF-8 bytes**. Invalid/excess new telemetry is omitted; existing counters still increment and evaluation results never change. A rejected variant does not suppress its boolean observation. Counters saturate at **9,007,199,254,740,991**, serialized as JSON decimal integers.

All accepted prepare calls, including empty calls and pending retries, advance rollback checking. Invalid/out-of-range/backward times reject atomically. No timestamp is fabricated to hide clock rollback. In the online adapter this means data is retained but flushing can fail until wall time catches up; a configuration refresh can recover readiness independently of telemetry. Starting a replacement client does not transfer the old client's in-memory counters.

## Online delivery and lifecycle

Options add `metrics_ms` (positive; default 60,000), `disable_metrics` (default false), and optional `instance_id`. Absent an explicit ID, each client creates a timestamp plus random instance identifier. Registration and metrics use the same ID and SDK version. Registration sends an RFC3339 `started` string and advertises `remoteAddress` along with the other supported strategies.

`with_client` owns a separate scoped metrics timer. The first periodic send occurs after `metrics_ms`; it does not delay feature polling. `Client::new` starts no background tasks. Use `flush_metrics()` for explicit delivery, especially before closing. Close is synchronous: it cancels scoped tasks and **does not promise a final network flush**.

A flush sends directly to `/api/client/metrics`, using the same bounded/timeout-controlled HTTP transport as polling. Concurrent flushes do not send the same pending bucket concurrently. Only **HTTP 202** acknowledges a classic bucket. Transport errors, timeouts, cancellation, registration failure, and other statuses retain it. In particular fixed Unleash v7.4.0 can return 204 when server metrics collection is disabled; this is not evidence of recorded counters. An empty or disabled flush is a successful no-op; a closed or busy client returns false.

Metrics errors are available separately through `metrics_error()` and `last_metrics_status()`. They do not increment configuration failure counts or invalidate a valid feature snapshot. `last_registration_status()` and `last_poll_status()` expose actual response status observations, not synthetic server acknowledgements. For an attempted request that fails before returning a response, its status is absent. A no-op does not create a new HTTP observation.

The delivery contract is **best effort with at-least-once retry behavior**, not exactly once and not guaranteed delivery: an ambiguous response can cause a duplicate on retry, process termination/close can lose unflushed data, and cardinality limits can omit telemetry. A server 202 acknowledges acceptance, not database persistence. Real-server acceptance must additionally wait for the target counters in the server's raw metrics readback before stopping the server.

## Tests and current evidence

[Accumulator regressions](<../metrics_wbtest.mbt>) cover Gregorian boundaries, validation/rollback, retry/active isolation, empty/ack behavior, escaping, UTF-8 limits, cardinality, and saturation. [Online regressions](<../online/metrics_test.mbt>) exercise public-call counting, identity, actual transport responses including 503/204/202, retry retention, busy exclusion, disabling, and scoped cancellation.

These tests and a configured CI job must not be represented as successful real-Unleash execution. Actual backend/commit/run evidence is tracked separately by the project acceptance report.

## Fixed-server protocol references

These references describe Unleash OSS v7.4.0 at `77c5af4d991541a93b877ddac0554beaaf61c8c5`, not a moving latest server:

- [Client application schema](<https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/client-application-schema.ts>): registration interval is documented as feature polling **seconds**, so `refresh_ms / 1000` is retained; it is not replaced with metrics milliseconds.
- [Runtime shared schema](<https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/metrics/shared/schema.ts>): Joi date conversion differs from the public numeric Unix-seconds description. RFC3339 avoids that unit ambiguity; this is not a claim that numeric schema values are illegal.
- [Classic metrics handler](<https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/metrics/instance/metrics.ts>): normal 202 versus disabled-collection 204.
- [Classic metrics schema](<https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/client-metrics-schema.ts>) and [date schema](<https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/date-schema.ts>): RFC3339 or numeric dates are accepted shapes; MoonUnleash intentionally emits strings.
