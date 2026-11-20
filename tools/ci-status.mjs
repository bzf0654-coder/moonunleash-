// Read-only public GitHub evidence. No token, settings changes or workflow dispatch.
import https from 'node:https';
import {mkdir,writeFile} from 'node:fs/promises';
import {validateProof} from './ci-proof.mjs';
const repo='bzf0654-coder/moonunleash-';
const [runId,expectedSha,mode='sdk']=process.argv.slice(2);
if(!/^\d+$/.test(runId??'') || !/^[0-9a-f]{40}$/.test(expectedSha??'') || !['sdk','real-server'].includes(mode))throw Error('Usage: node tools/ci-status.mjs RUN_ID FULL_EXPECTED_SHA [sdk|real-server]');
const workflow=mode==='sdk'?'.github/workflows/ci.yml':'.github/workflows/real-server.yml';
function get(path){return new Promise((resolve,reject)=>{
  const req=https.get(`https://api.github.com/repos/${repo}/${path}`,{headers:{'User-Agent':'MoonUnleash-public-ci-evidence','Accept':'application/vnd.github+json','Cache-Control':'no-cache'}},res=>{
    let text='';res.setEncoding('utf8');res.on('data',part=>{text+=part;if(text.length>2097152)req.destroy(Error('API response budget exceeded'));});
    res.on('end',()=>{if(res.statusCode!==200)return reject(Error(`GitHub API ${res.statusCode}: ${path}`));try{resolve(JSON.parse(text));}catch(error){reject(error);}});
    res.on('error',reject);
  });req.setTimeout(20000,()=>req.destroy(Error('GitHub API timeout')));req.on('error',reject);
});}
const [run,jobs,artifacts]=await Promise.all([get(`actions/runs/${runId}`),get(`actions/runs/${runId}/jobs?per_page=100`),get(`actions/runs/${runId}/artifacts?per_page=100`)]);
if(run.head_sha!==expectedSha || run.repository.full_name!==repo || run.path!==workflow)throw Error('CI provenance mismatch');
if(jobs.total_count!==jobs.jobs.length || artifacts.total_count!==artifacts.artifacts.length)throw Error('Unexpected pagination; do not silently omit evidence');
const report={repository:repo,workflow,runId:Number(runId),url:run.html_url,headSha:run.head_sha,status:run.status,conclusion:run.conclusion,attempt:run.run_attempt,event:run.event,createdAt:run.created_at,updatedAt:run.updated_at,jobs:jobs.jobs.map(j=>({id:j.id,checkRunUrl:j.check_run_url,name:j.name,url:j.html_url,status:j.status,conclusion:j.conclusion,steps:j.steps.map(s=>({name:s.name,status:s.status,conclusion:s.conclusion}))})),artifacts:artifacts.artifacts.map(a=>({name:a.name,id:a.id,size:a.size_in_bytes,expired:a.expired,digest:a.digest??null,createdAt:a.created_at,headSha:a.workflow_run?.head_sha??null})),note:'Public API job/step status, artifact metadata and current-run verified summary annotations. Raw artifact archives are not downloaded; summary report/result hashes bind the public summaries to archived files. Compiler versions are read from actual run annotations, never inferred from the stable label.'};
await mkdir(new URL('../artifacts/',import.meta.url),{recursive:true});
const save=()=>writeFile(new URL(`../artifacts/ci-run-${runId}.json`,import.meta.url),JSON.stringify(report,null,2)+'\n');
await save();
console.log(JSON.stringify({url:report.url,sha:report.headSha,status:report.status,conclusion:report.conclusion,jobs:report.jobs.map(j=>({id:j.id,checkRunUrl:j.checkRunUrl,name:j.name,status:j.status,conclusion:j.conclusion,failedSteps:j.steps.filter(s=>s.conclusion==='failure').map(s=>s.name)})),artifacts:report.artifacts.map(a=>a.name)},null,2));
if(run.status==='completed'){
  const targets=mode==='sdk'?['js','native','wasm','wasm-gc']:['native','wasm'];
  const jobName=t=>mode==='sdk'?`tests (${t})`:`Real server / ${t}`;
  if(run.conclusion!=='success' || report.jobs.length!==targets.length || targets.some(t=>!report.jobs.some(j=>j.name===jobName(t) && j.conclusion==='success')))throw Error('CI did not complete successfully across all required target jobs; evidence retained');
  for(const t of targets){
    const job=report.jobs.find(j=>j.name===jobName(t));
    const stages=mode==='sdk'?['Type check and test','Generate and validate per-case conformance report','Run offline example',...(t==='wasm'?['Real HTTP fault smoke (controlled server, not Unleash)']:[]),...(t==='js'?['Verify frozen independent Unicode golden and generated regressions','Common-profile differential and explicit Unicode diagnostics']:[])]:['Record actual toolchain and environment','Resolve declared Moon dependencies','Execute actual SDK against isolated pinned server'];
    if(stages.some(name=>!job.steps.some(s=>s.name===name && s.status==='completed' && s.conclusion==='success')))throw Error(`Missing successful acceptance step for ${t}; evidence retained`);
  }
  const wanted=targets.map(t=>mode==='sdk'?`verification-${t}`:`real-unleash-7.4.0-${t}-${runId}-${run.run_attempt}`);
  if(wanted.some(name=>!report.artifacts.some(a=>a.name===name && !a.expired && a.size>0 && a.headSha===expectedSha)))throw Error('Missing fresh same-SHA target artifact metadata; evidence retained');
  for(const t of targets){
    const job=report.jobs.find(j=>j.name===jobName(t));
    const id=job.checkRunUrl.split('/').at(-1);
    if(!/^\d+$/.test(id))throw Error('Invalid public check-run id');
    const annotations=await get(`check-runs/${id}/annotations?per_page=100`);
    job.annotations=annotations.map(a=>({level:a.annotation_level,title:a.title,message:a.message}));
    await save();
    const title=mode==='sdk'?'MoonUnleash conformance proof':'MoonUnleash real-server proof';
    const summaries=job.annotations.filter(a=>a.title===title && a.level==='notice');
    if(summaries.length!==1)throw Error(`Missing unique verified current-run public proof for ${t}; metadata alone is not sufficient`);
    job.proof=validateProof(JSON.parse(summaries[0].message),mode,t,expectedSha);
    if(mode==='sdk'){
      job.toolchain=job.annotations.find(a=>a.title===`Actual MoonBit toolchain ${t}`)?.message;
      if(!/moon[\s\S]*moonc/.test(job.toolchain??''))throw Error('Missing actual installed toolchain notice');
    }
    await save();
    console.log(JSON.stringify({target:t,verifiedPublicProof:job.proof,toolchain:job.toolchain??job.proof.toolchain},null,2));
  }
}
