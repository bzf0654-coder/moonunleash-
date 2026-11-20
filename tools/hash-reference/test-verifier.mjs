// Read-only guard tests. All deliberate corruption stays in memory; never edit
// Golden or Moon sources while the integrating agent is compiling/formatting.
import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { referenceHash, utf8Bytes } from './reference.mjs';
const root=new URL('../../',import.meta.url);
// The root may format Moon concurrently; snapshot only the three immutable JSONs.
const paths=['artifacts/unicode-verdict.golden.v1.json','artifacts/unicode-verdict.initial.v1.json',
  'artifacts/unicode-verdict.json'];
async function snapshot() {
  return Promise.all(paths.map(async path=>({path,
    sha256:createHash('sha256').update(await readFile(new URL(path,root))).digest('hex'),
    mtimeMs:(await stat(new URL(path,root))).mtimeMs})));
}
const before=await snapshot();
const {moonTokens}=await import('../unicode-verdict.mjs'); // Executes default read-only verification.
assert.deepEqual(await snapshot(),before,'Default verifier wrote frozen files');
const source=await readFile(new URL('unicode_generated_wbtest.mbt',root),'utf8');
const tokens=moonTokens(source);
let negativeChecks=0;
function rejectChange(changed) {
  assert.notEqual(changed,source,'Bad drift-test setup');
  assert.throws(()=>assert.deepEqual(moonTokens(changed),tokens));
  negativeChecks++;
}
rejectChange(source.replace('1483014240U','1483014241U'));
rejectChange(source.replace('"expected":false','"expected":true'));
rejectChange(source.replace('state.evaluate(name, ctx).enabled','true'));
rejectChange(source.replace('assert_eq(murmur32(text, 86028157U), seed_variant, msg=text)',''));
assert.deepEqual(moonTokens(source.replaceAll('assert_eq(', 'assert_eq(  ')),tokens);
assert.deepEqual(moonTokens(source.replace('msg=text)','msg=text,)')),tokens);
for (const seed of [-1,0.5,0x100000000,NaN,Infinity]) {
  assert.throws(()=>referenceHash(new Uint8Array(),seed)); negativeChecks++;
}
assert.throws(()=>referenceHash(new Uint8Array(65537),0)); negativeChecks++;
assert.throws(()=>referenceHash('foo',0)); negativeChecks++;
assert.throws(()=>utf8Bytes('\ud800')); negativeChecks++;
const bytes=utf8Bytes('full block:🌍:é');
const original=Buffer.from(bytes);
assert.equal(referenceHash(bytes,86028157),referenceHash(bytes,86028157));
assert.deepEqual(bytes,original,'Secondary reference input mutation leaked');
assert.deepEqual(await snapshot(),before,'Guard tests wrote frozen files');
console.log(JSON.stringify({status:'passed',negativeChecks,formatterOnlyChecks:2,
  readOnlyFilesChecked:paths.length,inputMutationGuard:true,allCorruptionInMemory:true},null,2));
