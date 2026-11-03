import { readdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
let checked = 0;
for (const dir of ['dist/js','scripts']) {
  for (const file of await readdir(path.join(root, dir))) {
    if (!/\.(m?js)$/.test(file)) continue;
    const result = spawnSync(process.execPath, ['--check',path.join(root,dir,file)], { encoding:'utf8' });
    if (result.status !== 0) { console.error(result.stderr); process.exit(1); }
    checked++;
  }
}
console.log(`Syntax checked ${checked} modules.`);
