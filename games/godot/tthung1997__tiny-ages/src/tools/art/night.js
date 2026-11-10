// @open art/reference/strip_v2.png
// @nolib
// Night variant of the strip: reads the saved day PNG, applies a palette shift, saves as strip_v2_night.png.
// Run strip.js first. Proves day/night can be a palette transform rather than separate art.
var W = 384, H = 80;
var IMG = SPR.layer(0).cel(0).image;
var d = IMG.getImageData();
var out = new Uint8Array(d.length), i;
for (i = 0; i < d.length; i++) out[i] = d[i];
function g(x, y) { var j = (y * W + x) * 4; return [out[j], out[j + 1], out[j + 2]]; }
function s(x, y, r, gg, b) {
  if (x < 0 || y < 0 || x >= W || y >= H) return;
  var j = (y * W + x) * 4;
  out[j] = Math.max(0, Math.min(255, r)); out[j + 1] = Math.max(0, Math.min(255, gg)); out[j + 2] = Math.max(0, Math.min(255, b)); out[j + 3] = 255;
}
var x, y;
// remove the sun by copying sky from a clear column
for (y = 4; y < 22; y++) for (x = 343; x < 362; x++) { var dx = x - 352, dy = y - 12; if (dx * dx + dy * dy <= 64) { var c = g(330, y); s(x, y, c[0], c[1], c[2]); } }
// remember window glass (becomes lit) and self-lit colours (bulb, flames: skip the tint)
var lit = {}, keep = {};
for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
  var c2 = g(x, y), k = c2[0] + ',' + c2[1] + ',' + c2[2];
  if (k == '168,220,240') lit[y * W + x] = 1;
  if (k == '255,226,122' || k == '255,248,208' || k == '245,158,43' || k == '229,115,43') keep[y * W + x] = 1;
}
// night tint
for (y = 0; y < H; y++) for (x = 0; x < W; x++) { if (keep[y * W + x]) continue; var p = g(x, y); s(x, y, p[0] * 0.36 + 10, p[1] * 0.44 + 16, p[2] * 0.74 + 52); }
// lit windows + dithered glow
var k2, kk;
for (k2 in lit) { kk = parseInt(k2, 10); s(kk % W, Math.floor(kk / W), 255, 209, 102); }
for (k2 in lit) {
  kk = parseInt(k2, 10); var wx = kk % W, wy = Math.floor(kk / W);
  for (var oy = -2; oy <= 2; oy++) for (var ox = -2; ox <= 2; ox++) {
    if (lit[(wy + oy) * W + wx + ox]) continue;
    if (((wx + ox + wy + oy) & 1) == 0 && Math.abs(ox) + Math.abs(oy) <= 3) { var q = g(wx + ox, wy + oy); s(wx + ox, wy + oy, q[0] + 30, q[1] + 22, q[2] - 5); }
  }
}
// campfire glow (solid core, dithered rim)
var fx = 162, fy = 69;
for (y = fy - 18; y <= fy + 10; y++) for (x = fx - 24; x <= fx + 24; x++) {
  if (x < 0 || y < 0 || x >= W || y >= H || keep[y * W + x]) continue;
  var dd = Math.sqrt((x - fx) * (x - fx) + ((y - fy) * 1.6) * ((y - fy) * 1.6)), f = 1 - dd / 22;
  if (f <= 0) continue;
  var q2 = g(x, y);
  if (f > 0.55) s(x, y, q2[0] + 70 * f, q2[1] + 38 * f, q2[2] - 10);
  else if (f > 0.2 && ((x + y) & 1) == 0) s(x, y, q2[0] + 45 * f, q2[1] + 25 * f, q2[2] - 6);
}
// crescent moon
for (y = 4; y < 22; y++) for (x = 343; x < 362; x++) { var mx = x - 352, my = y - 12; if (mx * mx + my * my <= 30) { var cx2 = x - 355, cy2 = y - 10; if (cx2 * cx2 + cy2 * cy2 > 22) s(x, y, 244, 241, 222); } }
// stars (only on dark sky pixels)
var seed = 4;
function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; }
for (var n = 0; n < 70; n++) {
  x = Math.floor(rnd() * W); y = Math.floor(rnd() * 44); var pc = g(x, y);
  if (pc[0] < 70 && pc[2] < 190 && (x < 340 || x > 365 || y > 24)) {
    var big = rnd() < 0.3; s(x, y, 255, 255, big ? 255 : 210);
    if (big) { s(x + 1, y, 150, 170, 230); s(x - 1, y, 150, 170, 230); s(x, y + 1, 150, 170, 230); s(x, y - 1, 150, 170, 230); }
  }
}
IMG.putImageData(out);
SPR.saveAs(DIR + 'art/reference/strip_v2_night.png');
console.log('night saved');
