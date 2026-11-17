import { readFile, writeFile, mkdir, open } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { isDeepStrictEqual } from 'node:util';
import { fileURLToPath } from 'node:url';
import { buildCorpus } from './generate-differential.mjs';
const root = new URL('../', import.meta.url);
const require = createRequire(new URL('tools/reference/package.json', root));
const version = require('unleash-client/package.json').version;
if (version !== '6.12.2') throw Error('Oracle version mismatch; install the frozen reference lockfile');
const Client = require('unleash-client/lib/client').default;
const { defaultStrategies } = require('unleash-client/lib/strategy');
const manifest = JSON.parse(await readFile(new URL('tests/fixtures/upstream/manifest.json', root), 'utf8'));
for (const entry of manifest.files) {
  const bytes = await readFile(new URL(`tests/fixtures/upstream/${entry.name}`, root));
  if (createHash('sha256').update(bytes).digest('hex') !== entry.sha256) throw Error(`Modified upstream fixture: ${entry.name}`);
}
const required = new Set(['01','02','03','04','05','07','08','09','10','11','12','18']);
const index = JSON.parse(await readFile(new URL('tests/fixtures/upstream/index.json', root), 'utf8'));
const fixtures = [];
for (const file of index.filter(n=>required.has(n.slice(0,2)))) fixtures.push({file,spec:JSON.parse(await readFile(new URL(`tests/fixtures/upstream/${file}`, root),'utf8'))});
const corpus = buildCorpus(fixtures);
const cases = corpus.groups.flatMap(g=>g.cases);
for (const [profile,count] of Object.entries({official:93,common:4608,'unicode-diagnostic':48})) if (cases.filter(c=>c.profile===profile).length!==count) throw Error(`Frozen v1 case count changed: ${profile}`);
const input = JSON.stringify(corpus);
const inputSha256 = createHash('sha256').update(input).digest('hex');
const firstURL = new URL(`artifacts/differential.initial.v${corpus.planVersion}.json`,root);
const previous = await readFile(firstURL,'utf8').then(JSON.parse).catch(error=>{if(error.code==='ENOENT')return null;throw error;});
if (previous && previous.inputSha256 !== inputSha256) throw Error('Frozen corpus changed; do not erase an initial result or change samples to clear a failure');
await mkdir(new URL('artifacts/',root),{recursive:true});
const inputURL = new URL('artifacts/differential-input.json',root);
await writeFile(inputURL,input);
const outputURL = new URL('artifacts/differential-moon.json',root);
const output = await open(outputURL,'w');
try {
  const child = spawn('moon',['run','cmd/differential','--target','js','--deny-warn'],{cwd:root,stdio:['ignore',output.fd,'inherit'],env:{...process.env,MOONUNLEASH_DIFF_INPUT:fileURLToPath(inputURL)}});
  const timer=setTimeout(()=>child.kill(),120000);
  let code; try { [code]=await once(child,'close'); } finally {clearTimeout(timer);}
  if(code!==0) throw Error(`MoonBit differential runner exited ${code}`);
} finally {await output.close();}
const moon = JSON.parse(await readFile(outputURL,'utf8'));
if (moon.backend!=='js' || moon.results.length!==cases.length) throw Error('MoonBit output provenance/count mismatch');
const actuals = new Map(moon.results.map(r=>[r.id,r.actual]));
if(actuals.size!==cases.length)throw Error('Duplicate MoonBit result IDs');
function variant(v) {
  const value={name:v.name,enabled:v.enabled,feature_enabled:v.feature_enabled};
  if(v.payload!==undefined)value.payload=v.payload;
  return value;
}
const records=[];
const summary={official:{matched:0,mismatched:0,oracleSpecFailures:0},common:{matched:0,mismatched:0},'unicode-diagnostic':{matched:0,mismatched:0}};
for(const group of corpus.groups){
  const toggles=new Map(group.state.features.map(f=>[f.name,f]));
  const segments=new Map((group.state.segments??[]).map(s=>[s.id,s]));
  const oracle=new Client({getToggle:name=>toggles.get(name),getSegment:id=>segments.get(id)},defaultStrategies);
  oracle.on('error',error=>{throw error;});
  for(const c of group.cases){
    if(!actuals.has(c.id))throw Error(`Missing MoonBit result: ${c.id}`);
    const reference=c.kind==='variant'?variant(oracle.getVariant(c.name,c.context)):oracle.isEnabled(c.name,c.context,()=>false);
    const actual=actuals.get(c.id);
    const matched=isDeepStrictEqual(reference,actual);
    summary[c.profile][matched?'matched':'mismatched']++;
    const oracleMatchesSpec=c.profile==='official'?isDeepStrictEqual(reference,c.expected):undefined;
    if(oracleMatchesSpec===false)summary.official.oracleSpecFailures++;
    records.push({id:c.id,profile:c.profile,status:matched?'Match':'Mismatch',moonbit:actual,node:reference,...(oracleMatchesSpec===undefined?{}:{officialExpected:c.expected,oracleMatchesSpec}),...(!matched?{name:c.name,kind:c.kind,context:c.context}:{})});
  }
}
const report={schemaVersion:1,planVersion:corpus.planVersion,seed:corpus.seed,inputSha256,specRevision:manifest.revision,backend:'js',reference:{name:'unleash-client',version,gitHead:'dc113ce745f6c0efe65ae3f6b49a439144ac4aa3',distIntegrity:'sha512-aId4dG9E8zEOlOYLVy7YTMHG/gMKQYKDldWvWGt+x1z32a9g+IjlYBsFbqwOpD6T6CvMpCHzX1aONTW5MLVcHA=='},summary,cases:records};
const encodedReport=JSON.stringify(report,null,2)+'\n';
await writeFile(new URL('artifacts/differential.json',root),encodedReport);
if(process.env.MOONUNLEASH_CI_OUTPUT==='1'){
  await mkdir(new URL('ci-output/',root),{recursive:true});
  await writeFile(new URL('ci-output/differential.json',root),encodedReport);
}
if(!previous)await writeFile(firstURL,encodedReport,{flag:'wx'});
console.log(JSON.stringify(summary,null,2));
if(summary.official.mismatched || summary.official.oracleSpecFailures || summary.common.mismatched)throw Error('Mandatory common-profile differential mismatch; report and initial result retained');
console.log('Common-profile differential passed; Unicode diagnostics remain separately reported, not full compatibility.');
