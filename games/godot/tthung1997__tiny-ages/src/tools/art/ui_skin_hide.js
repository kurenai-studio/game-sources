// @open art/reference/ui_skin_hide.png
// @canvas 384x192
// The Cave Age panel skin (docs: ages V7/V8), one atlas -> game/assets/ui/skin_hide.png:
//   (0,0,384,160)            the panel: a stretched hide with torn sides, a bone rail top and
//                            bottom lashed with sinew, an ochre handprint
//   y=164: four 16x16 stitched-leather button states (normal, hover, pressed, disabled)
//          at x = 0, 16, 32, 48 (a 9-patch with 4 px margins)
//   y=164: the bone close button, 14x14, normal at x=64 and hover at x=78
//   y=164: 10x10 resource icons: wood at x=96, food at x=106
// The regions are mirrored in game/scripts/ui/panel_skin.gd. Keep the panel at the size of
// PanelHost (WIDTH x HEIGHT).
seed = 17;
var IMG = SPR.layer(0).cel(0).image;
var PW = 384, PH = 160;
var A = new Buf(384, 192);
var P = new Buf(PW, PH);
var x, y, i;

// ---- the hide ---------------------------------------------------------------------------
var HIDE = '#c9a36b', BONE = '#efe6cf', BONEL = '#fffbee', BONED = '#cdc0a0', SINEW = '#6a4326', SINEWL = '#8a6a46', OCHRE = '#b8573a';
P.rect(0, 0, PW, PH, HIDE);
for (i = 0; i < 70; i++) P.ell(Math.floor(rnd() * PW), Math.floor(rnd() * PH), 4 + rnd() * 10, 2 + rnd() * 4, rnd() < 0.5 ? '#c49c64' : '#cfa972');
for (i = 0; i < 620; i++) P.px(Math.floor(rnd() * PW), Math.floor(rnd() * PH), rnd() < 0.5 ? '#b48c58' : '#dcba84');
for (i = 0; i < 40; i++) { x = Math.floor(rnd() * PW); y = Math.floor(rnd() * PH); P.px(x, y, '#a07c4c'); P.px(x + 1, y, '#a07c4c'); } // hair follicles
// torn left and right edges, outlined
var lo = [], ro = [];
for (y = 0; y < PH; y++) {
  var a = y == 0 ? 3 : lo[y - 1] + Math.floor(rnd() * 3) - 1; a = Math.max(2, Math.min(5, a)); lo.push(a);
  var b = y == 0 ? 3 : ro[y - 1] + Math.floor(rnd() * 3) - 1; b = Math.max(2, Math.min(5, b)); ro.push(b);
}
for (y = 0; y < PH; y++) {
  for (x = 0; x < lo[y]; x++) P.d[(y * PW + x) * 4 + 3] = 0;
  for (x = PW - ro[y]; x < PW; x++) P.d[(y * PW + x) * 4 + 3] = 0;
  P.px(lo[y] - 1, y, OUT); P.px(PW - ro[y], y, OUT);
}
// ---- bone rails with knobs and sinew lashings --------------------------------------------
function rail(y0) {
  P.rect(6, y0, PW - 12, 7, BONE);
  P.rect(6, y0, PW - 12, 1, OUT); P.rect(6, y0 + 6, PW - 12, 1, OUT);
  P.rect(6, y0 + 1, PW - 12, 1, BONEL); P.rect(6, y0 + 5, PW - 12, 1, BONED);
  for (var kx = 40; kx < PW - 40; kx += 29 + Math.floor(rnd() * 20)) P.px(kx, y0 + 3, BONED); // grain
  for (var side = 0; side < 2; side++) {
    var kc = side == 0 ? 3 : PW - 4;
    P.ell(kc, y0 + 3, 4, 4, OUT); P.ell(kc, y0 + 3, 3, 3, BONE); P.px(kc - 1, y0 + 2, BONEL); P.px(kc + 1, y0 + 4, BONED);
  }
  var lashes = [26, PW - 36];
  for (var l = 0; l < lashes.length; l++) for (var k = 0; k < 4; k++) {
    P.line(lashes[l] + k * 3, y0, lashes[l] + k * 3 + 2, y0 + 6, SINEW, 1);
    P.px(lashes[l] + k * 3 + 1, y0 + 2, SINEWL);
  }
}
rail(0); rail(PH - 7);
// ---- an ochre handprint near the close button --------------------------------------------
function hand(hx, hy, c) {
  P.ell(hx + 4, hy + 8, 4, 3.5, c);
  P.rect(hx, hy + 2, 2, 5, c); P.rect(hx + 2, hy, 2, 7, c); P.rect(hx + 4, hy, 2, 7, c); P.rect(hx + 6, hy + 2, 2, 5, c);
  P.rect(hx + 8, hy + 6, 2, 3, c);
  P.px(hx + 3, hy + 9, '#c9a36b'); P.px(hx + 5, hy + 3, '#c9a36b'); P.px(hx + 1, hy + 4, '#c9a36b');
}
hand(PW - 52, 12, OCHRE);
// a brush stroke under where the title sits
for (x = 12; x < 110; x++) P.px(x, 25 + (x > 90 ? 1 : 0), x < 100 ? OCHRE : '#d8896a');
blit(A, P, 0, 0);

// ---- stitched leather buttons ------------------------------------------------------------
function leather(fill, hi, lo, stitch, edge) {
  var b = new Buf(16, 16);
  b.rect(0, 0, 16, 16, edge); b.rect(1, 1, 14, 14, fill);
  b.rect(1, 1, 14, 1, hi); b.rect(1, 14, 14, 1, lo);
  for (var s = 4; s < 12; s += 2) { b.px(s, 3, stitch); b.px(s, 12, stitch); b.px(3, s, stitch); b.px(12, s, stitch); }
  b.px(3, 3, stitch); b.px(12, 3, stitch); b.px(3, 12, stitch); b.px(12, 12, stitch);
  return b;
}
blit(A, leather('#dcb87e', '#ecd09a', '#c29c60', SINEW, OUT), 0, 164);       // normal
blit(A, leather('#efd29a', '#fbe6b8', '#d6b078', SINEW, OUT), 16, 164);      // hover
blit(A, leather('#b48c58', '#8f6a3c', '#c49c64', '#4a3220', OUT), 32, 164);  // pressed
blit(A, leather('#cdbb98', '#d8c9aa', '#bba984', '#a8946f', '#8a7f6a'), 48, 164); // disabled

// ---- bone close button -------------------------------------------------------------------
function closeBtn(hot) {
  var b = new Buf(12, 12);
  b.ell(6, 6, 5.5, 5.5, hot ? BONEL : BONE); b.px(3, 3, BONEL);
  b.line(3, 3, 8, 8, hot ? OCHRE : '#7d3e22', 1); b.line(8, 3, 3, 8, hot ? OCHRE : '#7d3e22', 1);
  return outlined(b, OUT);
}
blit(A, closeBtn(false), 64, 164); blit(A, closeBtn(true), 78, 164);

// ---- resource icons ----------------------------------------------------------------------
var wood = new Buf(8, 8);
wood.rect(1, 2, 6, 5, '#8a5a36'); wood.rect(1, 2, 6, 1, '#a6703f'); wood.ell(2, 4.5, 2, 2.5, '#d9a566'); wood.px(2, 4, '#c58f50'); wood.px(5, 5, '#6a4326');
blit(A, outlined(wood, OUT), 96, 164);
var food = new Buf(8, 8);
food.ell(3, 4, 3, 3, '#d9694a'); food.px(2, 3, '#f0a080'); food.px(3, 2, '#f0a080'); food.rect(5, 5, 3, 2, BONE); food.px(7, 4, BONE); food.px(7, 7, BONE);
blit(A, outlined(food, OUT), 106, 164);

IMG.putImageData(A.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/skin_hide.png');
console.log('hide skin done');
