# Compatibility scope

Baseline: [Unleash/client-specification 9ef6efa](https://github.com/Unleash/client-specification/tree/9ef6efa01feabeb699857192ad8106fd7d990235).

## Current measured scope

The pinned index contains **22 suites / 294 cases**, all now Required. Local wasm, wasm-gc and JavaScript reports each contain **294 Pass / 0 Fail / 0 NotRun** (2026-11-20). All **24 SHA-256 checks** pass and original cases/expectations remain unchanged. [Four-target cloud CI](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44689082346), source `4249cc378a480f1d2196e02611fd51abb2ca76e1`, now independently passes 294/0/0 on Linux native as well as wasm, wasm-gc and JS. The [public same-run proofs](<../artifacts/ci-run-44689082346.json>) verify all 24 hashes and report digests; raw artifact archives were not downloaded. This is a development preview, not a complete SDK certification or live-server acceptance.

| Required suite | Passing cases |
|---|---:|
| 01 basic flags | 5 |
| 02 userWithId | 5 |
| 03 legacy user rollout | 6 |
| 04 legacy session rollout | 6 |
| 05 random rollout boundaries | 4 |
| 06 remote address | 6 |
| 07 multiple strategies | 6 |
| 08 global variants | 17 |
| 09 strategy constraints | 17 |
| 10 flexible rollout | 10 |
| 11 constraint edges | 6 |
| 12 custom stickiness | 9 |
| 13—15 advanced/date, SemVer and complete segments (3 suites) | 88 |
| 16 strategy variants | 11 |
| 17 dependent features | 43 |
| 18 UTF-8 names | 2 |
| 19—20 public delta hydration/events (2 suites) | 4 |
| 21 regex | 37 |
| 22 CIDR | 12 |
| **Total: 22 suites** | **294** |

Runtime reports contain per-case expected/actual values, status, group, index and suite name:

- [wasm-gc report](<../artifacts/conformance.wasm-gc.json>)
- [wasm report](<../artifacts/conformance.wasm.json>)
- [JavaScript report](<../artifacts/conformance.js.json>)

The backend label is produced by compile-time configuration, not a caller-supplied label. Node verifies every record against the [inventory](<spec-inventory.json>), rejects duplicates/missing cases and fails unless every required case passes. [The MoonBit runner](<../cmd/conformance/main.mbt>) performs the evaluations; Node does not implement a replacement flag engine.

Reproduce with `node tools/conformance.mjs wasm-gc` (also `wasm`, `js` or a supported native toolchain's `native`). Suites 19/20 invoke the actual public MoonBit delta API. Linux native historically passed the **old 104-case** validator in [cloud run #5](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293), source `25b13135f5cf9ed01c460dd3e587ab44ab9d5756`; that is **not** evidence for the new 294-case increment. Local Windows native has only type checking. Historical cloud artifact contents were not downloaded or copied into these local reports; see [publication status](<PUBLICATION_STATUS.md>). Fixtures are imported only by verification tools, not production SDK packages.

## Not declared compatible

The entire fixed specification now passes locally, but it does not prove arbitrary RE2/JavaScript extensions, unlimited resource use, performance or full distributional/randomness properties. [Regex dialect/budgets](<REGEX.md>) and [delta ordering/resynchronization](<DELTA.md>) are explicit contracts. Delta state support does not implement SSE. The known Unicode cohort difference below is not erased by ASCII case coverage.

Whole-snapshot validation remains strict for unknown strategies, malformed semantic fields, duplicate keys and resource bounds. Following unchanged suite 13, well-shaped unknown constraint operators instead evaluate false **before inversion**; they cannot open a flag by inversion or block unrelated valid flags. Malformed constraints still reject the update. Last-good state and its generation survive rejected full or delta updates.

There is no claim of Windows native execution, new Linux native runtime proof, native real-network smoke, actual Unleash server acceptance, Edge compatibility, metrics acceptance or production readiness. Existing historical cloud results retain their original smaller scope. See [build status](<BUILD_STATUS.md>) and [all outstanding exit gates](<ACCEPTANCE.md>).

## Fixed reference SDK comparison

[Node SDK 6.12.2 differential](<DIFFERENTIAL_RESULTS.md>) agrees on the 93 selected official cases and 4608 generated ASCII common-profile decisions (JS backend only). **20 of 48 Unicode diagnostic decisions differ.** The UTF-8 byte policy and the reference SDK's raw-JS-string hashing route can assign different cohorts when any bucket-key component is non-ASCII. Passing suite 18's name lookups does not remove this limitation. These samples do not enlarge the official compatibility scope.

## Scope history (not rewritten)

Before implementation, Phase A froze 01,02,03,04,05,07,09,10,11,12,18 as mandatory. Suite 12 initially failed because global variants were not yet supported. Global variant validation/selection was then implemented, suite 08 added, and every variantTests group in the selected suites enabled. No original mandatory case or expected output was removed to turn a failure into a pass.

On 2026-11-18 strategy-level variants were implemented and suite 16 made Required, adding all 11 original cases (104 Pass / 190 NotRun). The separate [M1 differential](<STRATEGY_VARIANTS.md>) adds 1536 deterministic comparisons and preserves its initial oracle exception; these are not extra official cases. Later checkpoints added dependencies (147), advanced constraints/SemVer/segments (235), IP (253), regex (290) and public delta (294). See [the ledger, including first stops](<ACCEPTANCE.md>). The completion target remains all 22 frozen suites on **four backends**, plus separately evidenced interoperability with OSS v7.4.0, Unicode verdicts and same-SHA publication proof. The three local 294-case reports are not the whole project's endpoint.
