// Optional network audit: pinned registry metadata + tarball SRI + installed files.
// Never installs packages or executes lifecycle scripts. --record initializes once.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';
import { readFile, writeFile } from 'node:fs/promises';
import { packages, provenance } from './reference.mjs';
const record = process.argv.length === 3 && process.argv[2] === '--record';
assert(process.argv.length === 2 || record, 'Usage: node audit-packages.mjs [--record]');
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
async function download(url) {
  const response = await fetch(url,{signal:AbortSignal.timeout(30000)});
  assert.equal(response.status,200,`Fetch failed: ${url}`);
  return Buffer.from(await response.arrayBuffer());
}
function tarFiles(tar) {
  const files = new Map();
  for (let offset=0;offset+512<=tar.length;) {
    const header=tar.subarray(offset,offset+512);
    if (header.every(b=>b===0)) break;
    const text=(start,end)=>header.subarray(start,end).toString('utf8').split('\0')[0];
    const name=text(0,100), prefix=text(345,500);
    const size=parseInt(text(124,136).trim(),8);
    assert(Number.isSafeInteger(size) && size>=0,'Unsupported tar size');
    const start=offset+512;
    assert(start+size<=tar.length,'Truncated tar entry');
    const type=header[156];
    if (type===0 || type===48) files.set(prefix?`${prefix}/${name}`:name,tar.subarray(start,start+size));
    offset=start+Math.ceil(size/512)*512;
  }
  return files;
}
const results=[];
for (const p of packages) {
  const registry=`https://registry.npmjs.org/${p.name}/${p.version}`;
  const metadata=JSON.parse(await download(registry));
  assert.equal(metadata.name,p.name); assert.equal(metadata.version,p.version);
  assert.equal(metadata.gitHead,p.gitHead,`gitHead drift: ${p.name}`);
  assert.equal(metadata.license,p.license,`license metadata drift: ${p.name}`);
  assert.equal(metadata.dist.integrity,p.integrity,`Registry SRI drift: ${p.name}`);
  assert.equal(new URL(metadata.dist.tarball).origin,'https://registry.npmjs.org');
  const archive=await download(metadata.dist.tarball);
  const actualIntegrity='sha512-'+createHash('sha512').update(archive).digest('base64');
  assert.equal(actualIntegrity,p.integrity,`Downloaded tarball SRI mismatch: ${p.name}`);
  const entries=tarFiles(gunzipSync(archive));
  for (const f of ['package.json',...p.files]) {
    const fromTar=entries.get(`package/${f}`);
    assert(fromTar,`Missing published file: ${p.name}/${f}`);
    const installed=await readFile(new URL(`node_modules/${p.name}/${f}`,import.meta.url));
    assert(installed.equals(fromTar),`Installed file differs from SRI-checked tarball: ${p.name}/${f}`);
  }
  const licenses=[...entries.keys()].filter(name=>/(?:^|\/)(?:licen[cs]e|copying)(?:\.[^/]*)?$/i.test(name));
  if (['murmur3hash-wasm','nanoassert','fmix'].includes(p.name)) {
    const copy=await readFile(new URL(`../../third_party/hash-reference/${p.name}-LICENSE`,import.meta.url));
    assert(copy.equals(entries.get('package/LICENSE')),`License copy differs from SRI-checked publication: ${p.name}`);
  }
  results.push({name:p.name,version:p.version,registry,gitHead:metadata.gitHead,license:metadata.license,
    integrity:p.integrity,tarball:metadata.dist.tarball,tarballSha256:sha256(archive),
    installedFilesMatchTarball:true,publishedLicenseFiles:licenses,
    sourceSha256:provenance.find(x=>x.name===p.name).files});
  console.log(`SRI and installed files verified: ${p.name}@${p.version}`);
}
const report={schemaVersion:1,registry:'https://registry.npmjs.org/',lifecycleScriptsExecuted:false,packages:results};
const reportUrl=new URL('../../artifacts/unicode-verdict.supply-chain.json',import.meta.url);
const expected=JSON.stringify(report,null,2)+'\n';
let current;
try { current=await readFile(reportUrl,'utf8'); } catch (e) { if (e.code!=='ENOENT') throw e; }
if (current===undefined) {
  assert(record,'Missing audit report: use --record for explicit initialization');
  await writeFile(reportUrl,expected,{flag:'wx'});
} else assert.equal(current.replaceAll('\r\n','\n'),expected,'Frozen supply-chain audit drift');
console.log('Supply-chain audit passed for all five pinned runtime packages.');
