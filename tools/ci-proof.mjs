// Pure validation of public current-run GitHub check annotations. No network or SDK execution.
import assert from 'node:assert/strict';
import { baseline, image } from './server-provenance.mjs';
const operations = ['registered', 'baseline', 'off', 'off-seen', 'on', 'on-seen', 'persisted', 'stop',
  'outage-seen', 'start', 'recovered', 'off-again', 'off-again-seen', 'on-again', 'on-again-seen', 'final-persisted', 'complete'];
const before = { 'ci-parent': { yes: 2, no: 1, variants: { blue: 1 } }, 'ci-child': { yes: 4, no: 2, variants: { gold: 2, disabled: 1 } } };
const final = { 'ci-parent': { yes: 3, no: 1, variants: { blue: 1 } }, 'ci-child': { yes: 6, no: 3, variants: { gold: 4, disabled: 2 } } };
const hash = value => typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
export function validateProof(proof, mode, target, sha) {
  assert.equal(proof.sha, sha, 'proof must use the exact workflow source SHA');
  assert.equal(proof.target, target, 'proof must use the exact job target');
  if (mode === 'sdk') {
    assert.equal(proof.revision, '9ef6efa01feabeb699857192ad8106fd7d990235');
    for (const [key, value] of Object.entries({ hashesVerified: 24, passed: 294, failed: 0, notRun: 0, suites: 22, requiredSuites: 22 })) assert.equal(proof[key], value, key);
    assert.ok(hash(proof.reportSha256), 'report must have a SHA-256');
  } else {
    assert.equal(mode, 'real-server');
    assert.equal(proof.status, 'PASS');
    assert.equal(proof.sourceRevision, baseline.revision);
    assert.equal(proof.image, image);
    assert.equal(proof.config, baseline.config);
    assert.ok(hash(proof.containerId), 'actual same-container identity must exist');
    assert.match(proof.toolchain, /moon[\s\S]*moonc/);
    assert.match(proof.databaseVersion, /^PostgreSQL 15\./);
    assert.equal(proof.registrations, 1);
    assert.equal(proof.acceptedMetrics, 2);
    assert.equal(proof.seen304, true);
    assert.ok(Array.isArray(proof.distinctETags) && new Set(proof.distinctETags).size >= 5);
    assert.deepEqual(proof.operations, operations);
    assert.deepEqual(proof.persistedBeforeOutage, before);
    assert.deepEqual(proof.persistedFinal, final);
    assert.ok(hash(proof.resultSha256), 'result must have a SHA-256');
  }
  return proof;
}
