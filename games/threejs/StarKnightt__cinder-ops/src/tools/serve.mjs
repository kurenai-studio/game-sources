import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const PORT = +(process.argv[2] || 8099);
const ROOT = path.resolve('.');
const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript',
  '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp',
};

http.createServer((rq, rs) => {
  const rel = decodeURI(rq.url.split('?')[0]).replace(/^\/+/, '');
  const f = path.resolve(ROOT, rel || 'index.html');
  if (!f.startsWith(ROOT)) { rs.writeHead(403); return rs.end(); }
  fs.readFile(f, (e, d) => {
    if (e) { rs.writeHead(404, { 'content-type': 'text/plain' }); return rs.end('not found'); }
    rs.writeHead(200, {
      'content-type': TYPES[path.extname(f)] || 'application/octet-stream',
      'cache-control': 'no-cache',
    });
    rs.end(d);
  });
}).listen(PORT, () => console.log(`cinder-ops → http://localhost:${PORT}/`));
