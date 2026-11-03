import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const outputDirectory = join(process.cwd(), 'pages-dist');
await rm(outputDirectory, { recursive: true, force: true });
await mkdir(outputDirectory, { recursive: true });

let html = await readFile('public/index.html', 'utf8');
html = html
  .replaceAll('"/node_modules/', '"./node_modules/')
  .replace('src="/src/', 'src="./src/');
await writeFile(join(outputDirectory, 'index.html'), html);

await cp('src', join(outputDirectory, 'src'), { recursive: true });
await cp('node_modules/three', join(outputDirectory, 'node_modules/three'), { recursive: true });
