// Node transport fallback: Windows sandbox Schannel cannot acquire credentials.
// No external packages or subprocesses; all content pinned to an immutable commit.
import { mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
const revision = '9ef6efa01feabeb699857192ad8106fd7d990235';
const base = `https://raw.githubusercontent.com/Unleash/client-specification/${revision}`;
const dir = new URL('../tests/fixtures/upstream/', import.meta.url);
await mkdir(dir, { recursive: true });
const files = [];
async function download(name, source) {
  const response = await fetch(`${base}/${source}`, { signal: AbortSignal.timeout(20000) });
  if (!response.ok) throw Error(`${source}: HTTP ${response.status}`);
  const data = Buffer.from(await response.arrayBuffer());
  await writeFile(new URL(name, dir), data);
  files.push({ name, sha256: createHash('sha256').update(data).digest('hex') });
  return data;
}
const index = JSON.parse(await download('index.json', 'specifications/index.json'));
for (const name of index) {
  if (!/^\d{2}-[a-z0-9-]+\.json$/.test(name)) throw Error('Unexpected fixture name');
  await download(name, `specifications/${name}`);
}
await download('LICENSE', 'LICENSE');
await writeFile(new URL('manifest.json', dir), JSON.stringify({ repository: 'https://github.com/Unleash/client-specification', revision, files }, null, 2) + '\n');
console.log(`Fetched ${index.length} specification files into ${fileURLToPath(dir)}`);
