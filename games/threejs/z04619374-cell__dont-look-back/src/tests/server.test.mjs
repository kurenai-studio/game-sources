import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
process.env.PORT = '0';
const { server } = await import('../scripts/serve.mjs');
await once(server, 'listening');
const base = `http://127.0.0.1:${server.address().port}`;
test('static preview serves actual game and modules, never project source', async () => {
  try {
    const page = await fetch(base + '/'); assert.equal(page.status, 200);
    assert.match(await page.text(), /Don't Look Back/);
    const module = await fetch(base + '/js/model.js'); assert.equal(module.status, 200);
    assert.match(module.headers.get('content-type'), /javascript/);
    assert.equal((await fetch(base + '/%2e%2e%2fREADME.md')).status,403);
    assert.equal((await fetch(base + '/missing')).status,404);
  } finally { server.close(); }
});
