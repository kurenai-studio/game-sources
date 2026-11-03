/**
 * Servidor mínimo que recibe capturas del juego y las escribe a disco.
 * Hace falta porque el panel del navegador corre la pestaña oculta: rAF queda
 * congelado y las capturas nativas salen negras, así que el propio juego
 * renderiza a mano y nos manda el PNG por POST.
 *
 *   node tools/capturador.mjs [carpetaDestino]
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const destino = process.argv[2] || '/tmp/capturas-imperios';
fs.mkdirSync(destino, { recursive: true });

const servidor = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') { res.writeHead(204).end(); return; }
  if (req.method !== 'POST') { res.writeHead(405).end('solo POST'); return; }

  const nombre = (new URL(req.url, 'http://x').searchParams.get('nombre') || 'captura')
    .replace(/[^a-zA-Z0-9_.-]/g, '_');
  const trozos = [];
  req.on('data', (c) => trozos.push(c));
  req.on('end', () => {
    try {
      const cuerpo = Buffer.concat(trozos).toString('utf8');
      const b64 = cuerpo.replace(/^data:image\/\w+;base64,/, '');
      const archivo = path.join(destino, `${nombre}.png`);
      fs.writeFileSync(archivo, Buffer.from(b64, 'base64'));
      console.log(`[captura] ${archivo}  ${(b64.length / 1365).toFixed(0)} KB`);
      res.writeHead(200).end(archivo);
    } catch (e) {
      console.error('[captura] error', e.message);
      res.writeHead(500).end(e.message);
    }
  });
});

servidor.listen(8912, '127.0.0.1', () => console.log('capturador escuchando en http://127.0.0.1:8912'));
