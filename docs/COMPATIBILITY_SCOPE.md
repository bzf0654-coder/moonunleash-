# Compatibility scope

Baseline: [Unleash/client-specification 9ef6efa](https://github.com/Unleash/client-specification/tree/9ef6efa01feabeb699857192ad8106fd7d990235).

## Current measured scope

The pinned index contains **22 suites / 294 cases**. The required scope is 12 suites / **93 passing cases**, with **201 cases explicitly NotRun**, not skipped passes. This is a scoped development preview, not a complete Unleash SDK certification.

| Required suite | Passing cases |
|---|---:|
| 01 basic flags | 5 |
| 02 userWithId | 5 |
| 03 legacy user rollout | 6 |
| 04 legacy session rollout | 6 |
| 05 random rollout boundaries | 4 |
| 07 multiple strategies | 6 |
| 08 global variants | 17 |
| 09 strategy constraints | 17 |
| 10 flexible rollout | 10 |
| 11 constraint edges | 6 |
| 12 custom stickiness | 9 |
| 18 UTF-8 names | 2 |

Runtime reports contain per-case expected/actual values, status, group, index and suite name:

- [wasm-gc report](<../artifacts/conformance.wasm-gc.json>)
- [wasm report](<../artifacts/conformance.wasm.json>)
- [JavaScript report](<../artifacts/conformance.js.json>)

The backend label is produced by compile-time configuration, not a caller-supplied label. Node verifies every record against the [inventory](<spec-inventory.json>), rejects duplicates/missing cases and fails unless every required case passes. [The MoonBit runner](<../cmd/conformance/main.mbt>) performs the evaluations; Node does not implement a replacement flag engine.

Reproduce with `node tools/conformance.mjs wasm-gc` (also `wasm` or `js`). Native is a future CI target, not a local passing result. The fixture package is used only by verification tools and is not imported by the SDK core or network adapter.

## Not declared compatible

06 remote address; 13 advanced/date constraint suite; 14 SemVer; 15 complete global segments suite; 16 strategy variants; 17 dependencies; 19/20 delta; 21 regex; 22 CIDR. Some constituent primitives exist, but no subset of these suites is silently counted as passed. Performance, full distributional/randomness testing and complete server interoperability are not established by 93 cases.

Whole-snapshot validation is strict: unknown strategies/operators and nonempty unsupported semantic fields reject installation. This intentionally differs from broad upstream behavior for unknown constructs. A single unsupported rule can block updates to other flags in the same response; the previous good snapshot remains in use according to explicit staleness policy.

There is no claim of native testing, actual Unleash server acceptance, Edge compatibility, complete metrics support or production readiness. See [build status](<BUILD_STATUS.md>).

## Scope history (not rewritten)

Before implementation, Phase A froze 01,02,03,04,05,07,09,10,11,12,18 as mandatory. Suite 12 initially failed because global variants were not yet supported. Global variant validation/selection was then implemented, suite 08 added, and every variantTests group in the selected suites enabled. No original mandatory case or expected output was removed to turn a failure into a pass.

Broader constraints, segments, strategy variants and dependencies remain planned expansion, subject to explicit tests and clear scope revisions.
