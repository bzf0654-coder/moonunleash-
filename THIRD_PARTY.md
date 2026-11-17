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
- Copyright: Unleash SDK contributors.
- Reference paths: `src/strategy/util.ts`, `src/variant.ts`, `src/strategy/strategy.ts`.
- MoonBit hashing normalization, variant stickiness/selection and constraint behavior are adaptations based on these publicly documented implementations and the client specification, not third-party runtime calls. No Node SDK is embedded in the MoonBit library.
- Reference commit for differential testing still needs to be pinned before that verification is claimed; current inspection used the main branch on 2026-11-17. Compatibility fixtures are independently pinned above.

## MurmurHash3

The x86_32 mixing constants and public algorithm originate in Austin Appleby's MurmurHash3 (SMHasher, public domain). The implementation in [hash.mbt](<hash.mbt>) is written in MoonBit with explicit wrapping unsigned operations. Its relation to Unleash normalization is separately attributed above.

## MoonBit core

The project imports the installed MoonBit standard library. No vendored standard-library code is included. Record the compiler/core version used when reproducing tests; dependency licenses remain with their respective projects.

## Authorship and use of AI

The project is being developed with AI-assisted implementation and testing at the user's direction. Development history records actual milestones; it is not a claim of manual-only authorship. The participant remains responsible for understanding the implementation and for final quality and submission statements.
