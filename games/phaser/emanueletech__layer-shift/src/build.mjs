// Builds dist/ (index.html + bundled main.js + public/ assets) and dist/game-web.zip for the itch.io HTML upload.
import { build } from 'esbuild';
import { mkdirSync, copyFileSync, rmSync, cpSync } from 'node:fs';
import { execSync } from 'node:child_process';

rmSync('dist', { recursive: true, force: true });
mkdirSync('dist', { recursive: true });
await build({
  entryPoints: ['src/main.js'],
  bundle: true,
  minify: true,
  format: 'iife',
  target: 'es2019',
  outfile: 'dist/main.js',
  logLevel: 'info',
});
copyFileSync('index.html', 'dist/index.html');
cpSync('public', 'dist', { recursive: true });
execSync('cd dist && zip -qr game-web.zip index.html main.js fonts');
console.log('Built dist/ and dist/game-web.zip');
