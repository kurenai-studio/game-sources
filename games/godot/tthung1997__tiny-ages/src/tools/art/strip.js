// @open art/reference/strip_v2.png
// @canvas 384x80
// Day strip: 384x80 native, ground line at y=56. Foot position of each object = (cx, foot).
// Drawn as separate layers (back to front: sky, far hills, near hills, tree line, ground+props).
// The composite is strip_v2.png; each layer is also saved under art/reference/layers/ so the
// engine can show only some of them (for example a transparent sky in desktop strip mode).
seed = 5;
var W = 384, H = 80, G = 56;
var SKY = new Buf(W, H), FAR = new Buf(W, H), NEAR = new Buf(W, H), TREES = new Buf(W, H);
var S = new Buf(W, H), x, y, i; // S = ground + props + villagers

// sky (5 dithered bands), sun, clouds
var sky = ['#78bde6', '#8fcaea', '#a6d5ee', '#bde1f0', '#dbeef2'];
for (y = 0; y < G; y++) {
  var bi = Math.min(4, Math.floor(y / 11)), t = y % 11;
  for (x = 0; x < W; x++) { var c = sky[bi]; if (t >= 9 && bi < 4 && ((x + y) & 1) == 0) c = sky[bi + 1]; SKY.px(x, y, c); }
}
SKY.ell(352, 12, 6, 6, '#fff6c2'); SKY.ell(352, 12, 4.5, 4.5, '#ffe27a');
cloud(SKY, 60, 13, 1); cloud(SKY, 190, 9, 1.1); cloud(SKY, 272, 17, 0.8);

// two hill layers + round-bump tree line
for (x = 0; x < W; x++) {
  var r1 = Math.round(38 + 5 * Math.sin(x / 37) + 2 * Math.sin(x / 13 + 1));
  for (y = r1; y < G; y++) FAR.px(x, y, y < r1 + 1 ? '#b5d0bb' : '#a1bfac');
  var r2 = Math.round(45 + 4 * Math.sin(x / 29 + 2) + 1.5 * Math.sin(x / 11));
  for (y = r2; y < G; y++) NEAR.px(x, y, y < r2 + 1 ? '#9cc28d' : '#84a97b');
}
for (x = -2; x < W + 4; x += 6) { var yy2 = 51 + Math.floor(rnd() * 3); TREES.ell(x, yy2 + 2, 4.2, 4.2, '#4a8a55'); TREES.ell(x - 1, yy2, 3.2, 3, '#5fa267'); }
for (y = G; y < H; y++) for (x = 0; x < W; x++) TREES.d[(y * W + x) * 4 + 3] = 0; // ground covers these rows

// ground (3 bands), tufts, flowers, path
for (y = G; y < H; y++) { var gc = y < G + 2 ? '#9ad05f' : (y < G + 13 ? '#74b24f' : '#63a043'); for (x = 0; x < W; x++) S.px(x, y, gc); }
for (i = 0; i < 200; i++) { x = Math.floor(rnd() * W); y = G + 2 + Math.floor(rnd() * (H - G - 2)); var lt = rnd() < 0.5; S.px(x, y, lt ? '#8fc95a' : '#528f3a'); if (rnd() < 0.5) S.px(x, y - 1, lt ? '#8fc95a' : '#528f3a'); }
for (i = 0; i < 46; i++) { x = Math.floor(rnd() * W); y = G + 4 + Math.floor(rnd() * (H - G - 6)); var fc = ['#ff8fb1', '#ffe27a', '#ffffff', '#c9a0ff'][Math.floor(rnd() * 4)]; S.px(x, y, fc); S.px(x, y + 1, '#3a7a3a'); }
for (x = 14; x < 306; x++) { var py = Math.round(75 + 1.5 * Math.sin(x / 22)); S.rect(x, py - 1, 1, 3, '#d9b57a'); S.px(x, py - 1, '#bf9558'); S.px(x, py + 1, '#bf9558'); if (rnd() < 0.05) S.px(x, py, '#f0d4a0'); }

// field soil, river (diagonal bank), lily pads
S.rect(78, 59, 40, 11, '#8a5a36'); for (y = 60; y < 70; y += 3) S.rect(78, y, 40, 1, '#6f4528');
function edge(yv) { return Math.round(326 - (yv - G) * 1.2); }
for (y = G; y < H; y++) for (x = edge(y); x < W; x++) S.px(x, y, x < edge(y) + 2 ? '#e8d4a0' : '#4f93c4');
for (i = 0; i < 50; i++) { y = G + 1 + Math.floor(rnd() * (H - G - 1)); x = edge(y) + 3 + Math.floor(rnd() * (W - edge(y) - 6)); S.rect(x, y, 3, 1, rnd() < 0.6 ? '#8cc8e8' : '#3b79ad'); }
S.ell(350, 70, 4, 2, '#4fae5f'); S.px(350, 69, '#ff8fb1'); S.ell(334, 76, 3, 1.5, '#4fae5f');

// objects: add(bufW, bufH, centreX, footY, drawFn, {sh: shadowRadius, flip})
var objs = [];
function add(w, h, cx, foot, fn, o) { o = o || {}; objs.push({ w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, fy: foot, cx: cx }); }
add(16, 26, 10, 66, pine, { sh: 6 }); add(22, 26, 30, 68, rtree, { sh: 8 }); add(12, 8, 44, 70, bush, { sh: 5 });
add(11, 8, 14, 77, sheep, { sh: 5 }); add(11, 8, 28, 78, sheep, { sh: 5, flip: 1 });
add(36, 38, 60, 66, house, { sh: 15 });
for (var fx = 82; fx <= 112; fx += 6) { add(5, 7, fx, 64, wheat, {}); add(5, 7, fx + 3, 69, wheat, {}); }
add(27, 27, 100, 74, vil({ pal: PAL.red, role: 'farmer', pose: 'walk', f: 0 }), { sh: 5 });
add(26, 18, 140, 66, tent, { sh: 11 }); add(10, 9, 162, 73, fire, { sh: 4 }); add(7, 7, 128, 77, rabbit, { sh: 3 });
add(27, 27, 186, 74, vil({ pal: PAL.blue, role: 'explorer', pose: 'walk', f: 2 }), { sh: 5 });
add(40, 34, 216, 66, shop2, { sh: 19 });
add(27, 27, 236, 75, vil({ pal: PAL.yellow, role: 'builder', pose: 'hammer', f: 0 }), { sh: 5, flip: 1 });
add(9, 12, 214, 22, bulb, {});
add(16, 26, 258, 65, pine, { sh: 6 }); add(22, 26, 278, 69, rtree, { sh: 8 }); add(12, 8, 300, 66, bush, { sh: 5 });
add(27, 27, 262, 76, vil({ pal: PAL.green, role: 'woodcutter', pose: 'chop', f: 1 }), { sh: 5 });
add(27, 27, 292, 74, vil({ pal: PAL.purple, role: 'fisher', pose: 'fish', f: 0 }), { sh: 5 });

objs.sort(function (a, b) { return a.fy - b.fy; }); // back-to-front by foot line
for (i = 0; i < objs.length; i++) { var ob = objs[i]; if (ob.sh) S.ell(ob.cx, ob.fy, ob.sh, 1.5, '#4a8a38'); }
for (i = 0; i < objs.length; i++) {
  ob = objs[i]; var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(S, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
S.line(305, 60, 312, 75, '#e8eaf0', 1); S.rect(311, 75, 2, 2, '#e5533d'); // fishing line + bobber

// composite (back to front) -> strip_v2.png, then each layer under layers/
var COMP = new Buf(W, H), IMG = SPR.layer(0).cel(0).image;
var stack = [SKY, FAR, NEAR, TREES, S];
for (i = 0; i < stack.length; i++) blit(COMP, stack[i], 0, 0);
IMG.putImageData(COMP.d);
SPR.save();
var names = ['sky', 'far_hills', 'near_hills', 'trees', 'ground'];
for (i = 0; i < stack.length; i++) {
  IMG.putImageData(stack[i].d);
  SPR.saveAs(DIR + 'art/reference/layers/strip_' + names[i] + '.png');
}
console.log('strip done');
