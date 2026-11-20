// Fixed dependency-v1 differential. Plan: docs/ACCEPTANCE.md.
import {readFile,writeFile,mkdir,open} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {isDeepStrictEqual} from 'node:util';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const root=new URL('../',import.meta.url);
const require=createRequire(new URL('tools/reference/package.json',root));
assert.equal(require('unleash-client/package.json').version,'6.12.2');
const Client=require('unleash-client/lib/client').default;
const {defaultStrategies}=require('unleash-client/lib/strategy');
const manifest=JSON.parse(await readFile(new URL('tests/fixtures/upstream/manifest.json',root),'utf8'));
const file='17-dependent-features.json';
const bytes=await readFile(new URL(`tests/fixtures/upstream/${file}`,root));
assert.equal(createHash('sha256').update(bytes).digest('hex'),manifest.files.find(f=>f.name===file).sha256);
const spec=JSON.parse(bytes);
const official=Object.entries(spec).filter(([k,v])=>/tests$/i.test(k)&&Array.isArray(v)).flatMap(([kind,cs])=>cs.map((c,i)=>({id:`official17/${kind}/${i}`,profile:'official17',name:c.toggleName,kind:kind==='variantTests'?'variant':'boolean',context:c.context,expected:c.expectedResult})));
assert.equal(official.length,43);
const flag=(name,enabled=true,dependencies=[])=>({name,enabled,dependencies,strategies:[]});
const features=[flag('on'),flag('off',false),flag('parent',true,[{feature:'on'}]),
  flag('and',true,[{feature:'on'},{feature:'off',enabled:false}]),
  flag('and-fail',true,[{feature:'on'},{feature:'off'}]),
  flag('missing-negative',true,[{feature:'missing',enabled:false}]),
  flag('self',true,[{feature:'self'}]),
  flag('nested-negative',true,[{feature:'parent',enabled:false}]),
  flag('named-disabled',true,[{feature:'on',variants:['disabled']}]),
  flag('negative-whitelist',true,[{feature:'off',enabled:false,variants:['never']}])];
const cases=['and','and-fail','missing-negative','self','nested-negative','named-disabled','negative-whitelist'].flatMap(name=>['boolean','variant'].map(kind=>({id:`edges/${name}/${kind}`,profile:'edges',name,kind,context:{userId:'dependency-user'}})));
const groups=[{state:spec.state,cases:official},{state:{version:2,features},cases}];
const input=JSON.stringify({planVersion:1,groups});
const inputSha256=createHash('sha256').update(input).digest('hex');
await mkdir(new URL('artifacts/',root),{recursive:true});
const first=new URL('artifacts/dependencies.initial.v1.json',root);
const previous=await readFile(first,'utf8').then(JSON.parse).catch(e=>{if(e.code==='ENOENT')return null;throw e});
if(previous&&previous.inputSha256!==inputSha256)throw Error('Frozen dependency-v1 corpus changed; preserve first result and version any new plan');
const inputPath=new URL('artifacts/dependencies-input.json',root);
await writeFile(inputPath,input);
const outputPath=new URL('artifacts/dependencies-moon.json',root);
const output=await open(outputPath,'w');
try{
  const child=spawn('moon',['run','cmd/differential','--target','js','--deny-warn'],{cwd:root,stdio:['ignore',output.fd,'inherit'],env:{...process.env,MOONUNLEASH_DIFF_INPUT:fileURLToPath(inputPath)}});
  const timer=setTimeout(()=>child.kill(),120000);
  try{const [code]=await once(child,'close');assert.equal(code,0)}finally{clearTimeout(timer)}
}finally{await output.close()}
const moon=JSON.parse(await readFile(outputPath,'utf8'));
const all=groups.flatMap(g=>g.cases);
assert.equal(moon.backend,'js');assert.equal(moon.results.length,57);
const actuals=new Map(moon.results.map(r=>[r.id,r.actual]));assert.equal(actuals.size,57);
const summary={official17:{matched:0,mismatched:0,oracleSpecFailures:0},edges:{matched:0,mismatched:0},oracleErrors:0};
const records=[];
for(const group of groups){
  const map=new Map(group.state.features.map(f=>[f.name,f]));
  const oracle=new Client({getToggle:name=>map.get(name),getSegment:()=>undefined},defaultStrategies);
  oracle.on('error',error=>{throw error});
  for(const c of group.cases){
    assert.ok(actuals.has(c.id));
    let node;
    try{
      if(c.kind==='variant'){
        const v=oracle.getVariant(c.name,c.context);
        node={name:v.name,enabled:v.enabled,feature_enabled:v.feature_enabled,...(v.payload===undefined?{}:{payload:v.payload})};
      }else node=oracle.isEnabled(c.name,c.context,()=>false);
    }catch(error){summary.oracleErrors++;records.push({id:c.id,status:'OracleError',moonbit:actuals.get(c.id),error:String(error)});continue}
    const actual=actuals.get(c.id);
    const matches=isDeepStrictEqual(actual,node);
    summary[c.profile][matches?'matched':'mismatched']++;
    const oracleMatchesSpec=c.profile==='official17'?isDeepStrictEqual(node,c.expected):undefined;
    if(oracleMatchesSpec===false)summary.official17.oracleSpecFailures++;
    records.push({id:c.id,status:matches?'Match':'Mismatch',moonbit:actual,node,...(oracleMatchesSpec===undefined?{}:{officialExpected:c.expected,oracleMatchesSpec})});
  }
}
const report=JSON.stringify({planVersion:1,backend:'js',inputSha256,specRevision:manifest.revision,reference:{name:'unleash-client',version:'6.12.2',gitHead:'dc113ce745f6c0efe65ae3f6b49a439144ac4aa3'},summary,cases:records},null,2)+'\n';
await writeFile(new URL('artifacts/dependencies.json',root),report);
if(!previous)await writeFile(first,report,{flag:'wx'});
if(process.env.MOONUNLEASH_CI_OUTPUT==='1'){
  await mkdir(new URL('ci-output/',root),{recursive:true});
  await writeFile(new URL('ci-output/dependencies.json',root),report);
}
console.log(JSON.stringify({inputSha256,summary},null,2));
if(summary.oracleErrors||summary.official17.mismatched||summary.official17.oracleSpecFailures||summary.edges.mismatched)throw Error('Dependency differential failed; first/latest evidence retained');
