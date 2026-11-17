import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {annotation,recordCommand} from './ci-command.mjs';
test('workflow annotation text cannot inject new commands',()=>{
  assert.equal(annotation('100%\r\n::warning::text'),'100%25%0D%0A::warning::text');
});
test('recorded child failure retains original exit code and both streams',async()=>{
  const url=new URL('../ci-output/reporter-negative-control.log',import.meta.url);
  const result=await recordCommand(process.execPath,['-e',"console.log('synthetic stdout');console.error('synthetic stderr');process.exit(7)"],url);
  assert.equal(result.code,7);
  assert.equal(result.timedOut,false);
  assert.match(result.text,/synthetic stdout/);
  assert.match(result.text,/synthetic stderr/);
  assert.equal(await readFile(url,'utf8'),result.text);
});
