// Independent byte references only. Never imports MoonBit or patches the old oracle.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import murmur32js from 'murmur-32';
const require = createRequire(import.meta.url);
const murmur32wasm = require('murmur3hash-wasm');
const here = new URL('./', import.meta.url);
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

export const packages = [
  { name:'murmur3hash-wasm', version:'1.0.1', gitHead:'0f042767dea6a467cf451b95bdc6c7a3f5834dfd', license:'ISC', integrity:'sha512-+TDFpNmFmg0gABC0FbaddZpkohpj/QqJQCzhMCq5zadALNpoamL3NhBgPzGE7kj9ZYh/Mi2SjU9lUV/K3xqnMQ==', files:['index.js','murmur3.js','murmur3.wat','test.js'] },
  { name:'murmur-32', version:'1.0.0', gitHead:'56279a399bcda62c8d67b75b76dc0c74bb063327', license:'MIT', integrity:'sha512-l6QKUGWXzZWHash7lmZzycpIifOrnc3PeMaoFrMv90c+xqOyOSzJU0q2T/1d15MzAdEWTpCh1paC855APqt1Gw==', files:['index.js','test.js'] },
  { name:'nanoassert', version:'2.0.0', gitHead:'237fd5f382f077f0be45954741a935f2c6070660', license:'ISC', integrity:'sha512-7vO7n28+aYO4J+8w96AzhmU8G+Y/xpPDJz/se19ICsqj/momRbb9mh9ZUtkoJ5X3nTnPdhEJyc0qnM6yAsHBaA==', files:['index.js'] },
  { name:'fmix', version:'1.0.0', gitHead:'83f81781ed19e182640e759753fba23dc161493b', license:'MIT', integrity:'sha512-PIaqOGvVH5P+R92Ywy5PumsNEHvondVQh42SGOmkA9A0ZTFbfguzZpjZ/Gy3WVRUqT9Ia8k5tWlJeiZQzRHA7g==', files:['index.js'] },
  { name:'encode-utf8', version:'2.0.0', gitHead:'d61fb3e55e5573b11df69f94ff0bb7af5aee58a9', license:'MIT', integrity:'sha512-3EyMFxZj1/7oMotElDQUEQcP7N4TIe1aJ0m1uBDoyQ8I2LBHhBsXx8P3KsPbqNlGzG+NYxFwEauUwMPHZg3YDQ==', files:['index.js'] },
];

assert.equal(new Uint8Array(new Uint32Array([1]).buffer)[0], 1,
  'murmur-32 requires a little-endian host');
assert.equal(Number(process.versions.node.split('.')[0]), 24, 'Freeze/verify with Node24');
const lock = readFileSync(new URL('pnpm-lock.yaml', here), 'utf8');
export const provenance = packages.map(p => {
  const base = new URL(`node_modules/${p.name}/`, here);
  assert.equal(JSON.parse(readFileSync(new URL('package.json', base))).version, p.version);
  assert(lock.includes(p.integrity), `Lock integrity missing: ${p.name}`);
  return { ...p, registry:`https://registry.npmjs.org/${p.name}/${p.version}`,
    files:Object.fromEntries(p.files.map(f => [f,sha256(readFileSync(new URL(f,base)))])) };
});

function validate(bytes, seed) {
  assert(bytes instanceof Uint8Array, 'Explicit Uint8Array/Buffer required');
  assert(Number.isInteger(seed) && seed >= 0 && seed <= 0xffffffff, 'uint32 seed required');
  assert(bytes.byteLength <= 65536, 'Wasm wrapper is limited to one 64KiB page');
}
function jsBytes(bytes, seed) {
  // The library mutates full blocks; do not pass Buffer.buffer or reuse a buffer.
  const copy = new Uint8Array(bytes.byteLength);
  copy.set(bytes);
  return new Uint32Array(murmur32js(copy.buffer, seed))[0];
}
export function referenceHash(bytes, seed) {
  validate(bytes, seed);
  const wasm = murmur32wasm(bytes, seed) >>> 0;
  const js = jsBytes(bytes, seed);
  assert.equal(wasm, js, `Independent byte references disagree: ${Buffer.from(bytes).toString('hex')}, seed=${seed}`);
  return wasm;
}
export function utf8Bytes(text) {
  assert(text.isWellFormed(), 'Malformed UTF-16 is outside the frozen Unicode policy');
  return Buffer.from(text, 'utf8');
}

export function selfTest() {
  // Run the installed, published test files' hash assertions, without installing
  // tape/arraybuffer-equal/hex-to-array-buffer or running package lifecycle scripts.
  let wasmAssertions = 0, wasmEnds = 0;
  const wasmSource = readFileSync(new URL('node_modules/murmur3hash-wasm/test.js', here), 'utf8');
  runInNewContext(wasmSource, { Buffer, Uint8Array, require(name) {
    if (name === '.') return murmur32wasm;
    if (name === 'tape') return (name, run) => run({
      equal(actual, expected, message) { assert.equal(actual, expected, message); wasmAssertions++; },
      end() { wasmEnds++; },
    });
    throw Error(`Unexpected self-test dependency: ${name}`);
  } });
  assert.equal(wasmEnds, 1);
  const jsSource = readFileSync(new URL('node_modules/murmur-32/test.js', here), 'utf8')
    .replace(/^import .*$/gm, '');
  let jsAssertions = 0;
  const executeJs = implementation => new Function('assert','isEqual','hexToArrayBuffer','murmur',jsSource)(
    value => { assert(value); jsAssertions++; },
    (a,b) => Buffer.from(a).equals(Buffer.from(b)),
    hex => Uint8Array.from(Buffer.from(hex,'hex')).buffer,
    implementation,
  );
  executeJs(murmur32js); // Published string API fixtures, including registered sign.
  const jsStringAssertions = jsAssertions;
  executeJs(text => new Uint32Array([jsBytes(utf8Bytes(text), 0)]).buffer);
  const jsByteAssertions = jsAssertions - jsStringAssertions;
  assert.equal(jsStringAssertions, 8);
  assert.equal(jsByteAssertions, 8);
  // Both references additionally cover unsigned seeds, NUL and all block tails.
  let crossChecks = 0;
  for (const seed of [0,1,86028157,0xffffffff]) {
    for (const hex of ['', '00', '0000', '000000', '00000000', 'ff'.repeat(4), '21436587', '2143658701', '214365870102', '21436587010203']) {
      referenceHash(Buffer.from(hex,'hex'), seed); crossChecks++;
    }
  }
  assert.equal(referenceHash(utf8Bytes('hello'),0), 0x248bfa47);
  assert.equal(referenceHash(utf8Bytes('foo'),0), 0xf6a5c420);
  return { wasmPublishedAssertions:wasmAssertions, jsPublishedStringAssertions:jsStringAssertions,
    jsPublishedByteAssertions:jsByteAssertions, additionalByteCrossChecks:crossChecks,
    asciiAnchorChecks:2 };
}
