# Native regular-expression constraints

Evaluation uses **moonbitlang/regexp@0.3.7**, a pinned Apache-2.0 MoonBit VM library, not JavaScript RegExp, Node Unleash, a subprocess or a platform-specific production FFI. The upstream [API/implementation](https://github.com/moonbitlang/regexp.mbt) is alpha; the module version is fixed and all SDK backends must be tested before release.

The RE2-facing adapter provides ASCII POSIX named classes (including their complements), ASCII Perl whitespace, numeric octal and hex escapes, quoted literals, absolute anchors, scoped and enclosing-remainder inline i/m/s flags, and Boolean-equivalent U flags. It rejects look-around and backreferences before compilation; the library's backreference-enabled exponential VM path is not used. The original configuration and oracle inputs are not rewritten by the differential harness: translation is ordinary SDK implementation code.

Resource guards: input pattern at most 4096 UTF-16 units, at most 64 nested explicit/synthetic scopes, counted repeat at most 1000 and a conservative expanded compilation-cost ceiling of 20000. Rejected/invalid patterns evaluate false as operator results; normal constraint inversion then follows the protocol. No timing/performance claim is made from these correctness tests.

A snapshot eagerly caches at most 100 distinct pattern/flag combinations (including invalid results); excess patterns remain supported through bounded on-demand compilation without retaining additional programs. Snapshot caches are not mutated during evaluation. Missing or non-string context values are not coerced to strings.

This is not a claim of equivalence with every RE2 extension. Unicode general categories are delegated to the pinned VM; script-property aliases and remaining dialect edges need explicit adjudication rather than silent compatibility claims. Required unchanged suite 21, extra regressions, four-backend execution and same-source CI are the evidence gates.

## Observed validation (2026-11-20)

All **37 unchanged suite-21 cases** passed on wasm, wasm-gc and JavaScript. Five additional direct regressions cover translation/dialect boundaries, invalid/budgeted patterns, bounded caching with a 101st uncached pattern, unscoped flags across alternation and case-insensitive escaped literals. The complete SDK now passes all **294 official cases** on those runtimes, with **96/81/81** MoonBit tests including other SDK suites. [Four-backend cloud execution](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44689082346) now also passes the unchanged 294 cases on Linux native, with [verified public summary/report digests](<../artifacts/ci-run-44689082346.json>) for every target. Windows native is still type checking only. The first compile stop on deprecated StringBuilder constructors was corrected without changing expectations. This is correctness evidence, not a latency/throughput or universal RE2-equivalence claim.

## Dependency installation history

- The first attempt to add 0.3.5 stopped at the user-level registry write boundary. The approved exact retry then failed because a configured localhost proxy was unavailable.
- A process-local empty Git configuration override failed because empty environment values were removed; it changed no global Git/proxy settings.
- A process-local `NO_PROXY=*` successfully reached the registry, but 0.3.5 stopped before compilation because its legacy module manifest is unsupported by the installed toolchain. No metadata/source migration or expectation changes were made to that release.
- Registry search identified 0.3.7; the exact 0.3.7 installation succeeded with current-format manifests. This is the actual pinned dependency, not a claim that the stopped 0.3.5 build passed. The proxy override was scoped to individual commands only.
