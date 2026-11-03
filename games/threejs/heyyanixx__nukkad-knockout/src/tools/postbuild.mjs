// After "vite build": write the real file list into site/sw.js so the game works offline after the first visit.
import { readdirSync, statSync, readFileSync, writeFileSync } from 'node:fs';
import { join, relative } from 'node:path';
const SITE = new URL('../site/', import.meta.url).pathname;
const walk = (d) => readdirSync(d).flatMap((f) => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p) : [p]; });
const files = walk(SITE).map((p) => './' + relative(SITE, p)).filter((p) => !/sw\.js$|og\.png$|\.txt$|icon-512/.test(p));
const sw = join(SITE, 'sw.js');
let src = readFileSync(sw, 'utf8');
// pages are cached by their folder URL (the host redirects /x/index.html -> /x/, and a redirected response can't answer a navigation)
const urls = [...new Set(files.map((f) => f.replace(/index\.html$/, '')))];
src = src.replace(/const SHELL = \[[^\]]*\];/, 'const SHELL = ' + JSON.stringify(urls) + ';');
writeFileSync(sw, src);
console.log('precache', files.length, 'files');
