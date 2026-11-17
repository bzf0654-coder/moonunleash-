// Run MoonBit itself; JS only verifies artifacts/inventory and supervises the process.
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { mkdir, open, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual } from 'node:util';
import './generate-fixtures.mjs';
const target = process.argv[2] ?? 'wasm-gc';
if (!['wasm-gc', 'wasm', 'js', 'native'].includes(target)) throw Error('Unsupported target');
const root = new URL('../', import.meta.url);
const formatter = spawn('moon', ['fmt', 'internal/specdata'], { cwd: root, stdio: 'inherit' });
const [formatCode] = await once(formatter, 'close');
if (formatCode !== 0) throw Error('Generated data formatting failed');
await mkdir(new URL('artifacts/', root), { recursive: true });
const path = new URL(`artifacts/conformance.${target}.json`, root);
const output = await open(path, 'w');
let code;
try {
  const child = spawn('moon', ['run', 'cmd/conformance', '--target', target, '--deny-warn'], { cwd: root, stdio: ['ignore', output.fd, 'inherit'] });
  const timer = setTimeout(() => child.kill(), 120000);
  try { [code] = await once(child, 'close'); } finally { clearTimeout(timer); }
} finally { await output.close(); }
if (code !== 0) throw Error(`Conformance executable exited ${code}; inspect ${fileURLToPath(path)}`);
const report = JSON.parse(await readFile(path, 'utf8'));
const inventory = JSON.parse(await readFile(new URL('docs/spec-inventory.json', root), 'utf8'));
if (report.revision !== inventory.revision || report.backend !== target || report.suites.length !== inventory.suites.length) throw Error('Report provenance mismatch');
const originalFixtures = new Map();
for (const suite of inventory.suites.filter(s => s.status === 'Required')) originalFixtures.set(suite.file, JSON.parse(await readFile(new URL(`tests/fixtures/upstream/${suite.file}`, root), 'utf8')));
const expectedCases = inventory.suites.flatMap(s => s.cases.map(c => ({ file: s.file, kind: c.kind, index: c.index, required: s.status === 'Required' })));
const byId = new Map(report.cases.map(c => [`${c.file}:${c.kind}:${c.index}`, c]));
if (byId.size !== report.cases.length || report.cases.length !== expectedCases.length) throw Error('Missing or duplicate report cases');
for (const expected of expectedCases) {
  const c = byId.get(`${expected.file}:${expected.kind}:${expected.index}`);
  if (!c || c.required !== expected.required || c.status !== (expected.required ? 'Pass' : 'NotRun')) throw Error(`Required case failed or inventory changed: ${JSON.stringify({ expected, actual: c })}`);
  if (expected.required && (!isDeepStrictEqual(c.actual, c.expected) || !isDeepStrictEqual(c.expected, originalFixtures.get(c.file)[c.kind][c.index].expectedResult))) throw Error(`False passing status or altered expectation: ${JSON.stringify(c)}`);
}
const passed = report.cases.filter(c => c.status === 'Pass').length;
const notRun = report.cases.filter(c => c.status === 'NotRun').length;
if (passed !== report.summary.passed || notRun !== report.summary.notRun || report.summary.failed !== 0 || passed + notRun !== report.cases.length) throw Error('Report summary mismatch');
console.log(`${target}: ${passed} official cases passed, ${notRun} explicitly not run, ${report.summary.requiredSuites}/${report.summary.suites} suites required. Report: ${fileURLToPath(path)}`);
