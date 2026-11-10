// Tiny Ages art library for LibreSprite scripts.
// Not run directly: tools/art/bundle.py prepends an app.open(...) header and
// concatenates this file with a scene script. Pure ES5-style JS, no imports.

var OUT = '#2b2d42';
var SK = '#f7d4b4', SKD = '#e0a98a', WOOD = '#8a5a36', WOODL = '#a6703f';

// ---- colour + pixel buffer -------------------------------------------------
var _c = {};
function col(h) {
  if (typeof h !== 'string') return h;
  var r = _c[h];
  if (!r) { var n = parseInt(h.slice(1), 16); r = _c[h] = [(n >> 16) & 255, (n >> 8) & 255, n & 255, 255]; }
  return r;
}

function Buf(w, h) { this.w = w; this.h = h; this.d = new Uint8Array(w * h * 4); }
Buf.prototype.px = function (x, y, c) {
  x = Math.floor(x); y = Math.floor(y);
  if (x < 0 || y < 0 || x >= this.w || y >= this.h) return;
  var i = (y * this.w + x) * 4, k = col(c);
  this.d[i] = k[0]; this.d[i + 1] = k[1]; this.d[i + 2] = k[2]; this.d[i + 3] = 255;
};
Buf.prototype.a = function (x, y) {
  if (x < 0 || y < 0 || x >= this.w || y >= this.h) return 0;
  return this.d[(y * this.w + x) * 4 + 3];
};
Buf.prototype.rect = function (x, y, w, h, c) {
  for (var j = 0; j < h; j++) for (var i = 0; i < w; i++) this.px(x + i, y + j, c);
};
Buf.prototype.ell = function (cx, cy, rx, ry, c) {
  for (var y = Math.floor(cy - ry); y <= Math.ceil(cy + ry); y++)
    for (var x = Math.floor(cx - rx); x <= Math.ceil(cx + rx); x++) {
      var dx = (x - cx) / rx, dy = (y - cy) / ry;
      if (dx * dx + dy * dy <= 1) this.px(x, y, c);
    }
};
// Triangle: apex column cx, first row `top`, h rows, half-width hw at the base. Left half cl, right half cd.
Buf.prototype.tri = function (cx, top, h, hw, cl, cd) {
  for (var r = 0; r < h; r++) {
    var w = Math.round(hw * (r + 1) / h);
    for (var x = cx - w; x <= cx + w; x++) this.px(x, top + r, x < cx ? cl : cd);
  }
};
Buf.prototype.line = function (x0, y0, x1, y1, c, t) {
  t = t || 1;
  var dx = Math.abs(x1 - x0), dy = Math.abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, e = dx - dy;
  while (true) {
    this.rect(x0, y0, t, t, c);
    if (x0 == x1 && y0 == y1) break;
    var e2 = 2 * e;
    if (e2 > -dy) { e -= dy; x0 += sx; }
    if (e2 < dx) { e += dx; y0 += sy; }
  }
};

// 1px outline (OUT) around every opaque pixel; result is 2px larger in each axis.
function outlined(b, c) {
  var o = new Buf(b.w + 2, b.h + 2), x, y;
  for (y = 0; y < b.h; y++) for (x = 0; x < b.w; x++)
    if (b.a(x, y)) { var i = (y * b.w + x) * 4; o.px(x + 1, y + 1, [b.d[i], b.d[i + 1], b.d[i + 2]]); }
  for (y = 0; y < o.h; y++) for (x = 0; x < o.w; x++) {
    if (o.a(x, y)) continue;
    if (b.a(x - 2, y - 1) || b.a(x, y - 1) || b.a(x - 1, y - 2) || b.a(x - 1, y)) o.px(x, y, c);
  }
  return o;
}
function mirror(b) {
  var o = new Buf(b.w, b.h);
  for (var y = 0; y < b.h; y++) for (var x = 0; x < b.w; x++) {
    var s = (y * b.w + x) * 4, d = (y * b.w + (b.w - 1 - x)) * 4;
    for (var k = 0; k < 4; k++) o.d[d + k] = b.d[s + k];
  }
  return o;
}
function blit(dst, src, ox, oy) {
  for (var y = 0; y < src.h; y++) for (var x = 0; x < src.w; x++) {
    var s = (y * src.w + x) * 4;
    if (!src.d[s + 3]) continue;
    var X = ox + x, Y = oy + y;
    if (X < 0 || Y < 0 || X >= dst.w || Y >= dst.h) continue;
    var d = (Y * dst.w + X) * 4;
    dst.d[d] = src.d[s]; dst.d[d + 1] = src.d[s + 1]; dst.d[d + 2] = src.d[s + 2]; dst.d[d + 3] = 255;
  }
}

// Seeded RNG so every run reproduces the same pixels. Scene scripts set `seed`.
var seed = 1;
function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; }

// ---- villager palettes -----------------------------------------------------
var PAL = {
  red:    { shirt: '#d8574a', shirtD: '#b23f35', pants: '#5b4a8a', hair: '#8a4b2a', hairD: '#6a3a20', hairL: '#a8643a' },
  blue:   { shirt: '#4a86c8', shirtD: '#3768a3', pants: '#4a5a3a', hair: '#e0b04a', hairD: '#b8862d', hairL: '#f3cf72' },
  green:  { shirt: '#6aa84f', shirtD: '#4e8a38', pants: '#6a4a3a', hair: '#3a2a24', hairD: '#241914', hairL: '#5a463c' },
  yellow: { shirt: '#e8b53a', shirtD: '#c4921f', pants: '#4a4a6a', hair: '#d9d9e0', hairD: '#b0b0bc', hairL: '#ffffff' },
  purple: { shirt: '#9b59b6', shirtD: '#7d3f99', pants: '#4a3a5a', hair: '#c24a6a', hairD: '#9a3552', hairL: '#e06a8a' },
  teal:   { shirt: '#3fa7a0', shirtD: '#2d827c', pants: '#5a4a3a', hair: '#2f5fa0', hairD: '#234a80', hairL: '#4f7fc0' },
  orange: { shirt: '#e8873a', shirtD: '#c46a22', pants: '#4a5a6a', hair: '#b84a2a', hairD: '#8f3820', hairL: '#d8683f' },
  pink:   { shirt: '#e888a8', shirtD: '#c46a88', pants: '#5a4a6a', hair: '#f0d060', hairD: '#c8a638', hairL: '#fff090' },
  // Cave Age: furs and hides (use with fur: true)
  furBrown: { shirt: '#a8703f', shirtD: '#7a4c28', pants: '#7a4c28', hair: '#2f2a26', hairD: '#1c1917', hairL: '#4a423c' },
  furTan:   { shirt: '#d0a068', shirtD: '#a8784a', pants: '#a8784a', hair: '#6a3a20', hairD: '#4a2814', hairL: '#8a5a38' },
  furGrey:  { shirt: '#b4b1b9', shirtD: '#8a8792', pants: '#8a8792', hair: '#d9d9e0', hairD: '#b0b0bc', hairL: '#ffffff' },
  furOchre: { shirt: '#cf7a46', shirtD: '#a05830', pants: '#a05830', hair: '#3a2a24', hairD: '#241914', hairL: '#5a463c' },
  // Settled Age: woven tunics (use with cloth: true); `trim` is the coloured border and collar
  clothMira: { shirt: '#e6dcc2', shirtD: '#c2b48e', trim: '#b8573a', pants: '#7a5a3a', hair: '#6a3a20', hairD: '#4a2814', hairL: '#8a5a38' },
  clothTheo: { shirt: '#6f8fae', shirtD: '#56738f', trim: '#e6dcc2', pants: '#5a4a3a', hair: '#3a2a24', hairD: '#241914', hairL: '#5a463c' },
  clothWren: { shirt: '#9db08a', shirtD: '#7e9270', trim: '#e6dcc2', pants: '#6a5a4a', hair: '#d9d9e0', hairD: '#b0b0bc', hairL: '#ffffff' }
};
// Later ages' outfits (use with outfit: 'field' | 'town' | 'fittings'): the same hair as the
// villager's other palettes, new clothes. `patch` is the scrap sewn on a field tunic; `cloak` is the
// town cloak and `trim` its red border (the colour of dyed cloth, drawn for everyone).
function palWith(base, extra) {
  var r = {}, k;
  for (k in base) r[k] = base[k];
  for (k in extra) r[k] = extra[k];
  return r;
}
PAL.fieldMira = palWith(PAL.clothMira, { shirt: '#c2b484', shirtD: '#998c60', patch: '#8a6038' });
PAL.fieldTheo = palWith(PAL.clothTheo, { shirt: '#b8ac82', shirtD: '#928a5c', patch: '#7a5a3a' });
PAL.fieldWren = palWith(PAL.clothWren, { shirt: '#bdb288', shirtD: '#968e62', patch: '#8f6a40' });
PAL.townMira = palWith(PAL.clothMira, { shirt: '#dccba0', shirtD: '#b8a57a', cloak: '#9a5a3c', cloakD: '#744230', trim: '#c0392b' });
PAL.townTheo = palWith(PAL.clothTheo, { shirt: '#c9a45a', shirtD: '#a3823f', cloak: '#55708f', cloakD: '#3f5670', trim: '#c0392b' });
PAL.townWren = palWith(PAL.clothWren, { shirt: '#e0d6b8', shirtD: '#bcb08e', cloak: '#6a8a5a', cloakD: '#4f6a43', trim: '#c0392b' });
// Iron Age checked wool (use with outfit: 'checked' | 'iron'): `shirt` and `shirtD` are the tunic's
// ground, `chkA` and `chkB` the two lines of the check, `cloak` and `cloakD` the pinned cloak.
PAL.checkedMira = palWith(PAL.clothMira, { shirt: '#8c9bb3', shirtD: '#6b7a94', chkA: '#4f5b86', chkB: '#d1a548', cloak: '#b08a46', cloakD: '#8a6a32', pants: '#4a4f63' });
PAL.checkedTheo = palWith(PAL.clothTheo, { shirt: '#bba66c', shirtD: '#968350', chkA: '#3f4f7a', chkB: '#7d8aa0', cloak: '#5b6f8a', cloakD: '#44546b', pants: '#3f4658' });
PAL.checkedWren = palWith(PAL.clothWren, { shirt: '#a9b1bb', shirtD: '#868e9a', chkA: '#566a8a', chkB: '#b8903f', cloak: '#6f7e72', cloakD: '#566456', pants: '#4a4f58' });
var BRONZE = '#d9a23a', BRONZE_L = '#f7d56a', BRONZE_D = '#9a6a1f';
var IRON_D = '#2c313b', IRON_M = '#555d6b', IRON_L = '#9aa5b5';
// Classical Age linen (use with outfit: 'linen' | 'civic'): `shirt` is the pale tunic, `trim` its hem
// band, `cloak` and `cloakD` the mantle draped over one shoulder.
PAL.linenMira = palWith(PAL.clothMira, { shirt: '#efe6d0', shirtD: '#cbbf9f', trim: '#b8402f', cloak: '#7c4a68', cloakD: '#5a3450' });
PAL.linenTheo = palWith(PAL.clothTheo, { shirt: '#e8e0c8', shirtD: '#c4baa0', trim: '#2f5f8a', cloak: '#4f6e8f', cloakD: '#3a5270' });
PAL.linenWren = palWith(PAL.clothWren, { shirt: '#eee6cc', shirtD: '#c9c0a2', trim: '#3f7a4a', cloak: '#c9953a', cloakD: '#a07428' });

// ---- villager (style A: mini chibi, 16px tall) ------------------------------
// o = { pal, pose: idle|walk|chop|hammer|fish|spear, f: frame,
//       role: farmer|builder|explorer|woodcutter|fisher|gatherer|undefined,
//       hair: short|tuft|long|bun|pony,
//       fur: true (hide tunic, bare legs, bone necklace), cloth: true (woven tunic, trousers; the
//       palette needs `trim`), stone: true (stone tool heads),
//       outfit: 'field' (hemp tunic, rope belt, rolled sleeves, bare feet; palette needs `patch`) |
//       'town' (long belted tunic with a red hem, hooded cloak, boots; palette needs `cloak`,
//       `cloakD`, `trim`) | 'fittings' (town plus bronze pin, buckle and arm rings) |
//       'checked' (long checked wool tunic over trousers, a cloak pinned at the shoulder, laced
//       shoes; palette needs `chkA`, `chkB`, `cloak`, `cloakD`) | 'iron' (checked plus a dark iron
//       brooch, buckle and boot studs) }
// Draw into a Buf(27, 27); feet land on row 26, body centre column 13, faces right.
// Use mirror() for left-facing. Place with outlined(buf, OUT).
function vil(o) {
  var cl = o.pal;
  return function (b) {
    var cx = 13, yb = 26, lh = 3, lw = 2, legTop = yb - lh + 1, bh = 5, bw = 6, rx = 5, ry = 5;
    var pose = o.pose || 'idle', f = o.f || 0;
    var wk = pose == 'walk' ? f : -1, dy = (wk == 1 || wk == 3) ? 1 : 0;
    var bodyTop = legTop - bh - dy, hx = cx + 1, hcy = bodyTop - ry + 2, bx = cx - 3;
    var l1 = cx - 3, l2 = cx + 1, h1 = lh, h2 = lh;
    var legc = o.fur ? SKD : cl.pants, headc = o.stone ? '#8d8a93' : '#aab0bc', headl = o.stone ? '#bdbbc2' : '#e4e8ee';
    if (wk == 0) { l1 -= 2; l2 += 2; }
    if (wk == 1) h1 = lh - 1;
    if (wk == 2) { l1 += 2; l2 -= 2; }
    if (wk == 3) h2 = lh - 1;
    var ofit = o.outfit, field = ofit == 'field', brz = ofit == 'fittings', town = ofit == 'town' || brz;
    var irn = ofit == 'iron', chk = ofit == 'checked' || irn;
    var civ = ofit == 'civic', lin = ofit == 'linen' || civ;
    var sole = o.fur ? '#5a4636' : '#4a3224';
    if (field) { legc = SKD; sole = '#c98a6a'; }
    if (town) { legc = '#6b4a2f'; sole = '#3a281a'; }
    if (chk) sole = '#7a5a3a';
    if (lin) { legc = SKD; sole = '#8a5a36'; }
    function leg(x, h) {
      b.rect(x, legTop - dy, lw, h - 1 + dy, legc); b.rect(x, legTop + h - 1, lw + 1, 1, sole);
      if (town) b.rect(x, legTop - dy, lw, 1, '#9a7448'); // boot cuff
      if (lin) b.px(x + 1, legTop + h - 2, '#c9a06a'); // a sandal strap
      if (chk) { // a laced shoe, studded with iron on the finer outfit
        b.px(x + 1, legTop + h - 1, '#e8dcb8');
        if (irn) { b.px(x, legTop + h - 1, IRON_L); b.px(x + 2, legTop + h - 1, IRON_L); }
      }
    }
    leg(l1, h1); leg(l2, h2);
    if (chk) { // the cloak hanging down the back, no hood
      b.rect(bx - 3, bodyTop, 3, bh + 1, cl.cloakD); b.rect(bx - 3, bodyTop, 1, bh + 1, cl.cloak);
    }
    if (town) { // the hood bunched behind the head, and the cloak hanging down the back, red at its edge
      b.ell(hx - 2, hcy + 1, rx + 1, ry + 0.5, cl.cloak);
      b.rect(bx - 3, bodyTop, 3, bh + 2, cl.cloakD); b.rect(bx - 3, bodyTop, 1, bh + 2, cl.cloak);
      b.rect(bx - 3, bodyTop + bh + 1, 3, 1, cl.trim);
    }
    // an arm: a sleeve line from the shoulder to the hand; rolled back on field clothes, ringed in bronze on fittings
    function arm(x0, y0, x1, y1) {
      if (!ofit) { b.line(x0, y0, x1, y1, cl.shirt, 2); return; }
      if (field) {
        var mx = Math.round(x0 + (x1 - x0) * 0.45), my = Math.round(y0 + (y1 - y0) * 0.45);
        b.line(x0, y0, mx, my, cl.shirt, 2); b.line(mx, my, x1, y1, SK, 2); b.rect(mx, my, 2, 2, '#ece0b8');
        return;
      }
      b.line(x0, y0, x1, y1, cl.shirt, 2);
      if (brz) { var qx = Math.round(x0 + (x1 - x0) * 0.8), qy = Math.round(y0 + (y1 - y0) * 0.8); b.rect(qx, qy, 2, 2, BRONZE); b.px(qx, qy, BRONZE_L); }
    }
    if (o.role == 'explorer') { b.rect(bx - 3, bodyTop, 3, 5, WOOD); b.rect(bx - 3, bodyTop, 3, 1, WOODL); b.px(bx - 2, bodyTop + 2, '#e8c46a'); }
    if (o.role == 'gatherer') { b.rect(bx - 3, bodyTop + 1, 3, 4, '#c9a06a'); b.px(bx - 2, bodyTop + 2, '#a8763e'); b.px(bx - 3, bodyTop + 3, '#a8763e'); b.px(bx - 2, bodyTop, '#c8433a'); b.px(bx - 1, bodyTop, '#6a3f8f'); }
    var ba = bh - 2, fa = bh - 2;
    if (wk == 0) fa = 2;
    if (wk == 2) ba = 2;
    b.rect(bx - 1, bodyTop + 1, 2, ba, cl.shirtD); b.rect(bx - 1, bodyTop + 1 + ba, 2, 1, SKD);
    if (field) { b.rect(bx - 1, bodyTop + 2, 2, 1, '#cfc29a'); b.rect(bx - 1, bodyTop + 3, 2, ba - 1, SKD); }
    if (brz) b.rect(bx - 1, bodyTop + ba, 2, 1, BRONZE_D);
    b.rect(bx, bodyTop, bw, bh, cl.shirt); b.rect(bx, bodyTop + bh - 2, bw, 2, cl.shirtD); b.rect(bx, bodyTop + bh - 1, bw, 1, o.fur ? '#4a3224' : '#6b4a2f');
    if (o.fur) {
      for (var hm = 0; hm < bw; hm += 2) b.px(bx + hm, bodyTop + bh, cl.shirtD); // ragged hem
      b.px(bx + 1, bodyTop, '#f4ecd8'); b.px(bx + 2, bodyTop, '#f4ecd8'); // bone necklace
    }
    if (o.cloth) { // Settled Age: a woven tunic with a coloured border, a collar and a hem to the knee
      b.rect(bx, bodyTop + bh - 3, bw, 1, cl.trim);
      b.px(bx + 1, bodyTop, cl.trim); b.px(bx + 2, bodyTop, cl.trim);
      b.rect(bx, bodyTop + bh, bw, 1, cl.shirtD);
    }
    if (field) { // a hemp tunic to the knee, a rope belt with its end hanging, a leather scrap sewn on
      b.rect(bx, bodyTop, bw, bh, cl.shirt); b.rect(bx, bodyTop + bh, bw, 1, cl.shirtD);
      b.rect(bx, bodyTop + bh - 2, bw, 1, '#ece0b8'); b.px(bx + bw - 2, bodyTop + bh - 1, '#ece0b8');
      b.rect(bx + 1, bodyTop + bh - 1, 2, 2, cl.patch);
    }
    if (town) { // a long belted tunic flared to a red hem, the cloak across the shoulders
      b.rect(bx, bodyTop, bw, bh, cl.shirt); b.rect(bx, bodyTop + bh - 1, bw, 1, '#6b4a2f');
      b.rect(bx - 1, bodyTop + bh, bw + 2, 1, cl.trim);
      b.rect(bx - 1, bodyTop + 2, bw + 1, 1, cl.cloak); b.rect(bx - 1, bodyTop + 3, 1, 2, cl.cloakD);
      if (brz) { b.rect(bx + bw - 3, bodyTop + bh - 1, 2, 1, BRONZE_L); b.px(bx + 3, bodyTop + 2, BRONZE_L); b.px(bx + 3, bodyTop + 3, BRONZE_D); }
    }
    if (chk) { // a long checked tunic to the knee, a leather belt, the cloak pinned over one shoulder
      b.rect(bx, bodyTop, bw, bh + 1, cl.shirt);
      for (var cy = 0; cy <= bh; cy++) for (var cxx = 0; cxx < bw; cxx++) {
        if (cxx % 3 == 1) b.px(bx + cxx, bodyTop + cy, cl.chkA);
        else if (cy == 2 || cy == bh) b.px(bx + cxx, bodyTop + cy, cl.chkB);
      }
      b.rect(bx, bodyTop + bh - 1, bw, 1, '#4a3626');
      b.rect(bx, bodyTop, bw - 1, 2, cl.cloak); b.rect(bx, bodyTop + 2, 2, 1, cl.cloakD);
      b.px(bx + bw - 3, bodyTop + 3, irn ? IRON_D : '#e4e8ee'); b.px(bx + bw - 2, bodyTop + 3, irn ? IRON_M : '#9aa3b0');
      if (irn) { b.px(bx + 2, bodyTop + bh - 1, IRON_L); b.px(bx + 3, bodyTop + bh - 1, IRON_D); }
    }
    if (lin) { // Classical: a pale linen tunic to the knee with a coloured hem band and a cord belt, a mantle draped over one shoulder
      b.rect(bx, bodyTop, bw, bh + 1, cl.shirt);
      b.rect(bx, bodyTop + bh, bw, 1, cl.trim);
      b.rect(bx, bodyTop + bh - 2, bw, 1, '#d9c9a0'); b.px(bx + bw - 2, bodyTop + bh - 1, '#d9c9a0');
      b.rect(bx, bodyTop, bw - 1, 2, cl.cloak); b.rect(bx, bodyTop + 2, 2, 2, cl.cloak); b.px(bx + 1, bodyTop + 4, cl.cloakD);
      if (civ) { b.rect(bx, bodyTop + 1, bw - 1, 1, cl.trim); b.px(bx + bw - 3, bodyTop + 2, BRONZE_L); b.px(bx + bw - 3, bodyTop + 3, BRONZE_D); }
    }
    if (o.role == 'woodcutter') for (var yy = 0; yy < bh - 1; yy++) for (var xx = 0; xx < bw; xx++) if ((xx + yy) % 3 == 0) b.px(bx + xx, bodyTop + yy, cl.shirtD);
    if (o.role == 'builder') { b.rect(bx + 1, bodyTop + 1, bw - 2, bh - 2, '#b57a42'); b.rect(bx + 1, bodyTop + 1, bw - 2, 1, '#d9a566'); }
    if (o.role == 'explorer') { b.rect(bx, bodyTop, bw, 1, '#3fa7a0'); b.rect(bx + bw - 2, bodyTop, 2, 3, '#3fa7a0'); }
    var sx = bx + bw, sy = bodyTop + 1;
    function tool(hxp, hyp, tx, ty, kind) {
      arm(sx - 1, sy, hxp, hyp); b.rect(hxp, hyp, 2, 2, SK); b.line(hxp, hyp, tx, ty, WOOD, 1);
      if (kind == 'axe') { b.rect(tx - 1, ty - 1, 3, 3, headc); b.px(tx - 1, ty - 1, headl); }
      else if (kind == 'hammer') b.rect(tx - 1, ty - 1, 3, 2, headc);
    }
    if (pose == 'chop') {
      if (f == 0) tool(sx + 2, sy - 2, sx + 2, sy - 8, 'axe');
      else if (f == 1) tool(sx + 2, sy - 1, sx + 6, sy - 5, 'axe');
      else tool(sx + 2, sy + 1, sx + 7, sy + 2, 'axe');
    } else if (pose == 'hammer') {
      if (f == 0) tool(sx + 2, sy - 1, sx + 3, sy - 6, 'hammer'); else tool(sx + 2, sy + 1, sx + 7, sy + 3, 'hammer');
    } else if (pose == 'fish') {
      var up = f == 0 ? 0 : 1;
      arm(sx - 1, sy, sx + 2, sy + 1 - up); b.rect(sx + 2, sy + 1 - up, 2, 2, SK);
      b.line(sx + 3, sy + 1 - up, sx + 10, sy - 7 - up, WOOD, 1); // rod tip = (sx+10, sy-7-up)
    } else if (pose == 'spear') { // held upright, stone tip above the head
      arm(sx - 1, sy, sx + 2, sy + 1); b.rect(sx + 2, sy + 1, 2, 2, SK);
      b.line(sx + 3, yb, sx + 3, 3, WOOD, 1); b.rect(sx + 3, 0, 1, 3, '#cfd8e0'); b.px(sx + 3, 3, '#c9a06a');
    } else {
      b.rect(bx + bw - 1, bodyTop + 1, 2, fa, cl.shirt); b.rect(bx + bw - 1, bodyTop + 1 + fa, 2, 1, SK);
      if (field) { b.rect(bx + bw - 1, bodyTop + 2, 2, 1, '#ece0b8'); b.rect(bx + bw - 1, bodyTop + 3, 2, fa - 2, SK); }
      if (brz) b.rect(bx + bw - 1, bodyTop + fa, 2, 1, BRONZE);
    }
    b.ell(hx - 2, hcy + 1, rx, ry, cl.hairD); // back hair
    if (o.hair == 'long') { b.rect(hx - rx - 2, hcy - 1, 4, ry + 4, cl.hairD); b.rect(hx - rx - 2, hcy - 1, 1, ry + 4, cl.hair); b.rect(hx - rx - 2, hcy + ry + 2, 4, 1, cl.hair); }
    if (o.hair == 'pony') { b.rect(hx - rx - 2, hcy - 1, 2, 5, cl.hairD); b.px(hx - rx - 2, hcy - 1, '#d8433a'); b.px(hx - rx - 2, hcy, '#d8433a'); b.px(hx - rx - 3, hcy + 2, cl.hairD); }
    for (var y = hcy - ry; y <= hcy + ry; y++) for (var x = hx - rx; x <= hx + rx; x++) {
      var dx = (x - hx) / rx, dy2 = (y - hcy) / ry;
      if (dx * dx + dy2 * dy2 > 1) continue;
      var hb = hcy - 0.25 * ry - (x - hx) * 0.3; // slanted fringe line
      if (y <= hb) b.px(x, y, (y <= hcy - ry * 0.7) ? cl.hairL : cl.hair);
      else if (y <= hb + 1) b.px(x, y, SKD);
      else b.px(x, y, (y == hcy + ry || x < hx - rx * 0.7) ? SKD : SK);
    }
    if (o.hair == 'tuft') { b.px(hx - 1, hcy - ry - 1, cl.hair); b.px(hx, hcy - ry - 1, cl.hair); b.px(hx, hcy - ry - 2, cl.hair); b.px(hx + 1, hcy - ry - 2, cl.hairL); }
    if (o.hair == 'bun') { b.ell(hx - rx + 2, hcy - ry, 2.3, 2.3, cl.hair); b.px(hx - rx + 1, hcy - ry - 1, cl.hairL); b.px(hx - rx + 2, hcy - ry - 1, cl.hairL); }
    var ey = hcy + 1; // face: dot eyes + blush
    b.rect(hx - 1, ey, 1, 2, OUT); b.rect(hx + 2, ey, 1, 2, OUT); b.px(hx - 2, ey + 2, '#f29b9b'); b.px(hx + 3, ey + 2, '#f29b9b');
    if (o.role == 'farmer') { b.ell(hx, hcy - ry + 1, rx - 1, 2.6, '#e8c46a'); b.rect(hx - rx - 1, hcy - ry + 2, 2 * rx + 3, 2, '#c99a3d'); b.rect(hx - rx + 1, hcy - ry + 2, 2 * rx - 1, 1, '#a8452f'); }
    if (o.role == 'builder') b.rect(hx - rx + 1, hcy - ry + 3, 2 * rx - 1, 1, '#d8433a');
    if (o.role == 'fisher') { b.rect(hx - rx + 1, hcy - ry, 2 * rx - 1, 3, '#6c8cb8'); b.rect(hx - rx, hcy - ry + 3, 2 * rx + 1, 1, '#547099'); }
  };
}

// ---- props (each draws into its own Buf; wrap with outlined()) ---------------
function pine(b) { b.rect(6, 21, 4, 5, WOOD); b.rect(6, 21, 1, 5, WOODL); b.tri(8, 0, 9, 4, '#4fb06a', '#2f8a55'); b.tri(8, 6, 9, 6, '#4fb06a', '#2f8a55'); b.tri(8, 12, 10, 7, '#4fb06a', '#2f8a55'); b.px(8, 0, '#7ad88a'); }
function rtree(b) { b.rect(9, 16, 4, 10, WOOD); b.rect(9, 16, 1, 10, WOODL); b.ell(3, 12, 3, 3, '#2f8545'); b.ell(19, 12, 3, 3, '#2f8545'); b.ell(11, 10, 10, 8.5, '#2f8545'); b.ell(11, 8.5, 9, 7, '#3f9a52'); b.ell(9.5, 6.5, 6, 4.5, '#58b05f'); b.ell(8, 5, 3, 2, '#82d874'); b.px(14, 9, '#e8504a'); b.px(7, 12, '#e8504a'); b.px(16, 12, '#e8504a'); }
function bush(b) { b.ell(6, 5, 6, 3.2, '#2f8545'); b.ell(5, 4, 4.5, 3, '#3f9a52'); b.ell(4, 3, 2.5, 1.8, '#7cd070'); b.px(8, 5, '#e8504a'); b.px(5, 6, '#e8504a'); }
function house(b) {
  b.rect(24, 6, 5, 9, '#b86a4a'); b.rect(23, 5, 7, 2, '#8f4f38'); b.ell(26, 3, 2, 1.6, '#f0f4f8'); b.ell(29, 1, 1.6, 1.4, '#e2e8ee');
  b.tri(17, 4, 14, 17, '#e0614a', '#b8473a'); b.rect(0, 18, 35, 3, '#c24f3b'); b.rect(0, 20, 35, 1, '#8f3a2d');
  b.rect(3, 21, 29, 16, '#f4dcae'); b.rect(3, 34, 29, 2, '#e0c28c'); b.rect(3, 21, 1, 16, WOODL); b.rect(31, 21, 1, 16, WOODL);
  b.rect(14, 25, 8, 12, WOOD); b.ell(18, 25, 4, 3.2, WOOD); b.rect(18, 22, 1, 15, '#6f4528'); b.px(20, 32, '#ffd166');
  b.ell(8, 28, 3.2, 3.2, '#a8dcf0'); b.rect(8, 25, 1, 7, WOOD); b.rect(5, 28, 7, 1, WOOD);
  b.ell(27, 28, 3.2, 3.2, '#a8dcf0'); b.rect(27, 25, 1, 7, WOOD); b.rect(24, 28, 7, 1, WOOD);
  b.rect(5, 31, 7, 2, WOOD); b.px(6, 30, '#e8504a'); b.px(8, 30, '#ffd166'); b.px(10, 30, '#e8504a'); b.rect(3, 36, 29, 2, '#9aa0aa');
}
function tent(b) {
  b.tri(13, 2, 16, 13, '#f2e2b8', '#d8c28c');
  for (var r = 12; r < 16; r++) { var w = Math.round(13 * (r + 1) / 16); b.rect(13 - w, 2 + r, 2 * w + 1, 1, r % 2 ? '#d8574a' : '#b23f35'); }
  b.tri(13, 9, 9, 3, '#4a3a2a', '#3a2c20'); b.px(13, 0, '#e0614a'); b.px(14, 0, '#e0614a'); b.px(13, 1, WOOD);
}
function fire(b) { b.rect(0, 6, 10, 2, WOOD); b.px(0, 5, '#9aa0aa'); b.px(9, 5, '#9aa0aa'); b.tri(5, 0, 7, 2, '#f59e2b', '#e5732b'); b.tri(5, 3, 4, 1, '#ffe27a', '#ffe27a'); }
function sheep(b) { b.rect(2, 6, 1, 2, '#4a4150'); b.rect(5, 6, 1, 2, '#4a4150'); b.rect(7, 6, 1, 2, '#4a4150'); b.ell(4.5, 3.5, 4.5, 3, '#f6f6f0'); b.ell(2, 2.5, 2, 2, '#f6f6f0'); b.ell(5, 1.8, 2, 1.8, '#f6f6f0'); b.rect(1, 5, 7, 1, '#d6d6cc'); b.ell(9, 4, 2, 2.2, '#4a4150'); b.px(9, 3, '#ffffff'); b.px(8, 1, '#4a4150'); }
function rabbit(b) { b.ell(3, 4.5, 3, 2.5, '#c9a98a'); b.ell(5, 3, 2, 2, '#c9a98a'); b.rect(5, 0, 1, 2, '#c9a98a'); b.rect(6, 0, 1, 2, '#e8a8a0'); b.px(0, 4, '#ffffff'); b.px(6, 3, OUT); }
function bulb(b) { b.ell(4, 4, 4, 4, '#ffe27a'); b.px(2, 2, '#fff8d0'); b.px(3, 1, '#fff8d0'); b.rect(3, 9, 3, 2, '#9aa0aa'); b.rect(3, 11, 3, 1, '#6a6f7a'); }
function wheat(b) { b.rect(2, 3, 1, 4, '#8fb843'); b.ell(2, 2, 1.4, 2, '#e6c84a'); b.px(1, 5, '#8fb843'); b.px(3, 4, '#8fb843'); }
function cloud(S, cx, cy, s) { S.ell(cx, cy + 2 * s, 9 * s, 3 * s, '#dbe9ee'); S.ell(cx, cy, 8 * s, 3.5 * s, '#f7fbf7'); S.ell(cx - 5 * s, cy - 1 * s, 4.5 * s, 3 * s, '#f7fbf7'); S.ell(cx + 3 * s, cy - 3 * s, 5 * s, 3.5 * s, '#f7fbf7'); }

// ---- workshop: construction stages (Buf 42x36; base row 28..33) ---------------
function shopBase(b) { b.rect(0, 28, 40, 6, '#9aa0aa'); for (var x = 5; x < 40; x += 8) b.rect(x, 28, 1, 6, '#7c8190'); b.rect(0, 28, 40, 1, '#bcc0cc'); }
function planks(b, x, y) { b.rect(x, y + 4, 12, 2, '#d9a566'); b.rect(x + 1, y + 2, 10, 2, '#c58f50'); b.rect(x + 2, y, 8, 2, '#d9a566'); }
function shopPosts(b) { b.rect(1, 8, 3, 20, '#b57a42'); b.rect(19, 8, 3, 20, '#b57a42'); b.rect(37, 8, 3, 20, '#b57a42'); b.rect(1, 8, 38, 3, '#9a6633'); }
function shop0(b) { // site: stakes, rope, lumber, sawhorse
  b.rect(0, 32, 40, 2, '#b7a98a'); b.rect(0, 32, 40, 1, '#d8cba8');
  for (var i = 0; i < 3; i++) { b.rect(2 + i * 18, 24, 1, 9, WOOD); b.px(2 + i * 18, 24, '#e0614a'); }
  b.line(2, 26, 38, 26, '#f0e4c0', 1); planks(b, 24, 26);
  b.line(4, 31, 10, 26, '#a8763e', 2); b.line(14, 31, 8, 26, '#a8763e', 2); b.rect(5, 25, 8, 2, '#c58f50');
}
function shop1(b) { shopBase(b); shopPosts(b); b.line(4, 27, 18, 12, '#b57a42', 2); planks(b, 24, 22); } // frame
function shop2(b) { // half-built
  shopBase(b); shopPosts(b);
  b.rect(4, 11, 15, 17, '#f4dcae'); for (var y = 14; y < 28; y += 4) b.rect(4, y, 15, 1, '#d9b985');
  b.ell(11, 18, 3, 3, '#a8dcf0'); b.rect(11, 15, 1, 6, WOOD); b.rect(8, 18, 7, 1, WOOD);
  b.line(23, 28, 36, 11, '#b57a42', 2); b.rect(24, 25, 12, 2, '#d9a566'); b.rect(25, 23, 10, 2, '#c58f50'); b.rect(26, 21, 8, 2, '#d9a566');
  b.line(1, 8, 10, 1, '#9a6633', 2); b.line(10, 1, 38, 9, '#9a6633', 2); b.line(19, 8, 19, 4, '#9a6633', 1); b.tri(10, 2, 6, 8, '#e0614a', '#b8473a');
}
function shop3(b) { // complete
  b.rect(30, 3, 5, 8, '#b86a4a'); b.rect(29, 2, 7, 2, '#8f4f38'); b.ell(32, 0, 2, 1.5, '#f0f4f8');
  b.tri(20, 2, 12, 20, '#e0614a', '#b8473a'); b.rect(0, 13, 41, 3, '#c24f3b'); b.rect(0, 15, 41, 1, '#8f3a2d');
  b.rect(3, 16, 35, 12, '#f4dcae'); b.rect(3, 16, 1, 12, '#a6703f'); b.rect(37, 16, 1, 12, '#a6703f');
  b.rect(16, 18, 9, 10, WOOD); b.ell(20, 18, 4.5, 3.2, WOOD); b.rect(20, 15, 1, 13, '#6f4528'); b.px(23, 24, '#ffd166');
  b.ell(9, 22, 3.2, 3.2, '#a8dcf0'); b.rect(9, 19, 1, 7, WOOD); b.rect(6, 22, 7, 1, WOOD);
  b.ell(32, 22, 3.2, 3.2, '#a8dcf0'); b.rect(32, 19, 1, 7, WOOD); b.rect(29, 22, 7, 1, WOOD);
  b.rect(40, 16, 1, 10, WOOD); b.rect(34, 17, 7, 1, WOOD); b.rect(34, 17, 1, 4, WOOD); b.rect(33, 21, 4, 3, '#d9a566'); b.px(34, 22, '#9aa0aa'); b.px(35, 22, '#9aa0aa');
  shopBase(b);
}

// ---- Cave Age props -----------------------------------------------------------
var ROCK = '#8d8a93', ROCKD = '#6f6c78', ROCKL = '#a8a5ae', OCHRE = '#b8573a';

function handprint(b, x, y) { // red-ochre hand on the cave wall
  b.rect(x + 1, y + 3, 3, 3, OCHRE); b.rect(x, y + 1, 1, 3, OCHRE); b.rect(x + 1, y, 1, 3, OCHRE);
  b.rect(x + 2, y, 1, 3, OCHRE); b.rect(x + 3, y + 1, 1, 3, OCHRE); b.rect(x + 4, y + 4, 1, 2, OCHRE);
}

// Cliff with the cave mouth, 100x54. The home of the settlement; foot on the bottom row. A rock
// outcrop, not a boulder: a stepped, uneven ridge, layered strata tilting a little, facets that
// catch the light on their upward slopes, cracks, moss and ivy along the ledges, scree at the foot,
// and a rough mouth under an overhang. It keeps its own random generator, so redrawing it never
// shifts the pixels of anything drawn after it. The mouth stays where the firelight expects it
// (cave_strip.js firelit): x 26..42, y 46..53.
function cliff(b) {
  var seedc = 11;
  function r() { seedc = (seedc * 1103515245 + 12345) & 0x7fffffff; return seedc / 0x7fffffff; }
  var STR = ['#908d96', '#8a8792', '#9a97a0', '#84818c', '#928f99'], LIT = '#b4b1b9', LITD = '#a09da7', SHADE = '#6f6c78', DEEP = '#5f5c68';
  var x, y, i, k;
  // silhouette: key heights from the bottom, jittered, interpolated, then terraced
  var keys = [[0, 1], [4, 8], [9, 19], [15, 30], [23, 39], [31, 42], [41, 46], [52, 51], [60, 49], [66, 41], [72, 44], [80, 40], [88, 25], [94, 11], [99, 1]];
  var top = [], h, a, c, t;
  for (i = 0; i < keys.length; i++) keys[i] = [keys[i][0], keys[i][1] + (i == 0 || i == keys.length - 1 ? 0 : Math.round((r() - 0.5) * 4))];
  for (x = 0; x < 100; x++) {
    for (k = 0; k < keys.length - 1 && keys[k + 1][0] < x; k++);
    a = keys[k]; c = keys[Math.min(k + 1, keys.length - 1)];
    t = c[0] == a[0] ? 0 : (x - a[0]) / (c[0] - a[0]);
    h = a[1] + (c[1] - a[1]) * t + Math.sin(x / 3.1) * 0.9 + Math.sin(x / 1.7 + 2) * 0.5;
    top.push(54 - (x < 4 || x > 95 ? Math.max(1, Math.round(h)) : Math.max(2, Math.round(h / 2) * 2))); // terraced in steps of two rows, tapering to a point at both ends
  }
  // strata tones, one per band, plus the drift that tilts the layers
  var band = [];
  for (i = 0; i < 14; i++) band.push(STR[Math.floor(r() * STR.length)]);
  for (x = 0; x < 100; x++) {
    var slopeR = (top[Math.min(x + 1, 99)] - top[x]) + (top[Math.min(x + 2, 99)] - top[x]); // >0: falling to the right
    for (y = top[x]; y < 54; y++) {
      var d = y - top[x], bi = Math.floor((y + Math.floor(x * 0.1)) / 6), col = band[bi % band.length];
      if (x > 64) col = x > 84 ? SHADE : '#7a7782';
      if (d < 2) col = slopeR < 0 || slopeR == 0 ? LIT : (d == 0 ? LITD : DEEP);
      else if (d < 4 && slopeR > 1) col = SHADE;
      else if (r() < 0.04) col = r() < 0.5 ? LITD : SHADE;
      if (((y + Math.floor(x * 0.1)) % 6) == 0 && d > 2 && r() < 0.7) col = DEEP; // a strata line, with breaks
      b.px(x, y, col);
    }
  }
  // cracks: jagged runs down from the ridge
  for (i = 0; i < 5; i++) {
    x = 8 + Math.floor(r() * 84); y = top[x] + 2;
    var len = 7 + Math.floor(r() * 10);
    for (k = 0; k < len && y < 50; k++) { b.px(x, y, DEEP); y++; if (r() < 0.45) x += r() < 0.5 ? -1 : 1; }
  }
  // scree and boulders at the foot
  var boulders = [[7, 51, 3, 2.5], [14, 51, 3, 2.5], [57, 51, 5, 2.5], [92, 51, 5, 3], [96, 50, 3, 3], [47, 52, 3, 1.8]];
  for (i = 0; i < boulders.length; i++) { var q = boulders[i]; b.ell(q[0], q[1], q[2], q[3], i % 2 ? '#7f7c86' : ROCK); b.ell(q[0] - 1, q[1] - 1, q[2] * 0.6, q[3] * 0.5, LITD); }
  // the mouth: a rough opening, lopsided, under an overhang
  var left = 18, right = 50, cx = 34;
  for (x = left; x <= right; x++) {
    var u = (x - cx) / (x < cx ? 16 : 14);
    if (Math.abs(u) > 1) continue;
    var ot = 53 - Math.round(18 * Math.sqrt(1 - u * u)) + (x % 5 == 0 ? 1 : 0) - (x % 7 == 0 ? 1 : 0);
    for (y = ot; y < 54; y++) b.px(x, y, '#2a2433');
    b.px(x, ot - 1, DEEP); b.px(x, ot - 2, '#4a4752'); // the underside of the overhang
    if (x % 3 != 0) b.px(x, ot - 3, LITD);
  }
  b.ell(cx, 49, 8, 4.5, '#3a3040'); // a paler floor inside
  for (y = 40; y < 54; y++) b.px(left + (y > 48 ? 1 : 0), y, LITD); // the lit left jamb
  b.px(right, 50, DEEP); b.px(right - 1, 44, DEEP); b.px(right, 46, DEEP);
  // moss and ivy along the ledges
  for (x = 3; x < 97; x++) {
    var peak = top[x] <= top[Math.max(x - 2, 0)] && top[x] <= top[Math.min(x + 2, 99)];
    if (peak || r() < 0.06) {
      var mw = 2 + r() * 3;
      b.ell(x, top[x], mw, 1.2 + r(), r() < 0.5 ? '#4f9a5a' : '#58b05f'); b.px(x - 1, top[x] - 1, '#7cd070');
      if (r() < 0.5) { var iy = top[x] + 1, ln = 3 + Math.floor(r() * 5); for (k = 0; k < ln; k++) b.px(x + (k % 3 == 1 ? 1 : 0), iy + k, k % 2 ? '#3f7f4a' : '#4f9a5a'); }
    }
  }
  handprint(b, 62, 28); handprint(b, 70, 31); handprint(b, 66, 36);
  b.px(78, 30, OCHRE); b.px(79, 31, OCHRE); b.px(80, 30, OCHRE); b.px(84, 34, OCHRE); b.px(85, 35, OCHRE);
}

// Woolly mammoth, 42x28, facing right.
function mammoth(b) {
  b.rect(9, 21, 5, 7, '#5a3e30'); b.rect(16, 22, 5, 6, '#5a3e30'); b.rect(25, 22, 5, 6, '#5a3e30'); b.rect(31, 21, 4, 7, '#5a3e30');
  b.rect(9, 27, 5, 1, '#3a2a22'); b.rect(16, 27, 5, 1, '#3a2a22'); b.rect(25, 27, 5, 1, '#3a2a22'); b.rect(31, 27, 4, 1, '#3a2a22');
  b.ell(20, 13, 15, 10, '#6a4a3a'); b.ell(31, 11, 8, 8, '#6a4a3a'); b.ell(18, 8, 10, 4.5, '#8a6044');
  for (var x = 8; x < 31; x += 2) b.rect(x, 21 + ((x / 2) & 1), 2, 3, '#5a3e30'); // shaggy underside
  b.ell(27, 13, 3, 4, '#5a3e30'); b.px(34, 9, '#1c1917');
  b.rect(36, 14, 3, 8, '#6a4a3a'); b.rect(37, 22, 3, 2, '#6a4a3a'); b.px(39, 24, '#6a4a3a'); // trunk
  b.line(35, 17, 40, 20, '#f4ecd8', 1); b.line(40, 20, 39, 23, '#f4ecd8', 1); // tusk
  b.px(5, 12, '#5a3e30'); b.px(4, 14, '#5a3e30');
}

// Hide shelter, 28x22: a stitched hide cone over crossed pole tips, with a dark doorway.
function leanto(b) {
  b.line(11, 0, 15, 5, WOOD, 1); b.line(17, 0, 13, 5, WOOD, 1);
  b.tri(14, 4, 18, 12, '#d6b47a', '#b08a58');
  b.line(14, 6, 14, 20, '#8a6a44', 1); b.line(14, 6, 8, 20, '#8a6a44', 1); b.line(14, 6, 20, 20, '#8a6a44', 1);
  b.rect(19, 13, 3, 3, '#a8845a'); b.px(10, 12, '#a8845a'); b.px(14, 7, '#f4ecd8');
  b.tri(14, 13, 9, 3, '#2a2433', '#2a2433');
}

// Meat/hide drying rack, 22x20.
function dryrack(b) {
  b.rect(2, 6, 2, 14, WOOD); b.rect(18, 6, 2, 14, WOOD); b.rect(0, 5, 22, 2, '#6f4528');
  var xs = [5, 8, 11, 14]; for (var i = 0; i < xs.length; i++) { b.rect(xs[i], 7, 2, 6 + (i % 3), '#c0504a'); b.rect(xs[i], 12 + (i % 3), 2, 1, '#8f3a2d'); }
  b.rect(16, 7, 2, 8, '#c9a66b'); b.rect(16, 14, 2, 1, '#a8845a');
}

// Lookout: rock outcrop with a wooden platform and ladder, 26x34. Platform surface is row 12.
function lookout(b) {
  b.ell(13, 29, 13, 6, ROCK); b.ell(10, 27, 8, 3, ROCKL); b.rect(1, 29, 24, 5, ROCKD);
  b.rect(4, 14, 2, 18, '#a8763e'); b.rect(12, 14, 2, 18, '#a8763e'); b.rect(20, 14, 2, 18, '#a8763e');
  b.rect(1, 12, 24, 3, '#c79a5f'); b.rect(1, 14, 24, 1, '#8c5f31');
  for (var x = 4; x < 24; x += 4) b.px(x, 12, '#a8763e');
  b.rect(1, 6, 1, 6, '#8c5f31'); b.rect(24, 6, 1, 6, '#8c5f31'); b.rect(1, 6, 24, 1, '#8c5f31');
  b.line(22, 15, 25, 31, '#6f4528', 1);
  for (var y = 18; y < 31; y += 3) b.rect(22 + Math.round((y - 15) / 5), y, 3, 1, '#c79a5f');
}

// Flat knapping stone with flint chips, 18x10.
function knapspot(b) {
  b.ell(9, 6, 9, 3.2, ROCK); b.ell(8, 5, 6, 1.8, ROCKL);
  b.px(2, 8, '#cfd8e0'); b.px(5, 9, '#6b7280'); b.px(13, 9, '#cfd8e0'); b.px(15, 8, '#6b7280'); b.px(9, 2, '#cfd8e0');
  b.px(12, 4, '#3a4452'); b.px(13, 4, '#3a4452');
}

// Fire pit with a stone ring and crossed logs, 16x14. `frame` (0-3) is the flame's flicker.
var FLAMES = [
  { cx: 8, top: 0, h: 9, ix: 8, spark: [[5, 3, '#ffe27a'], [11, 2, '#f59e2b']] },
  { cx: 9, top: 1, h: 8, ix: 9, spark: [[5, 4, '#ffe27a'], [12, 3, '#f59e2b']] },
  { cx: 7, top: 0, h: 9, ix: 7, spark: [[11, 4, '#ffe27a'], [4, 2, '#f59e2b']] },
  { cx: 8, top: 2, h: 7, ix: 8, spark: [[8, 0, '#f59e2b'], [11, 3, '#ffe27a']] }
];
function firepit(b, frame) {
  var i, a, sx, sy, fl = FLAMES[frame || 0];
  for (i = 0; i < 8; i++) { a = i * Math.PI / 4; sy = 10 + Math.sin(a) * 2.5; if (Math.sin(a) <= 0) b.ell(8 + Math.cos(a) * 6.5, sy, 1.8, 1.4, ROCKD); }
  b.ell(8, 10, 5, 2, '#3a2a22'); b.line(4, 10, 12, 8, WOOD, 2); b.line(5, 8, 12, 11, '#6f4528', 2);
  b.tri(fl.cx, fl.top, fl.h, 3, '#f59e2b', '#e5732b'); b.tri(fl.ix, 4, 5, 1, '#ffe27a', '#ffe27a');
  for (i = 0; i < fl.spark.length; i++) b.px(fl.spark[i][0], fl.spark[i][1], fl.spark[i][2]);
  for (i = 0; i < 8; i++) { a = i * Math.PI / 4; if (Math.sin(a) > 0) { sx = 8 + Math.cos(a) * 6.5; sy = 10 + Math.sin(a) * 2.5; b.ell(sx, sy, 1.8, 1.4, ROCK); b.px(sx - 1, sy - 1, ROCKL); } }
}

// The strange flower: three tall stalks with violet blossoms, 12x12.
function strangeflower(b) {
  var s = [[2, 6], [6, 9], [10, 5]];
  for (var i = 0; i < s.length; i++) {
    var x = s[i][0], h = s[i][1];
    b.rect(x, 11 - h, 1, h, '#3a7a3a'); b.px(x - 1, 11 - Math.floor(h / 2), '#58b05f'); b.px(x + 1, 11 - Math.floor(h / 3), '#58b05f');
    b.ell(x, 11 - h, 2.4, 2, '#b07ce8'); b.px(x, 11 - h, '#ffe27a'); b.px(x - 1, 11 - h - 1, '#d8b8ff');
  }
}

function rocks(b) { b.ell(3, 3, 3, 2.2, ROCK); b.px(2, 2, ROCKL); b.ell(7, 4, 2, 1.5, ROCKD); }

// Construction site marker: two stakes with a rope and a pile of poles, 22x10.
function buildsite(b) {
  b.rect(2, 2, 1, 8, WOOD); b.px(2, 2, '#e0614a'); b.rect(18, 2, 1, 8, WOOD); b.px(18, 2, '#e0614a');
  b.line(2, 4, 18, 4, '#f0e4c0', 1);
  b.rect(6, 7, 10, 2, '#d9a566'); b.rect(7, 5, 8, 2, '#c58f50'); b.rect(8, 9, 8, 1, '#8c5f31');
}

// Tilled field with green sprouts, 44x10.
function field(b) {
  b.rect(0, 2, 44, 8, '#8a5a36');
  for (var y = 3; y < 10; y += 3) b.rect(0, y, 44, 1, '#6f4528');
  for (var x = 3; x < 42; x += 5) for (var r = 0; r < 3; r++) { b.px(x, 2 + r * 3, '#6fbf4a'); b.px(x, 1 + r * 3, '#9bdf6a'); }
  b.px(0, 2, ROCK); b.px(43, 2, ROCK); b.px(0, 9, ROCK); b.px(43, 9, ROCK);
}

// A freshly planted sprout (the strange flower before it blooms), 12x12.
function sprout(b) { b.rect(6, 8, 1, 3, '#3a7a3a'); b.px(5, 8, '#58b05f'); b.px(7, 7, '#58b05f'); b.px(4, 7, '#7cd070'); b.px(8, 6, '#7cd070'); }
function stump(b) { // 10x8 chopped pine stump with a pale cut top
  b.rect(1, 3, 8, 4, WOOD); b.rect(1, 3, 1, 4, WOODL); b.px(6, 5, '#6a4326');
  b.ell(5, 3, 4.5, 2, '#d9a566'); b.ell(5, 3, 2.5, 1, '#c58f50'); }
function fallenlog(b) { // 18x7 fallen trunk with a cut end and a broken branch
  b.rect(0, 2, 18, 4, WOOD); b.rect(0, 2, 18, 1, WOODL); b.ell(1, 4, 1.5, 2, '#d9a566');
  b.px(7, 3, '#6a4326'); b.px(12, 4, '#6a4326'); b.rect(11, 0, 1, 3, WOOD); b.px(12, 0, WOODL); }
function reeds(b) { // 8x13 reed clump with cattail heads
  b.rect(1, 3, 1, 10, '#9bbb55'); b.rect(3, 1, 1, 12, '#86a94c'); b.rect(5, 4, 1, 9, '#9bbb55');
  b.rect(7, 2, 1, 11, '#86a94c'); b.rect(3, 0, 1, 3, '#8a5a36'); b.rect(7, 1, 1, 3, '#8a5a36');
  b.px(2, 6, '#c4dc82'); b.px(6, 7, '#c4dc82'); b.px(0, 8, '#c4dc82'); }
