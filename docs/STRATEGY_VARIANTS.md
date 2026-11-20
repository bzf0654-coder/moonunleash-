# Strategy variants — M1 implementation and validation

## Contract and pre-execution validation scope (2026-11-18)

The native evaluator must retain the **first enabled strategy** from the same flag evaluation. Its variants take priority; empty or unselectable strategy variants use the legacy feature-variant fallback. An earlier enabled strategy with no variants must not be skipped to find a later variant. Variant buckets use the strategy groupId, not the feature name. Stickiness follows the pinned reference's first-variant value when nonempty, then the strategy parameter, then default identity selection. A zero-weight strategy variant list falls back rather than disabling the feature.

This changes no public API and does not add Node to production. Validation targets the unmodified [official suite 16](<../tests/fixtures/upstream/16-strategy-variants.json>) and the fixed [Node SDK oracle](<../tools/reference/package.json>). Complete compatibility remains all 22 suites / 294 cases, not this milestone.

Before executing the new differential, freeze these inputs:

- All 11 original suite-16 cases, comparing MoonBit, the actual Node core, and original expectations.
- Twelve fixed configuration shapes: primary strategy variants; legacy fallback; first empty strategy; first zero-weight strategy; failed first constraint; multiple matching strategies; 50% first rollout; disabled flag; missing groupId; empty groupId; explicit variant stickiness; variant override.
- Each shape uses the same 64 ASCII contexts user-1 through user-64, cycling enterprise/free/internal plans and seven tenant identities. Evaluate both Boolean and canonical variant results: **1536 matrix comparisons**, plus the 11 official cases.
- No filtering users by observed bucket, changing weights after failures, changing old differential v1, or silently normalizing Unicode inputs. All stable identities required by these deterministic configurations are present. Random draw counts and invalid inputs are tested separately in [MoonBit regression tests](<../strategy_variants_test.mbt>).
- Freeze serialized input SHA-256 and preserve the first result even on mismatch. A mismatch or altered official expectation must exit nonzero. The new scope is separate from the existing frozen 93 / 4608 / 48 differential.

Run `node tools/strategy-variants.mjs` after installing the frozen development oracle. All decisions on the candidate side come from the compiled [MoonBit differential executable](<../cmd/differential/main.mbt>), not a JavaScript reimplementation.

## First reference failure and explicit v2 revision

Plan v1 input SHA-256 was `70a107de32c85b6d210a38bc1645dca219e38fd16dd88563cbb1dbd85736417f`. The MoonBit batch executed, but the unmodified Node core threw `TypeError: Cannot read properties of undefined (reading 'stickiness')` at `strategy.js:236`: its default strategy cannot evaluate nonempty variants when parameters is omitted. No completed v1 differential pass is claimed. The original [input](<../artifacts/strategy-variants-input.v1.json>), [source](<../artifacts/strategy-variants.v1-oracle-error.mjs>) and [failure record](<../artifacts/strategy-variants.initial.v1.json>) are retained in the repository; this is a reference-core limitation, not a hidden MoonBit mismatch.

Before re-execution, **plan v2** explicitly supplies `parameters: {}` on default strategies. All 64 contexts, configurations, weights, case IDs and official expectations are retained. The omitted-parameter robustness case stays in the MoonBit tests; v2 does not claim reference equivalence for it. New unexpected oracle errors are recorded per case and cause nonzero exit rather than skipping cases.

## Current integration status (2026-11-20)

The M1 implementation remains covered. The full evaluator now adds advanced constraints, segment handling, dependencies and public delta state application; wasm, wasm-gc and JS each execute **all 22 suites / 294 Pass / 0 Fail / 0 NotRun**. Integrated tests are **96/96 wasm, 81/81 wasm-gc and 81/81 JS**, including metrics and frozen independent Unicode regressions. [Four-target cloud CI](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44689082346) also executes the full 294 unchanged cases on Linux native, with [same-SHA public evidence](<../artifacts/ci-run-44689082346.json>). Windows native remains type checking only. Source `1f5cc6378948d1ac04655c64871e24d6bfbab665` now passes both [four-target SDK CI](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44690815957) and [wasm/native real-server acceptance](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44690815719) at the same SHA, with seven proposal decisions on actual server response snapshots. See the [current acceptance ledger](<ACCEPTANCE.md>), [delta contract](<DELTA.md>) and [metrics contract](<METRICS.md>).

## Historical M1 results (2026-11-18)

Plan v2 input SHA-256: `a37907e32a4978c90772a1323145359849a9d991475d1fdd588c7163b7834082`. The actual compiled JS MoonBit evaluator and unmodified Node core agree **11/11 official cases and 1536/1536 deterministic matrix comparisons**, with **0 oracle errors** and **0 oracle/spec disagreements**. Local tests pass wasm **43/43**, wasm-gc **33/33**, JavaScript **33/33**; Windows native type checking passes, runtime remains unverified. The public interfaces are unchanged. Existing local conformance has reached 104 Pass / 0 Fail / 190 NotRun on wasm, wasm-gc and JavaScript. This includes all 11 suite-16 cases, with no changes to upstream fixtures.

The source commit `25b13135f5cf9ed01c460dd3e587ab44ab9d5756` passed [cloud CI #5](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293) on wasm, wasm-gc, JavaScript and Linux native, including the 104-case conformance validator. Four current artifact metadata records match that SHA; their contents were not downloaded. The standalone application's complete JSON also passed **7/7** local MoonBit JS evaluations. Neither result implies a live-server test.

## Server and remaining boundaries

The server target is Unleash OSS v7.4.0, commit `77c5af4d991541a93b877ddac0554beaaf61c8c5`. Create strategy variants in that server's management configuration and fetch them through the backend Client API. Do not flatten them into deprecated feature-level variants. A representative A/B example is covered by the MoonBit regression above.

Pure evaluation success alone does not prove registration, token/environment selection, native networking or metrics. The independently executed [real-server harness](<REAL_SERVER.md>) now passes all twenty operations on both wasm and native, including actual registration, first-strategy/dependencies, two exact metrics database readbacks and same-client recovery. It also verifies a genuine 50/50 strategy and all seven application decisions on actual SDK response snapshots, not just singleton blue/gold variants. [Public server evidence](<../artifacts/ci-run-44690815719.json>) and [SDK evidence](<../artifacts/ci-run-44690815957.json>) bind both gates to the same full passing implementation SHA. Earlier failure records remain unchanged; this does not imply universal compatibility or production certification. [Unicode adjudication](<UNICODE.md>) retains the known Node-SDK divergence and adds independently frozen UTF-8 hash/API regressions.
