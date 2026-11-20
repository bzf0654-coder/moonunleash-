# Independent hash-reference dependency license record

These are **development reference tools only**, not SDK runtime dependencies.
All five exact package versions and full SRI values are frozen in the independent
[lockfile](<../../tools/hash-reference/pnpm-lock.yaml>); source hashes, registry gitHeads,
archive hashes and installed-file checks are in the [supply-chain audit](<../../artifacts/unicode-verdict.supply-chain.json>).
No implementation source is vendored here; installation directories and caches are ignored.

| Package | Declared license | Full published license text |
|---|---|---|
| murmur3hash-wasm@1.0.1 | ISC | [Unmodified license copy](<murmur3hash-wasm-LICENSE>) |
| nanoassert@2.0.0 | ISC | [Unmodified license copy](<nanoassert-LICENSE>) |
| fmix@1.0.0 | MIT | [Unmodified license copy](<fmix-LICENSE>) |
| murmur-32@1.0.0 | MIT | **Not present in its published tarball**; metadata declaration only |
| encode-utf8@2.0.0 | MIT | **Not present in its published tarball**; metadata declaration only |

The last two MIT declarations were verified against the exact
[murmur-32 registry record](https://registry.npmjs.org/murmur-32/1.0.0) and
[encode-utf8 registry record](https://registry.npmjs.org/encode-utf8/2.0.0).
Pinned GitHub `license` and `LICENSE` URLs also returned 404. We do not fabricate
an author/year notice or claim a missing upstream full text has been obtained.
The missing files are explicitly recorded as empty `publishedLicenseFiles` arrays
in the [audit](<../../artifacts/unicode-verdict.supply-chain.json>).
If redistributing those upstream implementation sources, resolve the complete
notices with their author; the current repository distributes pinned development
manifests and frozen hash evidence rather than those source packages.
