# Compatibility scope

Baseline: [Unleash/client-specification 9ef6efa](https://github.com/Unleash/client-specification/tree/9ef6efa01feabeb699857192ad8106fd7d990235).

## Current measured scope

The pinned index contains **22 suites / 294 cases**. The required scope is now 13 suites / **104 passing cases**, with **190 cases explicitly NotRun**, not skipped passes. This is a scoped development preview, not a complete Unleash SDK certification.

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
| 16 strategy variants | 11 |
| 18 UTF-8 names | 2 |

Runtime reports contain per-case expected/actual values, status, group, index and suite name:

- [wasm-gc report](<../artifacts/conformance.wasm-gc.json>)
- [wasm report](<../artifacts/conformance.wasm.json>)
- [JavaScript report](<../artifacts/conformance.js.json>)

The backend label is produced by compile-time configuration, not a caller-supplied label. Node verifies every record against the [inventory](<spec-inventory.json>), rejects duplicates/missing cases and fails unless every required case passes. [The MoonBit runner](<../cmd/conformance/main.mbt>) performs the evaluations; Node does not implement a replacement flag engine.

Reproduce with `node tools/conformance.mjs wasm-gc` (also `wasm` or `js`). Linux native passed the new 104-case validator, check/test and offline example in [cloud run #5](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293), pinned to source commit `25b13135f5cf9ed01c460dd3e587ab44ab9d5756`. Windows native is still not a local passing runtime result. Native cloud artifact contents were not downloaded or copied into these checked-in local reports; see [publication status](<PUBLICATION_STATUS.md>). The fixture package is used only by verification tools and is not imported by the SDK core or network adapter.

## Not declared compatible

06 remote address; 13 advanced/date constraint suite; 14 SemVer; 15 complete global segments suite; 17 dependencies; 19/20 delta; 21 regex; 22 CIDR. Some constituent primitives exist, but no subset of these suites is silently counted as passed. Performance, full distributional/randomness testing and complete server interoperability are not established by 104 cases.

Whole-snapshot validation is strict: unknown strategies/operators and nonempty unsupported semantic fields reject installation. This intentionally differs from broad upstream behavior for unknown constructs. A single unsupported rule can block updates to other flags in the same response; the previous good snapshot remains in use according to explicit staleness policy.

There is no claim of Windows native execution, native real-network smoke, actual Unleash server acceptance, Edge compatibility, complete metrics support or production readiness. Linux native check/test and current conformance validation passed in cloud run #5. See [build status](<BUILD_STATUS.md>).

## Fixed reference SDK comparison

[Node SDK 6.12.2 differential](<DIFFERENTIAL_RESULTS.md>) agrees on the 93 selected official cases and 4608 generated ASCII common-profile decisions (JS backend only). **20 of 48 Unicode diagnostic decisions differ.** The UTF-8 byte policy and the reference SDK's raw-JS-string hashing route can assign different cohorts when any bucket-key component is non-ASCII. Passing suite 18's name lookups does not remove this limitation. These samples do not enlarge the official compatibility scope.

## Scope history (not rewritten)

Before implementation, Phase A froze 01,02,03,04,05,07,09,10,11,12,18 as mandatory. Suite 12 initially failed because global variants were not yet supported. Global variant validation/selection was then implemented, suite 08 added, and every variantTests group in the selected suites enabled. No original mandatory case or expected output was removed to turn a failure into a pass.

On 2026-11-18 strategy-level variants were implemented and suite 16 made Required, adding all 11 original cases (104 Pass / 190 NotRun). The separate [M1 differential](<STRATEGY_VARIANTS.md>) adds 1536 deterministic comparisons and preserves its initial oracle exception; these are not extra official cases. Broader constraints, complete segments, dependencies and delta remain required future work. The project completion target is all 22 frozen suites: **294 Pass / 0 Fail / 0 NotRun**, plus separately evidenced interoperability with OSS v7.4.0. It is not an open-ended subset-compatibility endpoint.
