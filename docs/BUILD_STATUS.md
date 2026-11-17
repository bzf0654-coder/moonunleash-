# Build status (2026-11-17)

Observed, not claimed production readiness:

- Moon CLI `0.1.20261104 (940aa18)`; moonc `v0.10.20+65efd5b93`.
- wasm: 32 MoonBit tests passed (24 pure-core tests including 12 upstream suite runners; 8 online/lifecycle/security tests).
- wasm-gc: 24 pure-core tests passed. Online adapter is deliberately not built for this backend.
- JavaScript: 24 pure-core tests passed. Online adapter is deliberately not built for this backend.
- Native local tests attempted and failed before compilation because MSVC C++ Build Tools / cl.exe or clang-cl.exe are absent. The Windows SDK alone is installed. This is an environment limitation, not a passing native result.
- Upstream fixtures: 22 files pinned to `9ef6efa01feabeb699857192ad8106fd7d990235`; 24 SHA-256 checks including index and license passed during generation.
- First conformance run found suite 12 rejected global variants. Global variant validation/selection was implemented without removing the mandatory case. All 11 Phase A suites pass; expanded suite 08 and all included variantTests also pass.
- Offline example runs and prints deterministic user rollout and variant JSON.
- Actual loopback HTTP adapter test passed: 200 install -> 304 without generation change -> invalid JSON rejected -> 503 retains last good state -> new 200 replaces snapshot -> 302 refused. Accepted ETag remains unchanged after bad updates. Chunked response size guard also passed.
- The [HTTP smoke report](<../artifacts/http-smoke.json>) is from a controlled Node HTTP server, **not an actual Unleash server**. It proves transport/state behavior, not full server interoperability or TLS behavior.
- Scoped polling, cancellation during an in-flight request, explicit close during registration, bounded wait_ready, authentication-header/URL validation, state staleness and expiration, and clock rollback recovery have passing tests.

Remaining: per-case machine-readable conformance runtime results, reference SDK differential testing, further compatibility, real Unleash interoperability, public repository, CI and application material. Currently not submission-ready.

Registration payload follows the [official client registration contract](https://docs.getunleash.io/api/register-client-application): interval in seconds and started as Unix seconds. The mock checks those fields, strategies and appName; the started timestamp is fixed at client construction. This is contract checking, not proof of server acceptance.

## Environment and behavior notes

Windows PowerShell's default TLS transport failed to fetch raw GitHub inside this process, and curl/Schannel reported SEC_E_NO_CREDENTIALS. Built-in Node HTTPS fetched the immutable fixtures successfully, without subprocesses, extra npm packages or global TLS/security changes. The fixture fetch process-local execution policy changes were not persisted.

The installed standard library documents core/async.now as epoch milliseconds, not monotonic time. The online client detects backward steps, clears its ETag, conservatively invalidates old-snapshot evaluation and requires a new full accepted response. Fake-time pure state tests cover this behavior; the library does not claim a platform-monotonic clock it does not have.

Earlier milestone contained 20 tests on pure backends; current counts expand that coverage rather than replace or delete required assertions. Native and actual-Unleash evidence remain pending and are not inferred from wasm or mock results.
