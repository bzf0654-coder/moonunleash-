# Build status (2026-11-17)

Observed, not claimed production readiness:

- Moon CLI `0.1.20261104 (940aa18)`; moonc `v0.10.20+65efd5b93`.
- Pure SDK: `moon check --deny-warn` passed.
- Pure SDK: `moon test --deny-warn --target wasm-gc` passed, 20 MoonBit tests (12 upstream suite runners plus 8 regression/unit tests).
- Pure SDK: `moon test --deny-warn --target js` passed with the same 20 tests.
- Native local tests attempted and failed before compilation because MSVC C++ Build Tools / cl.exe or clang-cl.exe are absent. The Windows SDK alone is installed. This is an environment limitation, not a passing native result.
- Upstream fixtures: 22 files pinned to `9ef6efa01feabeb699857192ad8106fd7d990235`; 24 SHA-256 checks including index and license passed during generation.
- First conformance run found suite 12 rejected global variants. Global variant validation/selection was implemented without removing the mandatory case. All 11 Phase A suites now pass; expanded suite 08 and all included variantTests also pass.

Remaining: per-case machine-readable runtime results, further constraints/segments, network SDK, real Unleash interoperability, public repository and application material. This file will be updated as verification proceeds; currently not submission-ready.

Windows PowerShell's default TLS transport failed to fetch raw GitHub inside this process, and curl/Schannel reported SEC_E_NO_CREDENTIALS. Built-in Node HTTPS fetched the immutable fixtures successfully, without subprocesses, extra npm packages or global TLS/security changes. The fixture fetch process-local execution policy changes were not persisted.
