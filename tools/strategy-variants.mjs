// Deterministic M1 differential. The old v1 corpus and its first result are untouched.
import {readFile, writeFile, mkdir, open} from 'node:fs/promises';
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
const file='16-strategy-variants.json';
const bytes=await readFile(new URL(`tests/fixtures/upstream/${file}`,root));
assert.equal(createHash('sha256').update(bytes).digest('hex'),manifest.files.find(f=>f.name===file).sha256);
const spec=JSON.parse(bytes);
const originalCases=Object.entries(spec).filter(([k,v])=>/tests$/i.test(k)&&Array.isArray(v)).flatMap(([kind,cs])=>cs.map((c,i)=>({id:`official16/${kind}/${i}`,profile:'official16',name:c.toggleName,kind:kind==='variantTests'?'variant':'boolean',context:c.context,expected:c.expectedResult})));
assert.equal(originalCases.length,11);
const variants=[{name:'control',weight:500,payload:{type:'string',value:'baseline'}},{name:'treatment',weight:500,payload:{type:'json',value:'{"model":"v2"}'}}];
const legacy=[{name:'legacy',weight:1000}];
function strategy({parameters={},...rest}={}){return {name:'flexibleRollout',parameters:{rollout:'100',stickiness:'userId',groupId:'recommendation-ab-v1',...parameters},constraints:[{contextName:'plan',operator:'IN',values:['enterprise']}],variants:structuredClone(variants),...rest};}
const defaultEmpty={name:'default',variants:[]};
const noGroup=strategy();delete noGroup.parameters.groupId;
const configs=[
  {name:'primary',strategies:[strategy()],variants:[]},
  {name:'legacy',strategies:[{name:'default'}],variants:legacy},
  {name:'first-empty',strategies:[defaultEmpty,strategy()],variants:legacy},
  {name:'first-zero',strategies:[{name:'default',variants:[{name:'zero',weight:0}]},strategy()],variants:legacy},
  {name:'first-failed-constraint',strategies:[{name:'default',constraints:[{contextName:'plan',operator:'IN',values:['never']}],variants:[{name:'never',weight:1000}]},strategy()],variants:legacy},
  {name:'multi-match',strategies:[strategy(),{name:'default',variants:[{name:'second',weight:1000}]}],variants:legacy},
  {name:'rollout-50',strategies:[strategy({parameters:{rollout:'50'}}),{name:'default',variants:[{name:'second',weight:1000}]}],variants:legacy},
  {name:'disabled',enabled:false,strategies:[strategy()],variants:legacy},
  {name:'missing-group',strategies:[noGroup],variants:[]},
  {name:'empty-group',strategies:[strategy({parameters:{groupId:''}})],variants:[]},
  {name:'variant-stickiness',strategies:[strategy({variants:variants.map(v=>({...v,stickiness:'tenantId'}))})],variants:[]},
  {name:'override',strategies:[strategy({variants:[...variants,{name:'override',weight:0,overrides:[{contextName:'userId',values:['user-1','user-4']}]}]})],variants:[]},
];
assert.equal(configs.length,12);
// Plan v1 exposed an unmodified Node-core exception for omitted parameters.
// v2 keeps every context/weight, but supplies the explicit object emitted by
// normal server strategy configuration. v1 inputs and failure remain retained.
for(const config of configs)for(const s of config.strategies)if(s.parameters===undefined)s.parameters={};
const contexts=Array.from({length:64},(_,i)=>({userId:`user-${i+1}`,properties:{plan:['enterprise','free','internal'][i%3],tenantId:`tenant-${i%7}`}}));
const groups=[{state:spec.state,cases:originalCases},...configs.map(config=>({state:{version:2,features:[{enabled:true,...config}]},cases:contexts.flatMap((context,i)=>['boolean','variant'].map(kind=>({id:`matrix/${config.name}/${i}/${kind}`,profile:'matrix',name:config.name,kind,context})))}))];
assert.equal(groups.slice(1).reduce((s,g)=>s+g.cases.length,0),1536);
const input=JSON.stringify({planVersion:2,groups});
const inputSha256=createHash('sha256').update(input).digest('hex');
await mkdir(new URL('artifacts/',root),{recursive:true});
const first=new URL('artifacts/strategy-variants.initial.v2.json',root);
const previous=await readFile(first,'utf8').then(JSON.parse).catch(e=>{if(e.code==='ENOENT')return null;throw e});
if(previous&&previous.inputSha256!==inputSha256)throw Error('Frozen strategy-variant corpus changed; preserve initial evidence and version new plans explicitly');
const inputPath=new URL('artifacts/strategy-variants-input.json',root);
await writeFile(inputPath,input);
const outputPath=new URL('artifacts/strategy-variants-moon.json',root);
const output=await open(outputPath,'w');
try{
  const child=spawn('moon',['run','cmd/differential','--target','js','--deny-warn'],{cwd:root,stdio:['ignore',output.fd,'inherit'],env:{...process.env,MOONUNLEASH_DIFF_INPUT:fileURLToPath(inputPath)}});
  const timer=setTimeout(()=>child.kill(),120000);
  let code;try{[code]=await once(child,'close')}finally{clearTimeout(timer)}
  if(code!==0)throw Error(`MoonBit strategy-variant runner exited ${code}`);
}finally{await output.close()}
const moon=JSON.parse(await readFile(outputPath,'utf8'));
const all=groups.flatMap(g=>g.cases);
assert.equal(moon.backend,'js');assert.equal(moon.results.length,all.length);
const results=new Map(moon.results.map(r=>[r.id,r.actual]));assert.equal(results.size,all.length);
const summary={official16:{matched:0,mismatched:0,oracleSpecFailures:0},matrix:{matched:0,mismatched:0},oracleErrors:0};
const records=[];
for(const group of groups){
  const features=new Map(group.state.features.map(f=>[f.name,f]));
  const oracle=new Client({getToggle:name=>features.get(name),getSegment:()=>undefined},defaultStrategies);
  oracle.on('error',e=>{throw e});
  for(const c of group.cases){
    assert.ok(results.has(c.id));
    let node;
    try{
      if(c.kind==='variant'){
        const v=oracle.getVariant(c.name,c.context);
        node={name:v.name,enabled:v.enabled,feature_enabled:v.feature_enabled,...(v.payload===undefined?{}:{payload:v.payload})};
      }else node=oracle.isEnabled(c.name,c.context,()=>false);
    }catch(error){
      summary.oracleErrors++;
      records.push({id:c.id,status:'OracleError',moonbit:results.get(c.id),error:String(error)});
      continue;
    }
    const actual=results.get(c.id);
    const matches=isDeepStrictEqual(node,actual);
    summary[c.profile][matches?'matched':'mismatched']++;
    const oracleMatchesSpec=c.profile==='official16'?isDeepStrictEqual(node,c.expected):undefined;
    if(oracleMatchesSpec===false)summary.official16.oracleSpecFailures++;
    records.push({id:c.id,status:matches?'Match':'Mismatch',moonbit:actual,node,...(oracleMatchesSpec===undefined?{}:{officialExpected:c.expected,oracleMatchesSpec})});
  }
}
const report=JSON.stringify({planVersion:2,backend:'js',inputSha256,specRevision:manifest.revision,reference:{name:'unleash-client',version:'6.12.2',gitHead:'dc113ce745f6c0efe65ae3f6b49a439144ac4aa3'},summary,cases:records},null,2)+'\n';
await writeFile(new URL('artifacts/strategy-variants.json',root),report);
if(!previous)await writeFile(first,report,{flag:'wx'});
if(process.env.MOONUNLEASH_CI_OUTPUT==='1'){
  await mkdir(new URL('ci-output/',root),{recursive:true});
  await writeFile(new URL('ci-output/strategy-variants.json',root),report);
}
console.log(JSON.stringify({inputSha256,summary},null,2));
if(summary.oracleErrors||summary.official16.mismatched||summary.official16.oracleSpecFailures||summary.matrix.mismatched)throw Error('Strategy-variant differential failed; initial and latest evidence retained');
