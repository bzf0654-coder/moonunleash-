import { selfTest } from './reference.mjs';
console.log(JSON.stringify({ node:process.version, status:'passed', ...selfTest() }, null, 2));
