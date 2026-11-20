// Read-only Docker Registry identity evidence. No docker execution, npm deps, or bearer artifacts.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

export const baseline = Object.freeze({
  version: '7.4.0',
  source: 'https://github.com/Unleash/unleash',
  revision: '77c5af4d991541a93b877ddac0554beaaf61c8c5',
  repository: 'unleashorg/unleash-server',
  index: 'sha256:4aadfc1a7366f5e7f5f9a4aa591ade7a3d1843ffd53b224ac58bf945442f4356',
  amd64: 'sha256:fd521aeb776da5577c1889514bae9d48f901e8bc6119529c643797f901f75980',
  attestation: 'sha256:67d5269fc1c174b057fc48cac2fc861a9ee6542ea8ada899aa692e7d393d7fdb',
  config: 'sha256:8f47f34458be176c3d3467bbded66f815ca341f0c92817e150ac2f9b1dcf5688',
  statement: 'sha256:eda072846a1ce1fda9de02f2664735fa4b8bb5d5858f53f2b83b8abdb3033062',
});
export const image = `${baseline.repository}@${baseline.amd64}`;
const hash = raw => `sha256:${createHash('sha256').update(raw).digest('hex')}`;

export async function verifyProvenance(directory) {
  await mkdir(directory, { recursive: true });
  const tokenURL = `https://auth.docker.io/token?service=registry.docker.io&scope=repository:${baseline.repository}:pull`;
  const auth = await fetch(tokenURL, { signal: AbortSignal.timeout(30000) });
  assert.equal(auth.status, 200, 'anonymous registry token endpoint');
  // Token and its response are deliberately never written or logged.
  const { token } = await auth.json();
  assert.equal(typeof token, 'string');
  const saved = [];
  async function get(name, kind, digest, accept) {
    const url = `https://registry-1.docker.io/v2/${baseline.repository}/${kind}/${digest}`;
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, ...(accept ? { Accept: accept } : {}) },
      redirect: 'follow', signal: AbortSignal.timeout(60000),
    });
    assert.equal(response.status, 200, `${name}: registry status`);
    // Hash ORIGINAL bytes, before JSON parsing/reformatting. Verify EVERY fetched content object.
    const raw = Buffer.from(await response.arrayBuffer());
    await writeFile(resolve(directory, `${name}.raw.json`), raw);
    const headers = Object.fromEntries(response.headers);
    // Response headers only; no request Authorization / token response.
    await writeFile(resolve(directory, `${name}.headers.json`), JSON.stringify({ url, headers }, null, 2));
    assert.equal(hash(raw), digest, `${name}: content digest`);
    if (headers['docker-content-digest']) assert.equal(headers['docker-content-digest'], digest);
    saved.push({ name, digest, bytes: raw.length, url, accept: accept ?? null });
    return JSON.parse(raw.toString('utf8'));
  }
  const index = await get('index', 'manifests', baseline.index, 'application/vnd.oci.image.index.v1+json');
  const platform = index.manifests.find(x => x.platform?.os === 'linux' && x.platform?.architecture === 'amd64');
  assert.equal(platform?.digest, baseline.amd64, 'index linux/amd64 descriptor');
  const att = index.manifests.find(x => x.digest === baseline.attestation);
  assert.equal(att?.annotations?.['vnd.docker.reference.digest'], baseline.amd64);
  assert.equal(att?.annotations?.['vnd.docker.reference.type'], 'attestation-manifest');
  const manifest = await get('amd64', 'manifests', baseline.amd64, 'application/vnd.oci.image.manifest.v1+json');
  assert.equal(manifest.config.digest, baseline.config);
  const config = await get('config', 'blobs', baseline.config);
  assert.equal(config.os, 'linux');
  assert.equal(config.architecture, 'amd64');
  const attManifest = await get('attestation', 'manifests', baseline.attestation, 'application/vnd.oci.image.manifest.v1+json');
  const statement = attManifest.layers.find(x => x.digest === baseline.statement);
  assert.ok(statement, 'pinned in-toto statement layer');
  assert.equal(statement.mediaType, 'application/vnd.in-toto+json');
  // Retain and hash attestation config too, rather than leaving that descriptor unchecked.
  await get('attestation-config', 'blobs', attManifest.config.digest);
  const provenance = await get('statement', 'blobs', baseline.statement);
  assert.equal(provenance._type, 'https://in-toto.io/Statement/v0.1');
  assert.equal(provenance.predicateType, 'https://slsa.dev/provenance/v0.2');
  assert.ok(provenance.subject.some(s => s.digest?.sha256 === baseline.amd64.slice(7)), 'subject is executed amd64 manifest');
  const metadata = provenance.predicate.metadata['https://mobyproject.org/buildkit@v1#metadata'];
  assert.equal(metadata.vcs.revision, baseline.revision);
  assert.equal(metadata.vcs.source, baseline.source);
  const result = {
    kind: 'registry-content-and-source-association', checkedAt: new Date().toISOString(),
    baseline, image, platform: 'linux/amd64', objects: saved,
    // OCI label is workflow-dispatch SHA, NOT checked-out source; do not compare it to revision.
    ociRevisionLabel: config.config?.Labels?.['org.opencontainers.image.revision'] ?? null,
    builder: provenance.predicate.builder,
    sourceRevision: metadata.vcs.revision,
    signatureVerified: false,
    reproducibleBuildVerified: false,
    provenanceCompleteness: provenance.predicate.metadata.completeness,
    provenanceReproducible: provenance.predicate.metadata.reproducible,
    caveat: 'Content hashes and producer-reported source association only; no independent signature verification or reproducible-build proof. Image layers are validated by Docker pull, not downloaded here.',
  };
  await writeFile(resolve(directory, 'provenance.json'), JSON.stringify(result, null, 2) + '\n');
  return result;
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  const directory = resolve(process.argv[2] ?? 'ci-output/server-provenance');
  try {
    await verifyProvenance(directory);
    console.log(`Verified pinned OCI chain and source association; signatures/reproducibility NOT verified. Evidence: ${directory}`);
  } catch (error) {
    await mkdir(directory, { recursive: true });
    await writeFile(resolve(directory, 'failure.txt'), String(error.stack ?? error) + '\n');
    throw error;
  }
}
