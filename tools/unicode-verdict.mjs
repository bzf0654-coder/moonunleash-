// Default: read-only verification. --generate: initialize missing frozen files only.
// Golden is constructed and frozen BEFORE importing/evaluating the old Node oracle.
// No Moon process, Moon output, or pid UTF8->Latin1 bridge is used as a reference.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { isDeepStrictEqual } from 'node:util';
import { referenceHash, utf8Bytes, provenance, selfTest } from './hash-reference/reference.mjs';
import { buildCorpus } from './generate-differential.mjs';
const root = new URL('../', import.meta.url);
const generate = process.argv.length === 3 && process.argv[2] === '--generate';
assert(process.argv.length === 2 || generate, 'Usage: node tools/unicode-verdict.mjs [--generate]');
const sha = data => createHash('sha256').update(data).digest('hex');
const encoded = value => JSON.stringify(value, null, 2) + '\n';
const read = path => readFile(new URL(path, root));
const json = async path => JSON.parse(await read(path));
const protectedFiles = {
  'tools/generate-differential.mjs':'17bd45b1a12f69c9129a590ee9557988452e8c9f1224a66b0cfc7eb3c93bcc8b',
  'tools/reference/pnpm-lock.yaml':'18f136de5c0b1044e1a713e1ec516ff2b9e8801905efa2be2c847e09e27907b9',
  'artifacts/differential.initial.v1.json':'6f6f9eba3ce515a4a7eef4c36cd201f9f27d51622cc978ea5e2b3976281cef6d',
  'artifacts/differential.json':'6f6f9eba3ce515a4a7eef4c36cd201f9f27d51622cc978ea5e2b3976281cef6d',
};
for (const [path, digest] of Object.entries(protectedFiles)) {
  assert.equal(sha(await read(path)), digest, `Protected original evidence changed: ${path}`);
}
const fixtureManifest = await json('tests/fixtures/upstream/manifest.json');
for (const f of fixtureManifest.files) assert.equal(sha(await read(`tests/fixtures/upstream/${f.name}`)), f.sha256);
const required = new Set(['01','02','03','04','05','07','08','09','10','11','12','18']);
const fixtures = [];
for (const file of await json('tests/fixtures/upstream/index.json')) {
  if (required.has(file.slice(0,2))) fixtures.push({file,spec:await json(`tests/fixtures/upstream/${file}`)});
}
const corpus = buildCorpus(fixtures);
const inputSha256 = sha(JSON.stringify(corpus));
assert.equal(inputSha256, '7d801d96ca2820e8ed81e850d2d22c221374dcdd10e985a1ec4b80bf10ed93a8', 'Original corpus drift');
const original = corpus.groups.find(g => g.id === 'unicode-hash-diagnostic-v1');
assert.equal(original.cases.length, 48);
const referenceTests = selfTest();

const variants = [{name:'control',weight:250},{name:'treatment',weight:750,payload:{type:'string',value:'blue'}}];
const additional = {id:'unicode-isolated-components-v1',state:{version:2,features:[]},cases:[]};
for (const [i,groupId] of ['group-é','group-e\u0301','group-🌍','共享组'].entries()) {
  additional.state.features.push({name:`ascii-feature-${i}`,enabled:true,strategies:[{name:'flexibleRollout',parameters:{rollout:'37',groupId,stickiness:'userId'}}]});
}
for (const name of ['全局-é','全局-e\u0301','全局-🌍','全局-用户']) {
  additional.state.features.push({name,enabled:true,strategies:[{name:'default'}],variants});
}
for (const [i,userId] of ['ascii-user','é','e\u0301','😊'].entries()) {
  for (const f of additional.state.features) for (const kind of ['boolean','variant']) {
    additional.cases.push({id:`unicode-extra:${i}:${f.name}:${kind}`,name:f.name,context:{userId},kind});
  }
}
const groups = [original,additional];
const primitiveMap = new Map();
function primitive(text, origin) {
  const existing = primitiveMap.get(text);
  if (existing) { if (!existing.origins.includes(origin)) existing.origins.push(origin); return existing; }
  const bytes = utf8Bytes(text);
  const value = {id:`utf8-${primitiveMap.size}`,text,origins:[origin],utf8Hex:bytes.toString('hex'),
    byteLength:bytes.byteLength,tailLength:bytes.byteLength%4,
    hashes:[0,86028157].map(seed => {
      const uint32 = referenceHash(bytes,seed);
      return {seed,uint32,hex:uint32.toString(16).padStart(8,'0'),bucket100:uint32%100+1,bucket1000:uint32%1000+1};
    })};
  primitiveMap.set(text,value);
  return value;
}
function hashTrace(text, seed, scale, origin) {
  const vector = primitive(text,origin);
  const hash = vector.hashes.find(h=>h.seed === seed);
  return {primitiveId:vector.id,text,utf8Hex:vector.utf8Hex,byteLength:vector.byteLength,
    seed,uint32:hash.uint32,scale,bucket:hash.uint32%scale+1};
}
function expectedCase(group, c) {
  // Deliberately restricted mathematical policy, not a second SDK implementation.
  const f = group.state.features.find(f => f.name === c.name);
  assert(f.enabled && f.strategies.length === 1 && c.context.userId);
  const s = f.strategies[0];
  let featureEnabled, trace;
  if (s.name === 'flexibleRollout') {
    assert.deepEqual(Object.keys(s.parameters).sort(),['groupId','rollout','stickiness']);
    assert.equal(s.parameters.rollout,'37'); assert.equal(s.parameters.stickiness,'userId');
    trace = {...hashTrace(`${s.parameters.groupId}:${c.context.userId}`,0,100,c.id),rule:'bucket <= 37'};
    featureEnabled = trace.bucket <= 37;
  } else {
    assert.equal(s.name,'default');
    featureEnabled = true;
    trace = {rule:'default strategy is enabled; this Boolean does not hash'};
  }
  if (c.kind === 'boolean') return {...c,expected:featureEnabled,trace};
  assert.equal(c.kind,'variant');
  if (!f.variants?.length) {
    return {...c,expected:{name:'disabled',enabled:false,feature_enabled:featureEnabled},
      trace:{...trace,rule:'no variants: disabled variant, feature_enabled propagates rollout Boolean'}};
  }
  assert.deepEqual(f.variants,variants);
  trace = {...hashTrace(`${f.name}:${c.context.userId}`,86028157,1000,c.id),rule:'1..250 control; 251..1000 treatment'};
  const selected = trace.bucket <= 250 ? variants[0] : variants[1];
  return {...c,expected:{name:selected.name,enabled:true,feature_enabled:true,...(selected.payload?{payload:selected.payload}:{})},trace};
}
const expectedGroups = groups.map(g => ({id:g.id,state:g.state,cases:g.cases.map(c=>expectedCase(g,c))}));
for (const text of ['', 'foo', 'hello', 'a\u0000b', 'a:b:c', 'checkout:é', 'checkout:e\u0301', 'checkout:😊']) primitive(text,'primitive-anchor');
for (const base of ['尾部🌍:é','尾部🌍:e\u0301']) for (let n=0;n<4;n++) primitive(base+'x'.repeat(n),'full-block-plus-tail-0..3');
assert.deepEqual([...new Set([...primitiveMap.values()].filter(v=>v.origins.includes('full-block-plus-tail-0..3')).map(v=>v.tailLength))].sort(),[0,1,2,3]);
const candidateGolden = {
  schemaVersion:1,policy:'MurmurHash3_x86_32(UTF8(group + ":" + stickyId), uint32 seed)',
  encoding:{normalization:'none; NFC and NFD remain distinct',malformedUtf16:'excluded: reject before UTF8 encoding',endianness:'little-endian',unsignedResult:true},
  provenance:{nodeMajor:24,inputSha256,protectedFiles,references:provenance,selfTests:referenceTests,
    candidateOutputsUsed:false,legacyBridgeUsed:false},
  primitiveVectors:[...primitiveMap.values()],groups:expectedGroups,
};
async function freezeOrCheck(path, value) {
  let current;
  try { current = await readFile(new URL(path,root),'utf8'); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  const expected = encoded(value);
  if (current !== undefined) assert.equal(current.replaceAll('\r\n','\n'),expected, `Frozen artifact drift: ${path}; never regenerate to clear a failure`);
  else {
    assert(generate, `Missing frozen artifact: ${path}; initialize explicitly with --generate`);
    await writeFile(new URL(path,root),expected,{flag:'wx'});
  }
}
const goldenPath = 'artifacts/unicode-verdict.golden.v1.json';
await freezeOrCheck(goldenPath,candidateGolden);
// Read back the on-disk Golden; subsequent evaluation cannot supply expected data.
const golden = await json(goldenPath);
assert.deepEqual(golden,candidateGolden);
// Normalize serialization to LF, so checkout line endings are not runtime provenance.
const goldenSha256 = sha(encoded(golden));
console.log(`Golden frozen/verified before any oracle evaluation: ${goldenSha256}`);

function moonString(s) {
  return JSON.stringify(s).replace(/\\u([0-9a-f]{4})/gi,'\\u{$1}');
}
function renderMoon(golden) {
  const rows = golden.primitiveVectors.map(v=>`      (${moonString(v.text)}, ${v.hashes[0].uint32}U, ${v.hashes[1].uint32}U),`).join('\n');
  const api = golden.groups.map(g=>({id:g.id,state:g.state,cases:g.cases.map(({id,name,context,kind,expected})=>({id,name,context,kind,expected}))}));
  return `// Generated by tools/unicode-verdict.mjs from independently frozen Golden.\n// Golden SHA256: ${goldenSha256}\n// Formatter-only whitespace/trailing commas are accepted by the drift check.\n\n///|\ntest "independent Unicode UTF8 primitive Golden" {\n  for\n    (text, seed0, seed_variant) in [\n${rows}\n    ] {\n    assert_eq(murmur32(text, 0U), seed0, msg=text)\n    assert_eq(murmur32(text, 86028157U), seed_variant, msg=text)\n  }\n}\n\n///|\nfn unicode_verdict_field(value : @json.Json, key : String) -> @json.Json {\n  match value {\n    Object(fields) => fields.get(key).unwrap_or(@json.null)\n    _ => @json.null\n  }\n}\n\n///|\nfn unicode_verdict_text(value : @json.Json) -> String raise {\n  guard value is String(text) else { fail("expected generated Unicode text") }\n  text\n}\n\n///|\ntest "independent Unicode Golden through Snapshot public evaluation API" {\n  let source =\n    #|${JSON.stringify(api)}\n  guard @json.parse(source) is Array(groups) else {\n    fail("expected generated Unicode groups")\n  }\n  let mut count = 0\n  for group in groups {\n    let state = Snapshot::parse(unicode_verdict_field(group, "state").stringify())\n    guard unicode_verdict_field(group, "cases") is Array(cases) else {\n      fail("expected generated Unicode cases")\n    }\n    for c in cases {\n      let name = unicode_verdict_text(unicode_verdict_field(c, "name"))\n      let ctx = Context::parse(unicode_verdict_field(c, "context").stringify())\n      let actual = if unicode_verdict_text(unicode_verdict_field(c, "kind")) == "variant" {\n        state.get_variant(name, ctx).to_json()\n      } else {\n        @json.Json::boolean(state.evaluate(name, ctx).enabled)\n      }\n      assert_eq(\n        actual,\n        unicode_verdict_field(c, "expected"),\n        msg=unicode_verdict_text(unicode_verdict_field(c, "id")),\n      )\n      count = count + 1\n    }\n  }\n  assert_eq(count, ${api.flatMap(g=>g.cases).length})\n}\n`;
}
// Lexical comparison preserves strings/raw JSON and every substantive code token,
// while allowing moon fmt whitespace and optional trailing-comma changes.
export function moonTokens(source) {
  const tokens=[];
  for (const line of source.replaceAll('\r\n','\n').split('\n')) {
    if (line.trimStart().startsWith('#|')) { tokens.push(`RAW:${line.slice(line.indexOf('#|')+2)}`); continue; }
    const lineTokens=line.match(/"(?:\\.|[^"\\])*"|\/\/.*|[A-Za-z_][A-Za-z_0-9]*|[0-9]+|[^\s]/g)??[];
    for (const token of lineTokens) { if (token.startsWith('//')) break; tokens.push(token); }
  }
  return tokens.filter((t,i)=>!(t===',' && [')',']','}'].includes(tokens[i+1])));
}
const generatedMoon = renderMoon(golden);
const moonPath='unicode_generated_wbtest.mbt';
try {
  const current = await readFile(new URL(moonPath,root),'utf8');
  assert.deepEqual(moonTokens(current),moonTokens(generatedMoon),'Generated Moon regression drift');
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
  assert(generate,'Missing Moon regression: initialize explicitly with --generate');
  await writeFile(new URL(moonPath,root),generatedMoon,{flag:'wx'});
}

// Only now load the frozen, unmodified Node6.12.2 evaluator. Never rebind its hash.
const require = createRequire(new URL('tools/reference/package.json',root));
assert.equal(require('unleash-client/package.json').version,'6.12.2');
const Client = require('unleash-client/lib/client').default;
const { defaultStrategies } = require('unleash-client/lib/strategy');
const toggles = new Map(original.state.features.map(f=>[f.name,f]));
const oracle = new Client({getToggle:name=>toggles.get(name),getSegment:()=>undefined},defaultStrategies);
oracle.on('error',error=>{throw error;});
const first = await json('artifacts/differential.initial.v1.json');
const oldRecords = new Map(first.cases.filter(c=>c.profile==='unicode-diagnostic').map(c=>[c.id,c.node]));
function normalizeVariant(v) {
  return {name:v.name,enabled:v.enabled,feature_enabled:v.feature_enabled,...(v.payload===undefined?{}:{payload:v.payload})};
}
const records = golden.groups[0].cases.map(c => {
  const actual = c.kind==='variant' ? normalizeVariant(oracle.getVariant(c.name,c.context)) : oracle.isEnabled(c.name,c.context,()=>false);
  assert.deepEqual(actual,oldRecords.get(c.id),`Unmodified Node oracle changed from first report: ${c.id}`);
  const matched = isDeepStrictEqual(c.expected,actual);
  let legacyTrace;
  if (c.trace.text !== undefined) {
    // Independent hash of explicit legacy low-byte input: explanatory only.
    // This is NOT a patched pid call and NOT a source of the UTF8 Golden.
    const bytes = Buffer.from(Array.from({length:c.trace.text.length},(_,i)=>c.trace.text.charCodeAt(i)&0xff));
    const uint32 = referenceHash(bytes,c.trace.seed);
    legacyTrace = {encoding:'one low byte per UTF16 code unit, not UTF8 or UTF16LE',hex:bytes.toString('hex'),byteLength:bytes.length,
      uint32,seed:c.trace.seed,scale:c.trace.scale,bucket:uint32%c.trace.scale+1};
    const explained = c.kind==='boolean' ? legacyTrace.bucket<=37 : c.name==='unicode-rollout' ?
      {name:'disabled',enabled:false,feature_enabled:legacyTrace.bucket<=37} :
      legacyTrace.bucket<=250 ? {name:'control',enabled:true,feature_enabled:true} :
      {name:'treatment',enabled:true,feature_enabled:true,payload:{type:'string',value:'blue'}};
    assert.deepEqual(actual,explained,`Legacy byte mechanism does not explain Node: ${c.id}`);
  }
  const reason = matched ? (legacyTrace ? 'Same final decision does not prove equal hashes; threshold/interval may mask the encoding difference.' : 'Default-strategy Boolean is constant true and does not hash.') :
    c.kind==='boolean' ? `UTF8 bucket ${c.trace.bucket} versus legacy bucket ${legacyTrace.bucket} cross rollout <=37.` :
    c.name==='unicode-rollout' ? `No variants exist; feature_enabled propagates the differing rollout <=37 decision (UTF8 ${c.trace.bucket}, legacy ${legacyTrace.bucket}).` :
    `Weighted boundary 250/1000 crossed (UTF8 ${c.trace.bucket}, legacy ${legacyTrace.bucket}); treatment alone carries string payload blue.`;
  return {id:c.id,name:c.name,kind:c.kind,context:c.context,utf8Expected:c.expected,node6122:actual,
    matched,category:matched?'match':c.kind==='boolean'?'rollout-boolean':c.name==='unicode-rollout'?'propagated-feature-enabled':'weighted-variant',
    reason,utf8Trace:c.trace,...(legacyTrace?{legacyTrace}:{})};
});
const mismatches = records.filter(c=>!c.matched);
const mismatchCategories = Object.fromEntries(['rollout-boolean','propagated-feature-enabled','weighted-variant'].map(k=>[k,mismatches.filter(c=>c.category===k).length]));
assert.deepEqual(mismatchCategories,{'rollout-boolean':7,'propagated-feature-enabled':7,'weighted-variant':6});
assert.equal(mismatches.length,20);
const verdict = {schemaVersion:1,goldenSha256,inputSha256,referenceTests,
  summary:{originalCases:48,nodeMatches:28,nodeMismatches:20,mismatchCategories,
    additionalApiCases:additional.cases.length,primitiveTexts:golden.primitiveVectors.length,
    primitiveSeedChecks:golden.primitiveVectors.length*2,moonTests:2,moonExecutedByThisScript:false},
  oracle:{name:'unleash-client',version:'6.12.2',gitHead:'dc113ce745f6c0efe65ae3f6b49a439144ac4aa3',modified:false},
  verdict:'Keep UTF8 byte hashing as explicit policy; non-ASCII bucket inputs are a Node6.12.2 compatibility exception, not a parity pass.',
  records,mismatches};
await freezeOrCheck('artifacts/unicode-verdict.initial.v1.json',verdict);
await freezeOrCheck('artifacts/unicode-verdict.json',verdict);
console.log(JSON.stringify({mode:generate?'initialize-missing-only':'verify-read-only',node:process.version,...verdict.summary},null,2));
