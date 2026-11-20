// Actual Unleash acceptance control plane. NEVER forwards or sends /api/client/*.
// SDK transport is MoonBit -> real Unleash; this process only observes copies.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { createServer } from 'node:http';
import { appendFile, mkdir, open, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { baseline, image, verifyProvenance } from './server-provenance.mjs';
import { annotation } from './ci-command.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const target = process.argv[2];
assert.ok(['wasm', 'native'].includes(target), 'usage: node tools/real-server.mjs wasm|native');
assert.equal(process.platform, 'linux', 'isolated Docker acceptance requires Linux');
const out = resolve(root, process.argv[3] ?? `ci-output/real-server-${target}`);
await mkdir(resolve(out, '..'), { recursive: true });
// A previous run must never become this run's evidence. Choose a fresh path to rerun locally.
await mkdir(out);
const uid = randomUUID().replaceAll('-', '').slice(0, 16);
const names = { network: `moon-ci-net-${uid}`, db: `moon-ci-pg-${uid}`, server: `moon-ci-unleash-${uid}` };
const appName = `moon-ci-${target}-${uid}`, instanceId = `instance-${target}-${uid}`;
const adminToken = `*:*.${randomUUID()}`, backendToken = `default:development.${randomUUID()}`;
const password = randomUUID();
const environment = 'development';
const flags = ['ci-parent', 'ci-child'];
const featurePath = name => `/api/admin/projects/default/features/${name}/environments/${environment}`;
let base, control, child, commandNumber = 0, httpNumber = 0, wireNumber = 0;
let fault, stopped = false, completed = false, serverContainerId;
const created = { network: false, db: false, server: false };
const state = { ops: [], registrations: [], polls: [], metrics: [], oldETag: null, seen304: false, newETags: new Set() };
const initialExpected = {
  'ci-parent': { yes: 2, no: 1, variants: { blue: 1 } },
  'ci-child': { yes: 4, no: 2, variants: { gold: 2, disabled: 1 } },
};
const finalExpected = {
  'ci-parent': { yes: 3, no: 1, variants: { blue: 1 } },
  'ci-child': { yes: 6, no: 3, variants: { gold: 4, disabled: 2 } },
};
const order = ['registered', 'baseline', 'off', 'off-seen', 'on', 'on-seen', 'persisted', 'stop',
  'outage-seen', 'start', 'recovered', 'off-again', 'off-again-seen', 'on-again', 'on-again-seen', 'final-persisted', 'complete'];
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const json = (name, value) => writeFile(resolve(out, name), JSON.stringify(value, null, 2) + '\n');
const redactArgs = args => args.map(a => /^(INIT_.*TOKENS|POSTGRES_PASSWORD|DATABASE_URL)=/.test(a) ? a.split('=')[0] + '=<ephemeral-redacted>' : a);
const redact = text => [adminToken, backendToken, password].reduce((value, secret) => value.replaceAll(secret, '<ephemeral-redacted>'), text);
function diagnostic(label, text) {
  const detail = redact(String(text)).slice(-16000);
  // Escaped annotations expose fresh failure diagnostics without authenticated log download.
  // Never let compiler/container text execute GitHub workflow commands.
  if (process.env.GITHUB_ACTIONS === 'true') console.log(`::error title=Real server ${target} ${label}::${annotation(detail)}`);
  else console.error(`${label}: ${detail}`);
}

async function command(executable, args, { allowFailure = false, timeout = 120000 } = {}) {
  const n = String(++commandNumber).padStart(3, '0');
  const path = resolve(out, `${n}-${executable.replaceAll(/[^a-z0-9-]/gi, '_')}.log`);
  const log = await open(path, 'w');
  let code, signal, timedOut = false;
  await appendFile(resolve(out, 'commands.jsonl'), JSON.stringify({ n, executable, args: redactArgs(args), at: new Date().toISOString() }) + '\n');
  try {
    const process = spawn(executable, args, { cwd: root, stdio: ['ignore', log.fd, log.fd] });
    const timer = setTimeout(() => { timedOut = true; process.kill('SIGKILL'); }, timeout);
    try {
      [code, signal] = await new Promise((resolve, reject) => {
        process.once('error', reject); process.once('close', (code, signal) => resolve([code, signal]));
      });
    } finally { clearTimeout(timer); }
  } finally { await log.close(); }
  await appendFile(resolve(out, 'command-results.jsonl'), JSON.stringify({ n, code, signal, timedOut }) + '\n');
  const text = await readFile(path, 'utf8');
  if (!allowFailure && code !== 0) diagnostic(`${executable} command ${n}`, text);
  if (executable === 'moon' && args[0] === 'version' && process.env.GITHUB_ACTIONS === 'true') {
    console.log(`::notice title=Real server ${target} actual toolchain::${annotation(redact(text))}`);
  }
  if (!allowFailure) assert.equal(code, 0, `${executable} command ${n} failed (${signal ?? ''}); see ${path}`);
  return { code, text };
}
async function until(label, test, timeout = 60000) {
  const deadline = Date.now() + timeout;
  let last;
  do {
    if (fault) throw fault;
    try { const value = await test(); if (value) return value; } catch (error) { last = error; }
    await delay(250);
  } while (Date.now() < deadline);
  throw Error(`${label} deadline expired${last ? `: ${last.message}` : ''}`);
}
async function admin(path, { method = 'GET', body, expected = 200 } = {}) {
  assert.ok(path === '/health' || path.startsWith('/api/admin/'), 'control plane cannot make SDK client requests');
  const response = await fetch(base + path, {
    method, headers: { Authorization: adminToken, ...(body === undefined ? {} : { 'Content-Type': 'application/json' }) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    redirect: 'error', signal: AbortSignal.timeout(5000),
  });
  const text = await response.text();
  const n = String(++httpNumber).padStart(4, '0');
  await json(`admin-${n}.json`, { at: new Date().toISOString(), method, path, requestBody: body ?? null,
    status: response.status, headers: Object.fromEntries(response.headers), body: text });
  assert.equal(response.status, expected, `${method} ${path}: ${text.slice(0, 500)}`);
  return text ? JSON.parse(text) : null;
}
async function ready() {
  await until('Unleash health and authenticated Admin readiness', async () => {
    await admin('/health'); await admin('/api/admin/projects/default'); return true;
  }, 120000);
}
async function bootstrap() {
  for (const name of flags) {
    await admin('/api/admin/projects/default/features', { method: 'POST', body: { name, type: 'release' }, expected: 201 });
    const variant = name === 'ci-parent' ? 'blue' : 'gold';
    const first = await admin(featurePath(name) + '/strategies', { method: 'POST', body: {
      name: 'flexibleRollout', sortOrder: 0, parameters: { groupId: name, rollout: '100', stickiness: 'userId' },
      constraints: name === 'ci-child' ? [{ contextName: 'userId', operator: 'IN', values: ['allowed-user'] }] : [],
      variants: [{ name: variant, weight: 1000, weightType: 'fix', stickiness: 'userId',
        payload: { type: 'string', value: name === 'ci-parent' ? 'parent-blue' : 'child-gold' } }],
    } });
    if (name === 'ci-child') {
      // Both strategies match allowed-user. The SDK must select the FIRST matching
      // strategy's gold variant, never this later strategy's incompatible payload.
      const second = await admin(featurePath(name) + '/strategies', { method: 'POST', body: {
        name: 'flexibleRollout', sortOrder: 1,
        parameters: { groupId: name + '-later', rollout: '100', stickiness: 'userId' },
        constraints: [{ contextName: 'userId', operator: 'IN', values: ['allowed-user'] }],
        variants: [{ name: 'later', weight: 1000, weightType: 'fix', stickiness: 'userId',
          payload: { type: 'string', value: 'must-not-select' } }],
      } });
      assert.equal(typeof first.id, 'string'); assert.equal(typeof second.id, 'string');
      // Frozen schema root is an ARRAY of {id,sortOrder}, handler returns 200 empty.
      await admin(featurePath(name) + '/strategies/set-sort-order', { method: 'POST', body: [
        { id: first.id, sortOrder: 0 }, { id: second.id, sortOrder: 1 },
      ] });
      const ordered = await admin(featurePath(name) + '/strategies');
      assert.deepEqual(ordered.map(s => s.id), [first.id, second.id], 'Admin strategy order');
      assert.deepEqual(ordered.map(s => s.sortOrder), [0, 1]);
    }
  }
  await admin('/api/admin/projects/default/features/ci-child/dependencies', { method: 'POST',
    body: { feature: 'ci-parent', enabled: true, variants: ['blue'] } });
  // Strategies MUST exist before /on, or the server inserts a default OR strategy.
  for (const name of flags) await admin(featurePath(name) + '/on', { method: 'POST' });
  // Fixed server caches known feature names for 10 seconds. This is not a readiness assertion.
  // Readbacks below still use actual bounded predicates; 202 alone is never persistence proof.
  await delay(11000);
}
function canonical(toggles) {
  return Object.fromEntries(Object.entries(toggles).map(([name, value]) => [name, {
    yes: value.yes ?? 0, no: value.no ?? 0,
    variants: Object.fromEntries(Object.entries(value.variants ?? {}).filter(([, count]) => count !== 0)),
  }]));
}
function sumSent() {
  const totals = {};
  for (const event of state.metrics) for (const [flag, value] of Object.entries(event.data.bucket.toggles)) {
    const dest = totals[flag] ??= { yes: 0, no: 0, variants: {} };
    dest.yes += value.yes ?? 0; dest.no += value.no ?? 0;
    for (const [variant, count] of Object.entries(value.variants ?? {})) dest.variants[variant] = (dest.variants[variant] ?? 0) + count;
  }
  return canonical(totals);
}
async function metricsReadback(expected, label) {
  // Expected counters are hand-derived from fixed public API calls in Moon source, NOT SDK output.
  assert.deepEqual(sumSent(), expected, `${label}: exact SDK payload counters`);
  await until(label, async () => {
    const totals = {};
    for (const flag of flags) {
      const value = await admin(`/api/admin/client-metrics/features/${flag}/raw?hoursBack=1`);
      assert.equal(value.version, 1);
      const rows = value.data.filter(row => row.appName === appName && row.environment === environment && row.featureName === flag);
      const total = totals[flag] = { yes: 0, no: 0, variants: {} };
      for (const row of rows) {
        total.yes += row.yes; total.no += row.no;
        for (const [variant, count] of Object.entries(row.variants ?? {})) total.variants[variant] = (total.variants[variant] ?? 0) + count;
      }
    }
    assert.deepEqual(canonical(totals), expected);
    await json(`metrics-${label}.json`, { appName, environment, expected, actual: canonical(totals) });
    return true;
  });
}
async function observe(event) {
  const url = new URL(event.url);
  assert.equal(url.origin, base, 'SDK must connect directly to real server origin');
  assert.ok(['/api/client/register', '/api/client/features', '/api/client/metrics'].includes(url.pathname));
  assert.ok(Number.isInteger(event.status));
  const number = ++wireNumber;
  await json(`wire-${String(number).padStart(5, '0')}.json`, { number, at: new Date().toISOString(), phase: state.ops.at(-1) ?? 'startup', ...event });
  if (url.pathname.endsWith('/register')) {
    assert.equal(event.method, 'POST'); assert.equal(event.status, 202);
    const data = JSON.parse(event.requestBody);
    assert.equal(data.appName, appName); assert.equal(data.instanceId, instanceId);
    assert.equal(data.sdkVersion, 'moonunleash:0.1.0');
    assert.equal(data.interval, 0.1); assert.ok(data.strategies.includes('remoteAddress'));
    assert.equal(typeof data.started, 'string'); assert.ok(Number.isFinite(Date.parse(data.started)));
    state.registrations.push(event);
  } else if (url.pathname.endsWith('/features')) {
    assert.equal(event.method, 'GET');
    assert.ok(event.status === 200 || event.status === 304);
    // Includes the GET AFTER a headerless 304: dropping the cached tag must fail.
    if (state.oldETag !== null) assert.equal(event.ifNoneMatch, state.oldETag, 'every later poll retains the last good ETag');
    if (event.status === 200) {
      assert.ok(event.responseETag, '200 must supply ETag');
      const data = JSON.parse(event.responseBody);
      assert.equal(data.version, 2);
      const parent = data.features.find(f => f.name === 'ci-parent');
      const child = data.features.find(f => f.name === 'ci-child');
      assert.ok(parent && child);
      assert.ok(parent.strategies.some(s => s.variants?.some(v => v.name === 'blue' && v.payload?.value === 'parent-blue')));
      assert.equal(child.strategies.length, 2, 'no auto-inserted default strategy');
      assert.deepEqual(child.strategies.map(s => s.variants?.map(v => ({ name: v.name, payload: v.payload }))), [
        [{ name: 'gold', payload: { type: 'string', value: 'child-gold' } }],
        [{ name: 'later', payload: { type: 'string', value: 'must-not-select' } }],
      ], 'SDK full response preserves explicitly configured first-match order');
      for (const strategy of child.strategies) {
        assert.equal(strategy.name, 'flexibleRollout'); assert.equal(strategy.parameters.rollout, '100');
        assert.ok(strategy.constraints?.some(c => c.contextName === 'userId' && c.operator === 'IN' && c.values?.length === 1 && c.values[0] === 'allowed-user'));
      }
      assert.ok(child.dependencies?.some(d => d.feature === 'ci-parent' && d.enabled === true && d.variants?.includes('blue')));
      state.oldETag = event.responseETag;
      state.newETags.add(event.responseETag);
    } else {
      assert.equal(event.ifNoneMatch, state.oldETag, '304 request must retain last good ETag');
      assert.equal(event.responseBody, '');
      state.seen304 = true;
      // No assignment from responseETag: v7.4.0 strips headers on 304.
    }
    state.polls.push(event);
  } else {
    assert.equal(event.method, 'POST'); assert.equal(event.status, 202, '204 is not accepted metrics');
    const data = JSON.parse(event.requestBody);
    assert.equal(data.appName, appName); assert.equal(data.instanceId, instanceId);
    for (const date of [data.bucket.start, data.bucket.stop]) {
      assert.equal(typeof date, 'string'); assert.ok(Math.abs(Date.parse(date) - Date.now()) < 3600000);
    }
    assert.ok(Date.parse(data.bucket.stop) >= Date.parse(data.bucket.start));
    state.metrics.push({ event, data });
  }
}
async function operation(op, body) {
  if (op === 'wire') { await observe(body); return; }
  assert.equal(op, order[state.ops.length], 'control operation order');
  await json(`checkpoint-${String(state.ops.length).padStart(2, '0')}-${op}.json`, { at: new Date().toISOString(), ...body });
  switch (op) {
    case 'registered':
      assert.equal(state.registrations.length, 1);
      await until('registered instance persisted', async () => {
        const data = await admin(`/api/admin/metrics/instances/${encodeURIComponent(appName)}/environment/${environment}`);
        return data.instances.some(i => i.instanceId === instanceId && i.sdkVersion === 'moonunleash:0.1.0' && typeof i.clientIp === 'string');
      });
      break;
    case 'baseline': assert.ok(state.seen304); break;
    case 'off': case 'off-again': await admin(featurePath('ci-parent') + '/off', { method: 'POST' }); break;
    case 'on': case 'on-again': await admin(featurePath('ci-parent') + '/on', { method: 'POST' }); break;
    case 'persisted':
      assert.equal(state.metrics.length, 1); await metricsReadback(initialExpected, 'before-outage'); break;
    case 'stop':
      await command('docker', ['stop', '--time', '1', names.server]); stopped = true; break;
    case 'outage-seen':
      assert.ok(stopped); assert.equal(body.ready, true); assert.ok(body.failures > 0); assert.equal(typeof body.error, 'string');
      break;
    case 'start':
      assert.ok(stopped); await command('docker', ['start', names.server]); stopped = false; await ready(); break;
    case 'recovered':
      assert.equal(body.failures, 0); assert.equal(body.ready, true);
      await snapshotContainer(names.server, 'container-after-recovery.json'); break;
    case 'final-persisted':
      assert.equal(state.metrics.length, 2); await metricsReadback(finalExpected, 'final'); break;
    case 'complete':
      assert.equal(state.registrations.length, 1); assert.equal(state.metrics.length, 2);
      assert.ok(state.seen304); assert.ok(state.newETags.size >= 5, 'initial plus four real off/on revisions');
      completed = true; break;
  }
  state.ops.push(op);
}
async function startControl() {
  const nonce = randomUUID();
  control = createServer(async (request, response) => {
    try {
      if (request.method !== 'POST' || !request.url.startsWith(`/${nonce}/`)) { response.writeHead(404).end(); return; }
      const op = request.url.slice(nonce.length + 2);
      let size = 0, text = '';
      for await (const chunk of request) {
        size += chunk.length; assert.ok(size <= 10 * 1024 * 1024, 'control body size'); text += chunk.toString('utf8');
      }
      await operation(op, JSON.parse(text));
      response.writeHead(200, { 'Content-Type': 'application/json' }).end('{}');
    } catch (error) {
      fault ??= error;
      await json('control-failure.json', { message: error.message, stack: error.stack });
      response.writeHead(500, { 'Content-Type': 'application/json' }).end(JSON.stringify({ error: error.message }));
    }
  });
  await new Promise((resolve, reject) => { control.once('error', reject); control.listen(0, '127.0.0.1', resolve); });
  return `http://127.0.0.1:${control.address().port}/${nonce}`;
}
async function runMoon(controlURL) {
  const log = await open(resolve(out, 'moon.log'), 'w');
  let timer;
  try {
    const args = ['run', 'cmd/server-acceptance', '--target', target];
    await json('moon-command.json', { executable: 'moon', args, target, appName, instanceId,
      env: { REAL_SERVER_URL: base + '/api', REAL_CONTROL_URL: '<ephemeral-loopback-control>', REAL_APP_NAME: appName,
        REAL_INSTANCE_ID: instanceId, REAL_BACKEND_TOKEN: '<ephemeral-redacted>' } });
    child = spawn('moon', args, { cwd: root, stdio: ['ignore', log.fd, log.fd], env: { ...process.env,
      REAL_SERVER_URL: base + '/api', REAL_CONTROL_URL: controlURL, REAL_APP_NAME: appName,
      REAL_INSTANCE_ID: instanceId, REAL_BACKEND_TOKEN: backendToken } });
    const outcome = new Promise((resolve, reject) => { child.once('error', reject); child.once('close', (code, signal) => resolve({ code, signal })); });
    timer = setTimeout(() => child.kill('SIGKILL'), 420000);
    const result = await outcome;
    await json('moon-exit.json', result);
    if (fault || result.code !== 0) diagnostic('Moon acceptance output', await readFile(resolve(out, 'moon.log'), 'utf8'));
    if (fault) throw fault;
    assert.equal(result.code, 0, `Moon acceptance failed; see ${resolve(out, 'moon.log')}`);
  } finally { clearTimeout(timer); await log.close(); }
}
async function snapshotContainer(name, filename) {
  // Select safe fields IN docker, so credentials never reach even an interrupted raw log.
  const format = '{"Id":{{json .Id}},"Image":{{json .Image}},"Name":{{json .Name}},"State":{{json .State}},"ports":{{json .NetworkSettings.Ports}}}';
  const value = await command('docker', ['inspect', '--format', format, name], { allowFailure: true });
  if (value.code !== 0) return;
  const container = JSON.parse(value.text);
  if (name === names.server) {
    assert.equal(container.Image, baseline.config, 'executed container uses the verified image config');
    assert.match(container.Id, /^[0-9a-f]{64}$/);
    if (serverContainerId) assert.equal(container.Id, serverContainerId, 'stop/start recovers the SAME container');
    serverContainerId = container.Id;
  }
  await json(filename, { ...container, configuredServerEnvironment: {
    DATABASE_SSL: 'false', HTTP_HOST: '0.0.0.0', HTTP_PORT: '4242', SEND_TELEMETRY: 'false', CHECK_VERSION: 'false',
    INIT_ADMIN_API_TOKENS: '<ephemeral-redacted>', INIT_BACKEND_API_TOKENS: '<ephemeral-redacted>', DATABASE_URL: '<ephemeral-redacted>',
  } });
}
let passed = false;
try {
  await json('run.json', { status: 'Running', target, appName, instanceId, environment, baseline, image,
    startedAt: new Date().toISOString(), github: { repository: process.env.GITHUB_REPOSITORY, sha: process.env.GITHUB_SHA,
      runId: process.env.GITHUB_RUN_ID, runAttempt: process.env.GITHUB_RUN_ATTEMPT }, expected: { beforeOutage: initialExpected, final: finalExpected } });
  await verifyProvenance(resolve(out, 'provenance'));
  await command('docker', ['version']);
  await command('moon', ['version', '--all']);
  await command('docker', ['pull', '--platform', 'linux/amd64', image]);
  await command('docker', ['pull', '--platform', 'linux/amd64', 'postgres:15']);
  await command('docker', ['image', 'inspect', image]);
  await command('docker', ['image', 'inspect', 'postgres:15']);
  await command('docker', ['network', 'create', names.network]); created.network = true;
  await command('docker', ['run', '-d', '--platform', 'linux/amd64', '--name', names.db, '--network', names.network,
    '--tmpfs', '/var/lib/postgresql/data', '-e', 'POSTGRES_USER=unleash', '-e', `POSTGRES_PASSWORD=${password}`,
    '-e', 'POSTGRES_DB=unleash', 'postgres:15']); created.db = true;
  await until('PostgreSQL ready', async () => (await command('docker', ['exec', names.db, 'pg_isready', '-U', 'unleash', '-d', 'unleash'], { allowFailure: true })).code === 0);
  await command('docker', ['run', '-d', '--platform', 'linux/amd64', '--name', names.server, '--network', names.network,
    '-p', '127.0.0.1::4242', '-e', `DATABASE_URL=postgres://unleash:${password}@${names.db}:5432/unleash`,
    '-e', 'DATABASE_SSL=false', '-e', 'HTTP_HOST=0.0.0.0', '-e', 'HTTP_PORT=4242', '-e', 'UNLEASH_URL=http://127.0.0.1:4242',
    '-e', `INIT_ADMIN_API_TOKENS=${adminToken}`, '-e', `INIT_BACKEND_API_TOKENS=${backendToken}`,
    '-e', 'SEND_TELEMETRY=false', '-e', 'CHECK_VERSION=false', '-e', 'LOG_LEVEL=warn', image]); created.server = true;
  const port = (await command('docker', ['port', names.server, '4242/tcp'])).text.trim();
  assert.match(port, /^127\.0\.0\.1:\d+$/); base = `http://${port}`;
  await ready(); await snapshotContainer(names.server, 'container-before.json'); await bootstrap();
  const controlURL = await startControl(); await runMoon(controlURL);
  assert.ok(completed); assert.deepEqual(state.ops, order); passed = true;
} catch (error) {
  await json('failure.json', { message: error.message, stack: error.stack });
  diagnostic('failure', error.stack ?? error.message); process.exitCode = 1;
} finally {
  if (control) { control.closeAllConnections(); await new Promise(resolve => control.close(resolve)); }
  // Collect current-run diagnostics before deleting only containers/network created by this run.
  for (const key of ['server', 'db']) if (created[key]) {
    try {
      const logs = await command('docker', ['logs', '--timestamps', names[key]], { allowFailure: true });
      if (!passed) diagnostic(`${key} container output`, logs.text);
      await snapshotContainer(names[key], `${key}-final.json`);
    } catch (error) { await json(`cleanup-${key}-error.json`, { message: error.message }); }
    await command('docker', ['rm', '-f', names[key]], { allowFailure: true });
  }
  if (created.network) await command('docker', ['network', 'rm', names.network], { allowFailure: true });
  await json('result.json', { status: passed ? 'PASS' : 'FAIL', executed: true, target, appName, instanceId,
    environment, image, sourceRevision: baseline.revision, completedAt: new Date().toISOString(),
    operations: state.ops, wire: { registrations: state.registrations.length, polls: state.polls.length,
      seen304: state.seen304, distinctETags: [...state.newETags], acceptedMetrics: state.metrics.length },
    caveats: ['No signature verification or reproducible-build proof', 'PostgreSQL postgres:15 and Moon stable are mutable; actual identities are archived'] });
}
console.log(`Real-server ${target}: ${passed ? 'PASS' : 'FAIL'}. Evidence: ${out}`);
