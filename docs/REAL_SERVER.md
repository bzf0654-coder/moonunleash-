# Real Unleash 7.4.0 acceptance

**Acceptance status: PASS on wasm and Linux native (2026-11-20).** [Real-server run 44690815719](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44690815719) passed both targets at source `1f5cc6378948d1ac04655c64871e24d6bfbab665`, the same SHA as the [four-target 294-case SDK run](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44690815957). The [verified public record](<../artifacts/ci-run-44690815719.json>) contains both current-run PASS summaries, all twenty operations, seven proposal decisions, five independent parent-phase ETags, one registration, two accepted metrics buckets and exact database readback counts; it verifies actual toolchain, PostgreSQL 15.20 and pinned image/config/container identities. Nonempty same-SHA artifact metadata was checked; authenticated raw artifact archives were not downloaded. Earlier readiness/bootstrap/recovery failures remain in the [acceptance ledger](<ACCEPTANCE.md>); this result does not rewrite them. SDK specification CI and real-server interoperability are independently required gates.

## Entry points and boundary

- [Acceptance workflow](../.github/workflows/real-server.yml): automatic push, pull-request and manual dispatch; independent Linux `wasm` and Linux `native` jobs.
- [Control-plane runner](../tools/real-server.mjs): no npm dependencies; requires Node 24, Docker and an installed Moon toolchain. Creates its own network, ephemeral PostgreSQL and fixed Unleash container; tears down only its own generated names.
- [Registry verifier](../tools/server-provenance.mjs): can also run independently. Fetches and verifies raw content bytes, not reformatted JSON hashes.
- [Moon acceptance package](../cmd/server-acceptance/moon.pkg) and [Moon acceptance program](../cmd/server-acceptance/main.mbt): one `with_client` scope and one real `Client` throughout all scenarios for each target.

Node does **not** proxy or issue SDK `/api/client/register`, `/api/client/features` or `/api/client/metrics` requests. Its outbound HTTP helper permits only `/health` and `/api/admin/…`. The SDK uses `Transport::http(options)` to connect directly to the mapped Unleash port. A transparent decorator reports copies of method/body/ETag and unmodified responses to a separate randomly named loopback control endpoint. The decorator returns the original `Response` unchanged; observation failure fails the run rather than fabricating a response. No SDK token is forwarded to the control endpoint. There is no public-SSE assumption, no Node evaluation oracle, and no Golden generated from compiled SDK results.

## Run (Linux only)

Use a disposable development runner. The script pulls images, starts/stops its own containers, compiles/runs the acceptance executable with `moon run`, writes evidence and removes those containers/network. PostgreSQL data lives on a container tmpfs, not a repository or named volume. No production service, credentials or cloud ECS is involved.

```sh
moon update
node tools/real-server.mjs wasm
node tools/real-server.mjs native
# Optional standalone identity check; does not run Docker:
node tools/server-provenance.mjs ci-output/provenance-only
```

Each target's default output directory must not already exist: stale evidence is refused. For a rerun select a new explicit third argument instead of reusing old results:

```sh
node tools/real-server.mjs wasm ci-output/real-server-wasm-rerun-2
```

The runner passes `REAL_SERVER_URL` (API base ending `/api`), `REAL_CONTROL_URL`, `REAL_APP_NAME`, `REAL_INSTANCE_ID` and `REAL_BACKEND_TOKEN` only to the acceptance child. The control URL is ephemeral and loopback-only. App and instance names contain the target plus a per-run random identifier. The child is not a general external-server utility: its paired control plane intentionally owns fixture mutations and Docker outage control.

## Frozen server identity

| Item | Value |
| --- | --- |
| Release | Unleash OSS `v7.4.0` |
| Checked-out source | `77c5af4d991541a93b877ddac0554beaaf61c8c5` |
| OCI index | `sha256:4aadfc1a7366f5e7f5f9a4aa591ade7a3d1843ffd53b224ac58bf945442f4356` |
| Executed Linux amd64 manifest | `sha256:fd521aeb776da5577c1889514bae9d48f901e8bc6119529c643797f901f75980` |
| Its attestation manifest | `sha256:67d5269fc1c174b057fc48cac2fc861a9ee6542ea8ada899aa692e7d393d7fdb` |
| In-toto statement blob | `sha256:eda072846a1ce1fda9de02f2664735fa4b8bb5d5858f53f2b83b8abdb3033062` |
| Image config | `sha256:8f47f34458be176c3d3467bbded66f815ca341f0c92817e150ac2f9b1dcf5688` |

Execution explicitly uses `--platform linux/amd64` and `unleashorg/unleash-server@<amd64 manifest digest>`, never the mutable release tag. The verifier checks the index's platform descriptor, attestation descriptor association, all downloaded object hashes, statement subject and BuildKit source revision. Docker independently verifies the content-addressed image layers during pull. The verifier does not download all image layers itself.

Registry endpoints:

```text
GET https://auth.docker.io/token?service=registry.docker.io&scope=repository:unleashorg/unleash-server:pull
GET https://registry-1.docker.io/v2/unleashorg/unleash-server/manifests/<index>
    Accept: application/vnd.oci.image.index.v1+json
GET https://registry-1.docker.io/v2/unleashorg/unleash-server/manifests/<platform-or-attestation-manifest>
    Accept: application/vnd.oci.image.manifest.v1+json
GET https://registry-1.docker.io/v2/unleashorg/unleash-server/blobs/<config-or-statement>
```

The registry bearer is kept only in memory, never in request logs or artifacts. Every downloaded raw object is SHA256-checked before parsing; response headers and raw bodies are retained. In the statement, the checked source is:

```text
predicate.metadata["https://mobyproject.org/buildkit@v1#metadata"].vcs.revision
predicate.metadata["https://mobyproject.org/buildkit@v1#metadata"].vcs.source
```

**Do not substitute the OCI revision label:** that label is the workflow-dispatch revision (`5ca04f52912f802fe1fc493ffe7e52d7cddbf2ac`), not the checked-out version source. [Producer workflow](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/.github/workflows/docker_publish.yaml) checks out the version tag; [producer run](https://api.github.com/repos/Unleash/unleash/actions/runs/20166185029) records the workflow SHA. [Tag ref](https://api.github.com/repos/Unleash/unleash/git/ref/tags/v7.4.0) points to [annotated tag object](https://api.github.com/repos/Unleash/unleash/git/tags/02a0641e66969697a2b08e66337fd6a62077c509), which resolves to the frozen source.

**Scope of proof:** hashes and producer-reported source association, **not independently verified signatures or reproducible builds**. The provenance itself says `completeness.materials=false` and `reproducible=false`. PostgreSQL `postgres:15`, official Moon stable, hosted runner and actions are not all immutable inputs; actual pulled image metadata, installer checksum, toolchain versions and checkout SHA are recorded. Do not describe the entire CI environment as reproducible merely because Unleash is digest-pinned.

## Startup and bootstrap

Only the server is exposed, on an OS-selected free `127.0.0.1` host port published explicitly to Docker. An empty/random Docker HostPort can be reallocated after stop/start; the selected numeric binding is fixed for this container and checked again before recovery readiness. A rare port-release/bind race is a startup failure, never an origin change for the SDK. PostgreSQL stays on the private per-run Docker network. The runner waits for `pg_isready`, then `/health` plus authenticated Admin project readiness. Server environment:

```text
DATABASE_URL=postgres://unleash:<ephemeral-password>@<private-db-name>:5432/unleash
DATABASE_SSL=false
HTTP_HOST=0.0.0.0
HTTP_PORT=4242
UNLEASH_URL=http://127.0.0.1:4242
INIT_ADMIN_API_TOKENS=*:*.<ephemeral-random-secret>
INIT_BACKEND_API_TOKENS=default:development.<ephemeral-random-secret>
SEND_TELEMETRY=false
CHECK_VERSION=false
LOG_LEVEL=warn
```

These are verified [configuration names](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/create-config.ts), not assumed disable flags. Tokens are direct `Authorization: <token>`, not Bearer. Credentials are per-run disposable values, redacted from command metadata; container inspect selects only safe fields before output, never raw credential-bearing configuration. A fresh database supplies default project plus development/production environments.

Admin creates `ci-parent` and `ci-child` (feature POST actually **201**, despite route OpenAPI metadata saying 200), then creates **strategy-level** `flexibleRollout` variants **before** enabling either environment. Otherwise `/on` can insert a default OR strategy and invalidate a constraint fixture. Parent is 100% userId-sticky blue, payload `parent-blue`. Child has **two matching strategies in explicit order**: first gold / `child-gold` (`sortOrder=0`), then later / `must-not-select` (`sortOrder=1`), each 100% userId-sticky and constrained to `userId IN [allowed-user]`. Both match the allowed user; the SDK must choose the first strategy's gold payload. Both reject the denied user, so adding the second strategy cannot accidentally bypass the constraint check. Child dependency requires parent enabled and parent variant blue. Strategy POST, dependency POST and `/on`/`/off` actually return **200**, with enable/dependency operations returning empty bodies.

The frozen [create-strategy schema](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/create-feature-strategy-schema.ts) explicitly permits `sortOrder:number`. After creating both child strategies, the runner uses their returned IDs in `POST …/strategies/set-sort-order` with root-array body `[{"id":"<gold-id>","sortOrder":0},{"id":"<later-id>","sortOrder":1}]`, then checks ordered Admin GET output. The [sort-order schema](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/set-strategy-sort-order-schema.ts) requires both fields; the controller actually returns **200 empty**. Every observed full SDK response must contain exactly two child strategies in gold/later order with both constraints intact. Moon's gold/payload assertion and raw metrics' absence of any `later` count independently demonstrate first-match order; merely checking the bootstrap request is not sufficient.

Sources: [feature controller](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/feature-toggle/feature-toggle-controller.ts), [auto-default insertion](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/feature-toggle/feature-toggle-service.ts#L1939-L1997), [dependency controller](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/dependent-features/dependent-features-controller.ts).

## Application example: real 50/50 configuration and seven decisions

A separate `recommendation-ab` flag is created with the application's exact parameters: `groupId=recommendation-ab-v1`, `rollout=100`, `stickiness=userId`, `plan IN [enterprise]`; strategy variants `control` (500 fixed, string payload `baseline`) and `treatment` (500 variable, `model-v2`); no global variants. The actual SDK HTTP observer checks the server-returned parameters, weights and payloads. MoonBit parses those received response bytes with the public `Snapshot::parse`, never synthetic or edited JSON, and asserts user-1/control, user-2/treatment, free-plan/disabled, missing-userId/disabled and unknown-feature/disabled. Two additional Admin phases really disable the flag, then re-enable it with rollout=0; each waits for the matching committed SDK response and proves disabled. A JSON Patch replaces only the strategy's rollout field, preserving its actual variants.

These seven decisions use the immutable Snapshot API and do not add metrics to the online two-flag test. The original `ci-parent`/`ci-child` counters and persistence gates below are unchanged. Three required checkpoints (`recommendation`, `recommendation-off`, `recommendation-zero`) extend the original ordered seventeen operations to twenty; none of the old operations is removed. Five separate parent-phase ETags must remain distinct, so the extra recommendation revisions cannot satisfy the original parent update gate accidentally. Implementation/type checking alone is not a passing real-server record.

## Acceptance sequence and independent counts

The client uses `refresh_ms=100`, `timeout_ms=1000`, a one-hour metrics loop interval, and explicit flushes. It never manually refreshes during outage/recovery; background polling must do the work. Snapshot-body observations are used to wait for configuration, **without evaluation calls**, avoiding hidden variable metrics counts. Public-call results, reason/variant/payload assertions remain in Moon.

1. Real registration **202**, unique identity and Admin instance readback. Metrics cannot stand in for registration: its handler also creates instances, so the registration wire event is required first.
2. Real features **200** with ETag, then **304** with matching `If-None-Match`. Fixed v7.4.0 strips headers from 304; absence of response ETag must not erase the saved tag. Raw full payload is checked for strategy variants, payloads, userId constraint and parent-blue dependency.
3. Baseline: parent `get_variant` blue; child allowed `get_variant` gold; child denied `is_enabled=false`; child allowed `evaluate=true`; `evaluate_many([parent,child])` both true. Each API call is explicit, once.
4. Admin parent `/off`; wait background poll; parent `is_enabled=false` and child allowed `get_variant=disabled` (dependency). Admin parent `/on`; child allowed variant gold again.
5. Explicit SDK metrics POST **202**, exact payload counts, then exact per-app/environment/flag server raw readback. **Wait for persistence before stop.** A 202 alone is not persistence evidence.
6. Docker stops the actual server container (PostgreSQL stays alive). Wait for background poll error; require ready last-good state, unchanged generation, last error and positive failure count. Child last-good variant gold; parent last-good enabled.
7. Start **the same container**, wait real background polling to recover without a new `Client`, then perform another real Admin `/off` and `/on`; require dependency disabled/restored again.
8. Flush remaining metrics before leaving the client scope; verify second 202 and exact cumulative server readback; require all checkpoints and successful child exit before writing PASS.

Only `get_variant` counts variant names. `is_enabled`, `evaluate` and each `evaluate_many` result count yes/no only. Internal dependency evaluation must not add counts. The independent expected counts are handwritten from the sequence above, not generated from captured SDK output:

| Readback point / flag | yes | no | variant counts |
| --- | ---: | ---: | --- |
| Before outage / parent | 2 | 1 | blue=1 |
| Before outage / child | 4 | 2 | gold=2, disabled=1 |
| Final cumulative / parent | 3 | 1 | blue=1 |
| Final cumulative / child | 6 | 3 | gold=4, disabled=2 |

The runner compares both SDK-emitted payload totals **and separately persisted server raw rows** to these constants. It filters by exact unique appName, development environment and featureName, sums hourly rows, and rejects missing or extra counters. No broad summary across unrelated applications substitutes for this check.

Readbacks:

```text
GET /api/admin/metrics/instances/{appName}/environment/development
GET /api/admin/client-metrics/features/{flag}/raw?hoursBack=1
```

## Fixed-version protocol traps

- [Registration schema](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/client-application-schema.ts) documents `interval` as toggle refresh **seconds**; it is not unitless. The SDK sends 0.1 for 100 ms. Server runtime only checks that it is a number.
- Registration `started` permits RFC3339 string or number (description says Unix seconds). [Metrics date schema](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/openapi/spec/date-schema.ts) permits RFC3339 string or integer Unix timestamp. ISO strings are not the only schema-legal forms. However [runtime Joi](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/metrics/shared/schema.ts) uses plain `joi.date()` without Unix-seconds mode. The SDK emits UTC ISO strings for registration and metrics to avoid numeric-unit ambiguity and 1970-hour readback failures.
- [Features/ETag handler](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/client-feature-toggles/client-feature-toggle.controller.ts#L307-L363): version 2, exact quoted ETag, empty 304, no required ETag response header on 304. No SSE or delta support is claimed here.
- [Metrics handler](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/metrics/instance/metrics.ts#L170-L207): normal 202 empty; internal `disableMetrics` produces 204 **without processing metrics**; 204 is rejected by this test.
- [Scheduler](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/scheduler/schedule-services.ts): configuration revision about 1 s, metrics persistence about 5 s, instance persistence about 10 s. Bounded 60 s readback predicates are used. [Metrics service](https://github.com/Unleash/unleash/blob/77c5af4d991541a93b877ddac0554beaaf61c8c5/src/lib/features/metrics/client-metrics/metrics-service-v2.ts) caches known feature names for 10 s; bootstrap reserves an 11 s cache-settling window before SDK traffic. This delay does not substitute for eventual readback assertions.

## Evidence and failure interpretation

The current-run output includes registry raw JSON and response headers, provenance conclusions/caveats, actual Docker image identities, redacted command metadata plus exit statuses, raw Docker/server/PostgreSQL logs, Moon stdout/stderr and exit status, original SDK request bodies and response bodies/ETags (without Authorization), Admin request/response records, checkpoint status/generation/error data, exact expected/readback metrics and final result. Artifact upload runs even when prior steps fail. Logs never need production credentials; do not configure any for this workflow.

The script refuses an existing output directory and writes PASS only after the complete scenario and successful Moon child exit. A registry outage, compiler error, Docker readiness timeout, mismatched body, absent register202, lost ETag, metric 204, incorrect counters, missing persistence or failed auto-recovery is a failing run, not an omitted case. If the workflow has only been authored or type-checked but not executed, status remains **Pending**, not PASS. The integrating agent must review the final diff, compile both targets, and inspect actual uploaded CI evidence before claiming completion.
