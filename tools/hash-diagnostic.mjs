// Encoding diagnosis, not a replacement reference flag engine.
import { createRequire } from 'node:module';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { isDeepStrictEqual } from 'node:util';
const reference = createRequire(new URL('./reference/package.json', import.meta.url));
const sdk = createRequire(reference.resolve('unleash-client/package.json'));
const { x86 } = sdk('murmurhash3js');
if(sdk('murmurhash3js/package.json').version !== '3.0.1')throw Error('Unexpected primitive oracle version');
const rows=[];
for(const text of ['共享组-🌍:用户甲','全局变体-ø:用户乙','checkout:é','checkout:e\u0301','checkout:😊']) for(const seed of [0,86028157]){
  const utf8Bytes=Buffer.from(text,'utf8');
  rows.push({text,seed,utf8Hex:utf8Bytes.toString('hex'),utf8Hash:x86.hash32(utf8Bytes.toString('latin1'),seed),nodeStringHash:x86.hash32(text,seed)});
}
const Client=reference('unleash-client/lib/client').default;
const {defaultStrategies}=reference('unleash-client/lib/strategy');
const corpus=JSON.parse(await readFile(new URL('../artifacts/differential-input.json',import.meta.url),'utf8'));
const moon=JSON.parse(await readFile(new URL('../artifacts/differential-moon.json',import.meta.url),'utf8'));
const primary=JSON.parse(await readFile(new URL('../artifacts/differential.json',import.meta.url),'utf8'));
const actuals=new Map(moon.results.map(r=>[r.id,r.actual]));
const diagnostic=corpus.groups.find(g=>g.id==='unicode-hash-diagnostic-v1');
if(!diagnostic || diagnostic.cases.length!==48 || primary.summary['unicode-diagnostic'].mismatched!==20)throw Error('Unexpected diagnostic corpus or baseline; explicitly review a changed plan');
const rawHash=x86.hash32;
let matched=0;
const intervention=[];
try {
  // Controlled intervention only: not the original SDK and not a compatibility pass.
  x86.hash32=(text,seed=0)=>rawHash(Buffer.from(text,'utf8').toString('latin1'),seed);
  const toggles=new Map(diagnostic.state.features.map(f=>[f.name,f]));
  const client=new Client({getToggle:name=>toggles.get(name),getSegment:()=>undefined},defaultStrategies);
  for(const c of diagnostic.cases){
    let value;
    if(c.kind==='variant'){
      const v=client.getVariant(c.name,c.context);
      value={name:v.name,enabled:v.enabled,feature_enabled:v.feature_enabled,...(v.payload===undefined?{}:{payload:v.payload})};
    } else value=client.isEnabled(c.name,c.context,()=>false);
    const equal=isDeepStrictEqual(value,actuals.get(c.id));
    if(equal)matched++;
    intervention.push({id:c.id,matched:equal});
  }
} finally {x86.hash32=rawHash;}
const report={controlledIntervention:{description:'In-memory UTF-8 input bridge applied to primitive only, then restored; not an unmodified SDK result',baselineMismatches:primary.summary['unicode-diagnostic'].mismatched,matched,mismatched:48-matched,cases:intervention},primitive:'murmurhash3js@3.0.1 x86.hash32',note:'UTF-8 byte view versus raw JavaScript string. No claim that all SDKs share an encoding policy.',vectors:rows};
await mkdir(new URL('../artifacts/',import.meta.url),{recursive:true});
const encodedReport=JSON.stringify(report,null,2)+'\n';
await writeFile(new URL('../artifacts/hash-encoding.json',import.meta.url),encodedReport);
if(process.env.MOONUNLEASH_CI_OUTPUT==='1'){
  await mkdir(new URL('../ci-output/',import.meta.url),{recursive:true});
  await writeFile(new URL('../ci-output/hash-encoding.json',import.meta.url),encodedReport);
}
console.log(`Raw Node SDK: ${primary.summary['unicode-diagnostic'].mismatched}/48 differ. Encoding-only diagnostic: ${matched}/48 match MoonBit. This is not an unmodified SDK compatibility pass.`);
if(matched!==48)throw Error('Encoding-only hypothesis did not explain all diagnostic cases; report retained');
