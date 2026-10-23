import { existsSync, readFileSync } from 'node:fs';

const requiredFiles = [
  'index.html',
  'src/main.js',
  'src/gameLogic.js',
  'src/styles.css',
  'tests/gameLogic.test.js',
  '.github/workflows/ci.yml',
  '.github/workflows/pages.yml',
  '.github/workflows/cloudflare-pages.yml',
  'README.md',
  'docs/architecture.md',
  'docs/setup.md',
  'docs/assets/generated-readme-hero.png'
];

const missing = requiredFiles.filter((file) => !existsSync(file));
if (missing.length > 0) {
  throw new Error(`Missing required files: ${missing.join(', ')}`);
}

const filesToScan = requiredFiles.filter((file) => !file.endsWith('.yml') && !file.endsWith('.png'));
for (const file of filesToScan) {
  const content = readFileSync(file, 'utf8');
  if (content.includes('\t')) {
    throw new Error(`Tabs are not allowed in ${file}`);
  }
  if (content.includes('TODO')) {
    throw new Error(`Unresolved TODO found in ${file}`);
  }
}

console.log('lint checks passed');
