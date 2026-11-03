#!/usr/bin/env node
/* Castellan · build
 *
 * There is no bundler and no dependency. The whole game is one closure that
 * shares a single scope, so the "modules" in src/js are ordered fragments of
 * that closure rather than ES modules — they are concatenated in filename
 * order into src/shell.html at the @@BUNDLE@@ marker.
 *
 *   node build.mjs            → dist/castellan.html and docs/index.html
 *   node build.mjs --check    → build, then fail if anything looks wrong
 */
import { readFileSync, writeFileSync, readdirSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src  = join(here, 'src');
const jsDir = join(src, 'js');

const shell = readFileSync(join(src, 'shell.html'), 'utf8');
if (!shell.includes('/* @@BUNDLE@@ */')) {
  console.error('build: shell.html has lost its @@BUNDLE@@ marker'); process.exit(1);
}

const files = readdirSync(jsDir).filter(f => f.endsWith('.js')).sort();
if (!files.length) { console.error('build: no sources in src/js'); process.exit(1); }

const bundle = files.map(f => readFileSync(join(jsDir, f), 'utf8')).join('');
const html = shell.replace('/* @@BUNDLE@@ */', bundle) + '\n</script>\n</body>\n</html>\n';

mkdirSync(join(here, 'dist'), { recursive: true });
writeFileSync(join(here, 'index.html'), html);            // GitHub Pages serves the root
writeFileSync(join(here, 'dist', 'castellan.html'), html); // the named, downloadable artifact

const kb = (html.length / 1024).toFixed(1);
console.log(`build: ${files.length} fragments → index.html + dist/castellan.html (${kb} kB)`);

if (process.argv.includes('--check')) {
  const problems = [];
  const opens = (html.match(/\(function\(\)\{/g) || []).length;
  if (!html.includes('</html>')) problems.push('no closing </html>');
  if (!html.includes('importmap')) problems.push('the three.js importmap is missing');
  if (!opens) problems.push('the closure never opens');
  if (!/\}\)\(\);\s*<\/script>/.test(html)) problems.push('the closure never closes before </script>');
  // a crude but effective brace balance over the bundle only
  let depth = 0, inS = null, prev = '';
  for (const c of bundle) {
    if (inS) { if (c === inS && prev !== '\\') inS = null; }
    else if (c === '"' || c === "'" || c === '`') inS = c;
    else if (c === '{') depth++;
    else if (c === '}') depth--;
    prev = c;
  }
  if (depth !== 0) problems.push(`braces do not balance (${depth})`);
  if (problems.length) { problems.forEach(p => console.error('check: ' + p)); process.exit(1); }
  console.log('check: passed');
}
