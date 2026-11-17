// Exercise the actual pinned wrapper prototype methods, not a handwritten spread oracle.
// Constructor/network/metrics are deliberately outside this targeted comparison.
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFile,writeFile,mkdir,open } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { isDeepStrictEqual } from 'node:util';
const root=new URL('../',import.meta.url);
const require=createRequire(new URL('tools/reference/package.json',root));
if(require('unleash-client/package.json').version!=='6.12.2')throw Error('Pinned oracle version mismatch');
const {Unleash}=require('unleash-client/lib/unleash');
const Client=require('unleash-client/lib/client').default;
const {defaultStrategies}=require('unleash-client/lib/strategy');
const contexts=[{}, {userId:'user-1',properties:{tier:'enterprise'}}, {appName:'other'}, {environment:'other'}, {appName:''}, {appName:null}, {environment:''}, {environment:null}, {properties:{appName:'spoof',environment:'spoof',tier:'enterprise'}}];
const presets=[{appName:'tests',environment:'default'},{appName:'custom-app',environment:'production'}];
const groups=presets.map((defaults,p)=>{
  const app={contextName:'appName',operator:'IN',values:[defaults.appName]};
  const env={contextName:'environment',operator:'IN',values:[defaults.environment]};
  const features=[['app',[app]],['environment',[env]],['qualified',[app,env,{contextName:'tier',operator:'IN',values:['enterprise']}]]].map(([name,constraints])=>({name,enabled:true,strategies:[{name:'default',constraints}],variants:[{name:'only',weight:1000,payload:{type:'string',value:name}}]}));
  return {state:{version:2,features},cases:contexts.flatMap((context,i)=>features.flatMap(f=>['boolean','variant'].map(kind=>({id:`${p}:${i}:${f.name}:${kind}`,name:f.name,kind,context,defaults}))))};
});
const input=JSON.stringify({groups});
const expectedCount=108;
await mkdir(new URL('artifacts/',root),{recursive:true});
const inputURL=new URL('artifacts/context-defaults-input.json',root);
const outputURL=new URL('artifacts/context-defaults-moon.json',root);
await writeFile(inputURL,input);
const output=await open(outputURL,'w');
try{
  const child=spawn('moon',['run','cmd/differential','--target','js','--deny-warn'],{cwd:root,stdio:['ignore',output.fd,'inherit'],env:{...process.env,MOONUNLEASH_DIFF_INPUT:fileURLToPath(inputURL)}});
  const timer=setTimeout(()=>child.kill(),120000);
  let code;try{[code]=await once(child,'close');}finally{clearTimeout(timer);}
  if(code!==0)throw Error(`MoonBit context comparison exited ${code}`);
}finally{await output.close();}
const moon=JSON.parse(await readFile(outputURL,'utf8'));
const actuals=new Map(moon.results.map(c=>[c.id,c.actual]));
if(moon.backend!=='js' || moon.results.length!==expectedCount || actuals.size!==expectedCount)throw Error('Invalid comparison provenance/count');
const records=[];
let mismatched=0;
for(const group of groups){
  const toggles=new Map(group.state.features.map(f=>[f.name,f]));
  const core=new Client({getToggle:name=>toggles.get(name),getSegment:()=>undefined},defaultStrategies);
  // Match constructor staticContext; omit I/O and counters, not the evaluated methods.
  const receiver={staticContext:group.cases[0].defaults,ready:true,client:core,count(){},countVariant(){}};
  for(const c of group.cases){
    let reference;
    if(c.kind==='variant'){
      const v=Unleash.prototype.getVariant.call(receiver,c.name,c.context);
      reference={name:v.name,enabled:v.enabled,feature_enabled:v.feature_enabled,...(v.payload===undefined?{}:{payload:v.payload})};
    }else reference=Unleash.prototype.isEnabled.call(receiver,c.name,c.context);
    if(!actuals.has(c.id))throw Error(`Missing result ${c.id}`);
    const actual=actuals.get(c.id);
    const matched=isDeepStrictEqual(reference,actual);
    if(!matched)mismatched++;
    records.push({...c,node:reference,moonbit:actual,status:matched?'Match':'Mismatch'});
  }
}
const report={schemaVersion:1,reference:'unleash-client@6.12.2',gitHead:'dc113ce745f6c0efe65ae3f6b49a439144ac4aa3',backend:'js',scope:'Actual wrapper isEnabled/getVariant prototype methods with in-memory core/staticContext; no constructor, network or metrics lifecycle',inputSha256:createHash('sha256').update(input).digest('hex'),summary:{cases:records.length,matched:records.length-mismatched,mismatched},cases:records};
const data=JSON.stringify(report,null,2)+'\n';
await writeFile(new URL('artifacts/context-defaults.json',root),data);
if(process.env.MOONUNLEASH_CI_OUTPUT==='1'){
  await mkdir(new URL('ci-output/',root),{recursive:true});
  await writeFile(new URL('ci-output/context-defaults.json',root),data);
}
console.log(`Context defaults: ${records.length-mismatched}/${expectedCount} agree with pinned wrapper methods`);
if(mismatched || records.length!==expectedCount)throw Error('Context default comparison failed; report retained');
