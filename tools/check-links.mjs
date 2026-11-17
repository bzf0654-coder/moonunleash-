import { readFile, readdir, stat } from 'node:fs/promises';
const root = new URL('../', import.meta.url);
const files = ['README.md', 'README.mbt.md', 'THIRD_PARTY.md', ...(await readdir(new URL('docs/', root))).filter(n => n.endsWith('.md')).map(n => `docs/${n}`)];
let checked = 0;
for (const file of files) {
  const url = new URL(file, root);
  const content = await readFile(url, 'utf8');
  for (const match of content.matchAll(/\[[^\]]*\]\((?:<([^>]+)>|([^\s)]+))\)/g)) {
    const link = match[1] ?? match[2];
    if (/^(?:https?:|mailto:|#)/.test(link)) continue;
    const target = new URL(link, url);
    target.hash = '';
    const s = await stat(target).catch(() => null);
    if (!s?.isFile()) throw Error(`Broken local link in ${file}: ${link}`);
    checked++;
  }
}
console.log(`Verified ${checked} local documentation links in ${files.length} documents; remote URLs not checked.`);
