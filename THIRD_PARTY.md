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
- Modified adaptations are explicitly identified in the source headers of [sdk.mbt](<sdk.mbt>), [variants.mbt](<variants.mbt>), [dependencies.mbt](<dependencies.mbt>), the legacy adapter in [ip.mbt](<ip.mbt>), and [hash.mbt](<hash.mbt>). Changes include MoonBit translation, strict private snapshots, bounded input validation, the documented UTF-8 hashing policy, and single-evaluation strategy-level variant selection. These are not unmodified copies of the Node implementation.
- Reference paths: [normalization](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/util.ts), [variants](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/variant.ts), [constraints](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/strategy.ts), [client context defaults](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/unleash.ts).
- MoonBit hashing normalization, variant stickiness/selection and constraint behavior are adaptations based on these publicly documented implementations and the client specification, not third-party runtime calls. No Node SDK is embedded in the MoonBit library.
- Differential oracle is now pinned to npm `unleash-client@6.12.2`, reported gitHead `dc113ce745f6c0efe65ae3f6b49a439144ac4aa3`, with tarball integrity and frozen transitive dependencies in the [reference lockfile](<tools/reference/pnpm-lock.yaml>). Earlier design inspection used main on 2026-11-17; that fact is not retroactively a pinned execution.
- The development-only reference is actually called by the differential supervisor, not by production MoonBit code. See the [execution plan](<docs/DIFFERENTIAL_PLAN.md>) and [results including Unicode mismatches](<docs/DIFFERENTIAL_RESULTS.md>). It is not an assertion of complete cross-SDK compatibility.

## MurmurHash3

The x86_32 mixing constants and public algorithm originate in Austin Appleby's MurmurHash3 (SMHasher, public domain). The implementation in [hash.mbt](<hash.mbt>) is written in MoonBit with explicit wrapping unsigned operations. Its relation to Unleash normalization is separately attributed above.

## MoonBit-native regular expression dependency

- Exact production MoonBit module: **moonbitlang/regexp@0.3.7**, [upstream repository](https://github.com/moonbitlang/regexp.mbt), Apache-2.0, **Copyright 2025 International Digital Economy Academy**. This is a MoonBit VM compiled into the SDK's target, not a Node production dependency.
- The unmodified full [license](<third_party/moonbitlang-regexp/LICENSE>) and [upstream NOTICE](<third_party/moonbitlang-regexp/NOTICE>) are retained. The NOTICE includes the Russ Cox/Google re1 and Go Authors BSD attribution/disclaimers and must accompany redistribution.
- SHA-256: license `25cca5bcb2efbfcf33f8f00c7741a35045c75f84e1f017a03dd457db8fcbaeea`; NOTICE `9c2a70c4108965baec52ca2f6350fe401251f8407a3b596ed87e9e6c2e41050b`. Original/copy digests were compared.
- Upstream source is not modified. The SDK-owned [syntax adapter](<regex.mbt>) supplies RE2-facing translations and rejects backreferences/look-around; [regex scope](<docs/REGEX.md>) records bounds, the alpha API and installation stops. The older 0.3.5 installation never reached compilation and is not the shipped dependency.

## Development-only independent Unicode references

The separate [hash-reference environment](<tools/hash-reference/package.json>) pins `murmur3hash-wasm@1.0.1` (ISC), `murmur-32@1.0.0` (MIT metadata), `nanoassert@2.0.0` (ISC), `fmix@1.0.0` (MIT), and `encode-utf8@2.0.0` (MIT metadata). They generate and verify explicit UTF-8 byte Golden evidence; none is linked into production MoonBit code. See the [audit and original license records](<third_party/hash-reference/README.md>) and [Unicode methodology](<docs/UNICODE.md>).

Full unmodified published license texts are retained for the two ISC packages and fmix. The exact murmur-32 and encode-utf8 tarballs and fixed source commits did **not** supply standalone full LICENSE files; the MIT metadata is recorded without inventing copyright/year or claiming a copied license exists. Their implementation sources are not vendored here. The [supply-chain audit](<artifacts/unicode-verdict.supply-chain.json>) preserves exact versions, SRI, source and license-copy checks, including this attribution gap.

## Gregorian civil-date conversion

The UTC formatter in [metrics.mbt](<metrics.mbt>) adapts Howard Hinnant's [`civil_from_days` algorithm](<https://howardhinnant.github.io/date_algorithms.html#civil_from_days>), specialized to validated nonnegative Unix milliseconds through year 9999. The article's [Summary](<https://howardhinnant.github.io/date_algorithms.html#Summary>) donates the formulas to the public domain. This attribution concerns the algorithm article, not a copied file from the separately MIT-licensed `date` library. MoonBit validation, formatting and bounded metric accumulation are project additions.

## MoonBit core

The project imports the installed MoonBit standard library. No vendored standard-library code is included. Record the compiler/core version used when reproducing tests; dependency licenses remain with their respective projects.

## Authorship and use of AI

The project is being developed with AI-assisted implementation and testing at the user's direction. Development history records actual milestones; it is not a claim of manual-only authorship. The participant remains responsible for understanding the implementation and for final quality and submission statements.
