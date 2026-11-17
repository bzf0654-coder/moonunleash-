# Build status (2026-11-17)

Observed, not claimed production readiness:

- Moon CLI `0.1.20261104 (940aa18)`; moonc `v0.10.20+65efd5b93`.
- wasm: 35 MoonBit tests passed (26 pure-core tests including 12 upstream suite runners; 9 online/lifecycle/security tests).
- wasm-gc: 26 pure-core tests passed. Online adapter is deliberately not built for this backend.
- JavaScript: 26 pure-core tests passed. Online adapter is deliberately not built for this backend.
- Native MoonBit type check now passes (`moon check --target native --deny-warn`). The earlier native build/test attempt stopped before C compilation because MSVC C++ Build Tools / cl.exe or clang-cl.exe are absent. The Windows SDK alone is installed. Native binaries and runtime behavior remain unverified; the type check is not a passing native execution result.
- Upstream fixtures: 22 files pinned to `9ef6efa01feabeb699857192ad8106fd7d990235`; 24 SHA-256 checks including index and license passed during generation.
- First conformance run found suite 12 rejected global variants. Global variant validation/selection was implemented without removing the mandatory case. All 11 Phase A suites pass; expanded suite 08 and all included variantTests also pass.
- Offline example runs and prints deterministic user rollout and variant JSON.
- Actual loopback HTTP adapter test passed: 200 install -> 304 without generation change -> invalid JSON rejected -> 503 retains last good state -> new 200 replaces snapshot -> 302 refused. Accepted ETag remains unchanged after bad updates. Chunked response size guard also passed.
- The [HTTP smoke report](<../artifacts/http-smoke.json>) is from a controlled Node HTTP server, **not an actual Unleash server**. It proves transport/state behavior, not full server interoperability or TLS behavior.
- Scoped polling, cancellation during an in-flight request, explicit close during registration, bounded wait_ready, authentication-header/URL validation, state staleness and expiration, and clock rollback recovery have passing tests.

Per-case runtime reports now independently pass on wasm-gc, wasm and JS: **93 Pass, 0 Fail, 201 NotRun** across all 294 inventoried cases. Required cases cannot silently become skipped successes. The first JS provenance check failed because argv layouts differ; backend labels now use compile-time target configuration. Reports were rerun successfully after that fix; see the [matrix](<COMPATIBILITY_SCOPE.md>).

[CI](<../.github/workflows/ci.yml>) and [application one-pager](<APPLICATION_ONE_PAGE.md>) are prepared. The [first real GitHub CI run](<PUBLICATION_STATUS.md>) passed JS/wasm-gc but failed wasm/native at the check/test step. The complete four-target matrix is NOT passing evidence; first-failure metadata is retained and fresh diagnostic annotations are being added. CI follows the official stable installer and records actual versions; attempted historical archive HEAD requests returned HTTP 403, so no guessed fixed installer tag is presented as verified.

Publication update: user confirmed bzf0654-coder and authorized a separate moonunleash repository, preserving the existing moonshop project. SSH authentication returned that exact account. There is no reusable HTTPS/API credential for repository creation. After the user reported creation, both a fresh public API request and authenticated SSH still returned repository not found; no push occurred. Git's command-string SSH wrapper hit an MSYS sandbox IPC error; its approved exact read-only retry reached GitHub and confirmed the repository error. No global proxy/security settings were changed. Subsequent correction: the user supplied the actual target [moonunleash-](https://github.com/bzf0654-coder/moonunleash-) with a trailing hyphen. Its public API returns 200, owner bzf0654-coder, private=false and size=0. The earlier 404 diagnosis applies to the different URL without that hyphen; source first push 8dca496 subsequently succeeded, and the first real CI result is recorded above and in the publication status.

Pinned development-only Node SDK 6.12.2 differential now runs on the JS backend: original 93 official cases and 4608 generated ASCII common-profile cases all agree; 48 Unicode diagnostic decisions include 20 disagreements. A controlled encoding-only intervention explains those 48 samples but is NOT an unmodified SDK compatibility pass. Ten UTF-8 primitive vectors were added as one regression test, producing the then-current 33/25/25 test counts. See [differential results and limits](<DIFFERENTIAL_RESULTS.md>).

The next contract check found and fixed missing appName/environment defaults in online evaluations. All public decision entry points now merge client defaults without replacing explicit values. A core regression and a wasm online regression produce the current **35/26/26** counts. Targeted calls to the actual pinned Node wrapper prototype methods agree **108/108**, without constructing its network/metrics lifecycle. See [context defaults and scope](<CONTEXT_DEFAULTS.md>). The first cross-backend attempt also exposed the new async test missing an online-only target declaration; its scope now matches the existing wasm/native adapter, and all three supported test backends were rerun successfully.

Remaining: further compatibility as justified, real Unleash interoperability, native validation, repository publication and personal application information. [Current official requirements](<OFFICIAL_REQUIREMENTS.md>) specify a public repository and one-page explanation; repository/account-dependent conditions are not yet met. Currently not fully submission-ready.

Registration payload follows the [official client registration contract](https://docs.getunleash.io/api/register-client-application) and the observed [server schema](https://github.com/Unleash/unleash/blob/main/src/lib/openapi/spec/client-application-schema.ts): interval in seconds and started as Unix seconds (the schema also accepts RFC-3339 strings). This current server-source observation is not a pinned server execution. The mock checks those fields, strategies and appName; the started timestamp is fixed at client construction. This is contract checking, not proof of server acceptance.

## Environment and behavior notes

Windows PowerShell's default TLS transport failed to fetch raw GitHub inside this process, and curl/Schannel reported SEC_E_NO_CREDENTIALS. Built-in Node HTTPS fetched the immutable fixtures successfully, without subprocesses, extra npm packages or global TLS/security changes. The fixture fetch process-local execution policy changes were not persisted.

The installed standard library documents core/async.now as epoch milliseconds, not monotonic time. The online client detects backward steps, clears its ETag, conservatively invalidates old-snapshot evaluation and requires a new full accepted response. Fake-time pure state tests cover this behavior; the library does not claim a platform-monotonic clock it does not have.

Earlier milestone contained 20 tests on pure backends; current counts expand that coverage rather than replace or delete required assertions. Native and actual-Unleash evidence remain pending and are not inferred from wasm or mock results.
