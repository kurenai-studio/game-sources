#!/usr/bin/env node
/* A static server with no dependencies, for looking at the build.
 *   node serve.mjs  →  http://localhost:8080
 * ES modules will not load over file://, which is why this exists.        */
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { join, extname, normalize } from 'node:path';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const port = Number(process.env.PORT) || 8080;
const types = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css',
                '.png':'image/png', '.json':'application/json', '.svg':'image/svg+xml' };

createServer(async (req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  const file = join(here, normalize(p).replace(/^(\.\.[/\\])+/, ''));
  try {
    const body = await readFile(file);
    res.writeHead(200, { 'content-type': types[extname(file)] || 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404, { 'content-type': 'text/plain' }); res.end('not found');
  }
}).listen(port, () => console.log(`castellan: http://localhost:${port}`));
