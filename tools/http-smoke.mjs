// Controlled HTTP contract test, not an actual Unleash server.
// Inherit stdio: no subprocess output pipes, and keep this event loop serving HTTP.
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { mkdir, writeFile } from 'node:fs/promises';
const state = enabled => JSON.stringify({ version: 2, features: [{ name: 'checkout', enabled, strategies: [{ name: 'default' }] }] });
let step = 0, redirected = false, registered = 0;
const etags = [];
const server = createServer((req, res) => {
  if (req.headers.authorization !== 'not-a-secret') { res.writeHead(401).end(); return; }
  if (req.method === 'POST' && req.url.endsWith('/client/register')) {
    let body = '';
    req.setEncoding('utf8');
    req.on('data', chunk => { body += chunk; if (body.length > 16384) req.destroy(); });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const strategies = ['default', 'flexibleRollout', 'gradualRolloutRandom', 'gradualRolloutSessionId', 'gradualRolloutUserId', 'remoteAddress', 'userWithId'];
        if (typeof data.appName !== 'string' || typeof data.instanceId !== 'string' || !data.instanceId.startsWith('moon-') || data.sdkVersion !== 'moonunleash:0.1.0' || typeof data.interval !== 'number' || data.interval <= 0 || typeof data.started !== 'string' || !Number.isFinite(Date.parse(data.started)) || Math.abs(Date.parse(data.started) - Date.now()) > 60000 || !Array.isArray(data.strategies) || JSON.stringify([...data.strategies].sort()) !== JSON.stringify(strategies)) throw Error('registration schema');
        registered++; res.writeHead(202).end();
      } catch { res.writeHead(400).end(); }
    });
    return;
  }
  if (req.url === '/large/client/features') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    // Chunked encoding checks the incremental body guard, not Content-Length alone.
    res.write(' '.repeat(200)); res.end(state(true)); return;
  }
  if (req.url === '/leak') { redirected = true; res.writeHead(200).end(state(true)); return; }
  if (req.url !== '/flow/client/features') { res.writeHead(404).end(); return; }
  etags.push(req.headers['if-none-match'] ?? null);
  switch (++step) {
    case 1: res.writeHead(200, { ETag: 'v1' }).end(state(true)); break;
    case 2: res.writeHead(304).end(); break;
    case 3: res.writeHead(200, { ETag: 'invalid-v2' }).end('{broken'); break;
    case 4: res.writeHead(503).end(); break;
    case 5: res.writeHead(200, { ETag: 'v2' }).end(state(false)); break;
    case 6: res.writeHead(302, { Location: `http://127.0.0.1:${server.address().port}/leak` }).end(); break;
    default: res.writeHead(500).end();
  }
});
server.listen(0, '127.0.0.1');
await once(server, 'listening');
const url = `http://127.0.0.1:${server.address().port}`;
try {
  const child = spawn('moon', ['run', 'cmd/http-smoke', '--target', 'wasm', '--', url], { cwd: new URL('../', import.meta.url), stdio: 'inherit' });
  const timer = setTimeout(() => child.kill(), 60000);
  child.once('error', error => { console.error(error); child.kill(); });
  const [code] = await once(child, 'close');
  clearTimeout(timer);
  if (code !== 0) throw Error(`MoonBit HTTP smoke exited ${code}`);
  if (step !== 6 || redirected || registered !== 2) throw Error(`HTTP request sequence / redirect / registration check failed: ${JSON.stringify({step, redirected, registered})}`);
  if (JSON.stringify(etags) !== JSON.stringify([null, 'v1', 'v1', 'v1', 'v1', 'v2'])) throw Error(`Wrong ETag acceptance: ${JSON.stringify(etags)}`);
  const report = { kind: 'controlled-http-not-unleash', passed: true, steps: step, registrations: registered, redirected, etags, checkedAt: new Date().toISOString() };
  await mkdir(new URL('../artifacts/', import.meta.url), { recursive: true });
  await writeFile(new URL('../artifacts/http-smoke.json', import.meta.url), JSON.stringify(report, null, 2) + '\n');
  console.log('HTTP smoke passed: real loopback transport, incremental body limit, preserved ETag, redirects refused.');
} finally {
  server.closeAllConnections();
  await new Promise(resolve => server.close(resolve));
}
