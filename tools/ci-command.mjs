// Fresh command output and escaped annotations, never old authenticated job logs.
import {open,readFile,mkdir} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {randomUUID} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=new URL('../',import.meta.url);
export function annotation(text){return text.replaceAll('%','%25').replaceAll('\r','%0D').replaceAll('\n','%0A');}
export async function recordCommand(executable,args,outputURL){
  await mkdir(new URL('ci-output/',root),{recursive:true});
  const output=await open(outputURL,'w');
  let code,timedOut=false;
  try{
    const child=spawn(executable,args,{cwd:root,stdio:['ignore',output.fd,output.fd]});
    const timer=setTimeout(()=>{timedOut=true;child.kill();},540000);
    try{[code]=await once(child,'close');}finally{clearTimeout(timer);}
  }finally{await output.close();}
  return {code:code??1,timedOut,text:await readFile(outputURL,'utf8')};
}
if(process.argv[1] && pathToFileURL(process.argv[1]).href===import.meta.url){
  const target=process.argv[2];
  if(!['js','wasm','wasm-gc','native'].includes(target))throw Error('Expected explicit supported target');
  if(process.env.GITHUB_ACTIONS==='true'){
    const version=await readFile(new URL(`ci-output/toolchain-${target}.txt`,root),'utf8');
    console.log(`::notice title=Actual MoonBit toolchain ${target}::${annotation(version)}`);
  }
  for(const stage of ['check','test']){
    const result=await recordCommand('moon',[stage,'--target',target,'--deny-warn'],new URL(`ci-output/${stage}-${target}.log`,root));
    // Compiler/test output is data, not GitHub workflow commands.
    const fence=randomUUID();
    console.log(`::stop-commands::${fence}`);
    process.stdout.write(result.text+'\n');
    console.log(`::${fence}::`);
    if(result.code!==0){
      const detail=result.text.length>48000?'[tail; full fresh output is in this run artifact]\n'+result.text.slice(-48000):result.text;
      console.log(`::error title=MoonBit ${stage} ${target}::${annotation((result.timedOut?'Command timed out\n':'')+detail)}`);
      process.exitCode=result.code;
      break;
    }
  }
}
