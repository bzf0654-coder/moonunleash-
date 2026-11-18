# Third-party materials and implementation references

## Unleash Client Specification

- Repository: https://github.com/Unleash/client-specification
- Pinned revision: `9ef6efa01feabeb699857192ad8106fd7d990235`
- License: Apache-2.0; original full license retained in [the upstream license](<tests/fixtures/upstream/LICENSE>).
- Original specification JSON files are redistributed without changing expected values.
- SHA-256 [manifest](<tests/fixtures/upstream/manifest.json>).
- Generated MoonBit test bindings reproduce these fixtures as text. The fixtures and generated representations retain the upstream Apache-2.0 license.

## Unleash Node SDK

- Repository: https://github.com/Unleash/unleash-node-sdk
- License: Apache-2.0. The project [license](<LICENSE>) contains the Apache-2.0 terms.
- Original copyright notice: **Copyright 2020 Bricks Software AS**.
- The complete original license, including that copyright notice, is retained in [the SDK license](<third_party/unleash-node-sdk/LICENSE>). The project-supplied [NOTICE](<NOTICE>) records the attribution; it is not represented as an upstream NOTICE file.
- Modified adaptations are explicitly identified in the source headers of [sdk.mbt](<sdk.mbt>), [variants.mbt](<variants.mbt>), and [hash.mbt](<hash.mbt>). Changes include MoonBit translation, strict private snapshots, bounded input validation, the documented UTF-8 hashing policy, and single-evaluation strategy-level variant selection. These are not unmodified copies of the Node implementation.
- Reference paths: [normalization](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/util.ts), [variants](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/variant.ts), [constraints](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/strategy.ts), [client context defaults](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/unleash.ts).
- MoonBit hashing normalization, variant stickiness/selection and constraint behavior are adaptations based on these publicly documented implementations and the client specification, not third-party runtime calls. No Node SDK is embedded in the MoonBit library.
- Differential oracle is now pinned to npm `unleash-client@6.12.2`, reported gitHead `dc113ce745f6c0efe65ae3f6b49a439144ac4aa3`, with tarball integrity and frozen transitive dependencies in the [reference lockfile](<tools/reference/pnpm-lock.yaml>). Earlier design inspection used main on 2026-11-17; that fact is not retroactively a pinned execution.
- The development-only reference is actually called by the differential supervisor, not by production MoonBit code. See the [execution plan](<docs/DIFFERENTIAL_PLAN.md>) and [results including Unicode mismatches](<docs/DIFFERENTIAL_RESULTS.md>). It is not an assertion of complete cross-SDK compatibility.

## MurmurHash3

The x86_32 mixing constants and public algorithm originate in Austin Appleby's MurmurHash3 (SMHasher, public domain). The implementation in [hash.mbt](<hash.mbt>) is written in MoonBit with explicit wrapping unsigned operations. Its relation to Unleash normalization is separately attributed above.

## MoonBit core

The project imports the installed MoonBit standard library. No vendored standard-library code is included. Record the compiler/core version used when reproducing tests; dependency licenses remain with their respective projects.

## Authorship and use of AI

The project is being developed with AI-assisted implementation and testing at the user's direction. Development history records actual milestones; it is not a claim of manual-only authorship. The participant remains responsible for understanding the implementation and for final quality and submission statements.
