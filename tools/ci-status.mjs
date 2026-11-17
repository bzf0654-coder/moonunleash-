// Read-only public GitHub evidence. No token, settings changes or workflow dispatch.
import https from 'node:https';
import {mkdir,writeFile} from 'node:fs/promises';
const repo='bzf0654-coder/moonunleash-';
const [runId,expectedSha]=process.argv.slice(2);
if(!/^\d+$/.test(runId??'') || !/^[0-9a-f]{40}$/.test(expectedSha??''))throw Error('Usage: node tools/ci-status.mjs RUN_ID FULL_EXPECTED_SHA');
function get(path){return new Promise((resolve,reject)=>{
  const req=https.get(`https://api.github.com/repos/${repo}/${path}`,{headers:{'User-Agent':'MoonUnleash-public-ci-evidence','Accept':'application/vnd.github+json','Cache-Control':'no-cache'}},res=>{
    let text='';res.setEncoding('utf8');res.on('data',part=>{text+=part;if(text.length>2097152)req.destroy(Error('API response budget exceeded'));});
    res.on('end',()=>{if(res.statusCode!==200)return reject(Error(`GitHub API ${res.statusCode}: ${path}`));try{resolve(JSON.parse(text));}catch(error){reject(error);}});
    res.on('error',reject);
  });req.setTimeout(20000,()=>req.destroy(Error('GitHub API timeout')));req.on('error',reject);
});}
const [run,jobs,artifacts]=await Promise.all([get(`actions/runs/${runId}`),get(`actions/runs/${runId}/jobs?per_page=100`),get(`actions/runs/${runId}/artifacts?per_page=100`)]);
if(run.head_sha!==expectedSha || run.repository.full_name!==repo || run.path!=='.github/workflows/ci.yml')throw Error('CI provenance mismatch');
if(jobs.total_count!==jobs.jobs.length || artifacts.total_count!==artifacts.artifacts.length)throw Error('Unexpected pagination; do not silently omit evidence');
const report={repository:repo,runId:Number(runId),url:run.html_url,headSha:run.head_sha,status:run.status,conclusion:run.conclusion,attempt:run.run_attempt,event:run.event,createdAt:run.created_at,updatedAt:run.updated_at,jobs:jobs.jobs.map(j=>({id:j.id,checkRunUrl:j.check_run_url,name:j.name,url:j.html_url,status:j.status,conclusion:j.conclusion,steps:j.steps.map(s=>({name:s.name,status:s.status,conclusion:s.conclusion}))})),artifacts:artifacts.artifacts.map(a=>({name:a.name,id:a.id,size:a.size_in_bytes,expired:a.expired,digest:a.digest??null,createdAt:a.created_at,headSha:a.workflow_run?.head_sha??null})),note:'Public API job/step status and artifact metadata only; artifact contents and compiler versions are not inferred or downloaded.'};
await mkdir(new URL('../artifacts/',import.meta.url),{recursive:true});
await writeFile(new URL(`../artifacts/ci-run-${runId}.json`,import.meta.url),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({url:report.url,sha:report.headSha,status:report.status,conclusion:report.conclusion,jobs:report.jobs.map(j=>({id:j.id,checkRunUrl:j.checkRunUrl,name:j.name,status:j.status,conclusion:j.conclusion,failedSteps:j.steps.filter(s=>s.conclusion==='failure').map(s=>s.name)})),artifacts:report.artifacts.map(a=>a.name)},null,2));
if(run.status==='completed'){
  if(run.conclusion!=='success' || report.jobs.length!==4 || report.jobs.some(j=>j.conclusion!=='success'))throw Error('CI did not complete successfully across all four jobs; evidence retained');
  const wanted=['verification-js','verification-native','verification-wasm','verification-wasm-gc'];
  if(wanted.some(name=>!report.artifacts.some(a=>a.name===name && !a.expired && a.size>0 && (a.headSha===null || a.headSha===expectedSha))))throw Error('Missing current four-target artifact metadata; evidence retained');
}
