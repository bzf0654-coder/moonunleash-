import assert from 'node:assert/strict';
import { validateProof } from './ci-proof.mjs';
import { baseline, image } from './server-provenance.mjs';
const sha = 'a'.repeat(40), digest = 'b'.repeat(64);
const sdk = { sha, target: 'native', revision: '9ef6efa01feabeb699857192ad8106fd7d990235', hashesVerified: 24, passed: 294, failed: 0, notRun: 0, suites: 22, requiredSuites: 22, reportSha256: digest };
const real = { sha, target: 'wasm', status: 'PASS', sourceRevision: baseline.revision, image, config: baseline.config, containerId: digest,
  toolchain: 'moon 0.1\nmoonc v0.10', databaseVersion: 'PostgreSQL 15.20 (Debian)', registrations: 1, acceptedMetrics: 2, seen304: true,
  distinctETags: ['"1"', '"2"', '"3"', '"4"', '"5"'],
  parentDistinctETags: ['"1"', '"2"', '"3"', '"4"', '"5"'], recommendationCases: 7,
  operations: ['registered', 'recommendation', 'recommendation-off', 'recommendation-zero', 'baseline', 'off', 'off-seen', 'on', 'on-seen', 'persisted', 'stop', 'outage-seen', 'start', 'recovered', 'off-again', 'off-again-seen', 'on-again', 'on-again-seen', 'final-persisted', 'complete'],
  persistedBeforeOutage: { 'ci-parent': { yes: 2, no: 1, variants: { blue: 1 } }, 'ci-child': { yes: 4, no: 2, variants: { gold: 2, disabled: 1 } } },
  persistedFinal: { 'ci-parent': { yes: 3, no: 1, variants: { blue: 1 } }, 'ci-child': { yes: 6, no: 3, variants: { gold: 4, disabled: 2 } } }, resultSha256: digest };
assert.equal(validateProof(sdk, 'sdk', 'native', sha), sdk);
assert.equal(validateProof(real, 'real-server', 'wasm', sha), real);
let rejected = 0;
function reject(original, mode, edit) {
  const copy = structuredClone(original); edit(copy);
  assert.throws(() => validateProof(copy, mode, original.target, sha)); rejected++;
}
for (const edit of [p => { delete p.sha; }, p => { p.sha = 'c'.repeat(40); }, p => { p.target = 'js'; },
  p => { p.passed = 293; }, p => { p.failed = 1; }, p => { p.notRun = 1; }, p => { p.hashesVerified = 23; },
  p => { p.requiredSuites = 21; }, p => { p.suites = 21; }, p => { p.revision = sha; }, p => { p.reportSha256 = 'bad'; }]) reject(sdk, 'sdk', edit);
for (const edit of [p => { p.sha = null; }, p => { p.target = 'native'; }, p => { p.status = 'FAIL'; },
  p => { p.sourceRevision = sha; }, p => { p.image = 'unleashorg/unleash-server:latest'; }, p => { p.config = 'bad'; },
  p => { delete p.containerId; }, p => { p.toolchain = ''; }, p => { p.databaseVersion = 'PostgreSQL 16'; },
  p => { p.registrations = 0; }, p => { p.acceptedMetrics = 1; }, p => { p.seen304 = false; },
  p => { delete p.recommendationCases; }, p => { p.recommendationCases = 6; },
  p => { delete p.parentDistinctETags; }, p => { p.parentDistinctETags = Array(5).fill('same'); },
  p => { p.distinctETags = Array(5).fill('same'); }, p => { p.operations.pop(); }, p => { p.operations.reverse(); },
  p => { p.persistedBeforeOutage['ci-child'].yes++; }, p => { p.persistedFinal['ci-parent'].variants.blue++; }, p => { delete p.resultSha256; }]) reject(real, 'real-server', edit);
console.log(`Public CI proof validation: 2 valid summaries, ${rejected} corrupted/missing evidence summaries rejected.`);
