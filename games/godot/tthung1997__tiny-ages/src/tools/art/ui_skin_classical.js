// @open art/reference/ui_skin_classical.png
// @canvas 384x192
// The Classical Age panel skin, one atlas -> game/assets/ui/skin_classical.png, laid out exactly like the
// Cave, Settled, Bronze and Iron skins (ui_skin_hide.js, ui_skin_clay.js, ui_skin_bronze.js, ui_skin_iron.js):
//   (0,0,384,160)            the panel: limestone beams top and bottom with a terracotta band, a fluted
//                            column down each side, a plastered cream wall with fine joints (it stays
//                            light so the dark ink reads), a Greek-key meander under the title and a
//                            laurel wreath near the close button
//   y=164: four 16x16 terracotta-tile button states (normal, hover, pressed, disabled)
//          at x = 0, 16, 32, 48 (a 9-patch with 4 px margins): a cream face with a terracotta border,
//          so the dark button text keeps its contrast
//   y=164: the close button, 14x14, normal at x=64 and hover at x=78
//   y=164: 10x10 resource icons: wood (a stack of cut beams) at x=96, food (an amphora) at x=106
// The regions are mirrored in game/scripts/ui/panel_skin.gd. Keep the panel at the size of
// PanelHost (WIDTH x HEIGHT).
seed = 47;
var IMG = SPR.layer(0).cel(0).image;
var PW = 384, PH = 160;
var A = new Buf(384, 192);
var P = new Buf(PW, PH);
var x, y, i;

var LS = '#e6dcc4', LSL = '#f6efdc', LSD = '#bfb394', LSS = '#9d9177';
var TC = '#c0623a', TCL = '#e08a58', TCD = '#8a3f24';

// ---- the plastered wall ---------------------------------------------------------------------
P.rect(0, 0, PW, PH, '#eee6d0');
for (i = 0; i < 90; i++) { // broad soft patches of lighter and darker plaster
  var ex = Math.floor(rnd() * PW), ey = Math.floor(rnd() * PH);
  P.ell(ex, ey, 6 + rnd() * 16, 2 + rnd() * 5, rnd() < 0.5 ? '#f4eddb' : '#e6dec7');
}
for (y = 14; y < PH - 10; y += 14) { // faint joints between courses of stone, broken here and there
  for (x = 10; x < PW - 10; x++) if (rnd() < 0.8) P.px(x, y + Math.floor(rnd() * 2), '#ddd3b8');
}
for (i = 0; i < 500; i++) P.px(Math.floor(rnd() * PW), Math.floor(rnd() * PH), rnd() < 0.5 ? '#e0d7bd' : '#f8f2e2');

// ---- the limestone frame --------------------------------------------------------------------
function beam(y0, top) { // top: the terracotta band runs on its lower edge, else on its upper edge
  P.rect(0, y0, PW, 8, LS);
  P.rect(0, y0, PW, 1, OUT); P.rect(0, y0 + 7, PW, 1, OUT);
  if (top) { P.rect(0, y0 + 1, PW, 1, LSL); P.rect(0, y0 + 4, PW, 2, TC); P.rect(0, y0 + 4, PW, 1, TCL); P.rect(0, y0 + 6, PW, 1, LSD); }
  else { P.rect(0, y0 + 1, PW, 1, LSD); P.rect(0, y0 + 2, PW, 2, TC); P.rect(0, y0 + 2, PW, 1, TCL); P.rect(0, y0 + 6, PW, 1, LSD); }
  for (var sx = 30; sx < PW - 24; sx += 60) P.rect(sx, y0 + 1, 1, 6, LSD); // a joint between blocks
}
function column(x0, left) { // a fluted column the length of the panel
  P.rect(x0, 0, 8, PH, LS);
  P.rect(x0, 0, 1, PH, OUT); P.rect(x0 + 7, 0, 1, PH, OUT);
  P.rect(x0 + (left ? 1 : 5), 0, 1, PH, LSL);
  P.rect(x0 + 2, 0, 1, PH, LSD); P.rect(x0 + 4, 0, 1, PH, LSD); P.rect(x0 + 6, 0, 1, PH, LSD);
  for (var cy = 12; cy < PH - 12; cy += 3) { P.px(x0 + 3, cy, LSL); P.px(x0 + 5, cy, LSL); }
}
column(0, true); column(PW - 8, false);
beam(0, true); beam(PH - 8, false);
// a rosette in each corner, a smaller one along the rails
function rosette(cx, cy, r) {
  P.ell(cx, cy, r, r, TCD); P.ell(cx, cy, r - 1, r - 1, TC); P.px(cx - 1, cy - 1, TCL); P.px(cx, cy, LSL);
}
var rxs = [4, PW - 5], rys = [4, PH - 5];
for (i = 0; i < 2; i++) for (var j = 0; j < 2; j++) rosette(rxs[i], rys[j], 2.5);
for (x = 56; x < PW - 40; x += 56) { P.px(x, 4, TCD); P.px(x + 1, 4, TCD); P.px(x, PH - 5, TCD); P.px(x + 1, PH - 5, TCD); }
// shadow where the wall meets the frame
for (x = 8; x < PW - 8; x++) { P.px(x, 8, '#d8cdb0'); P.px(x, PH - 9, '#f6efdc'); }
for (y = 9; y < PH - 9; y++) { P.px(8, y, '#f6efdc'); P.px(PW - 9, y, '#d8cdb0'); }
// the corners of the whole panel are cut, so it does not look like a screen
var corners = [[0, 0], [PW - 1, 0], [0, PH - 1], [PW - 1, PH - 1]];
for (i = 0; i < corners.length; i++) P.d[(corners[i][1] * PW + corners[i][0]) * 4 + 3] = 0;

// ---- a laurel wreath near the close button ---------------------------------------------------
function wreath(hx, hy) {
  var g = new Buf(14, 10), k, a, lx, ly;
  for (k = 0; k < 9; k++) { // two arcs of leaves meeting at the top
    a = Math.PI * (0.15 + k * 0.088);
    lx = 7 - Math.cos(a) * 6; ly = 8 - Math.sin(a) * 6;
    g.ell(lx, ly, 1.2, 0.9, k % 2 ? '#7aa05a' : '#5e8a42');
    lx = 7 + Math.cos(a) * 6;
    g.ell(lx, ly, 1.2, 0.9, k % 2 ? '#5e8a42' : '#7aa05a');
  }
  g.px(7, 9, TC); g.px(6, 9, TCD); g.px(8, 9, TCD);
  blit(P, outlined(g, OUT), hx, hy);
}
wreath(PW - 56, 15);
// a Greek-key meander under where the title sits
function key(kx, ky) { // one 8x5 unit of the pattern, a square spiral
  P.rect(kx, ky, 7, 1, TCD); P.rect(kx, ky, 1, 5, TCD); P.rect(kx, ky + 4, 5, 1, TCD);
  P.rect(kx + 4, ky + 2, 1, 3, TCD); P.rect(kx + 2, ky + 2, 3, 1, TCD); P.rect(kx + 2, ky + 2, 1, 2, TCD);
  P.px(kx + 1, ky + 1, TC);
}
for (x = 12; x + 8 <= 112; x += 8) key(x, 22);
blit(A, P, 0, 0);

// ---- terracotta-tile buttons ----------------------------------------------------------------
function tile(fill, hi, lo, border, edge) {
  var b = new Buf(16, 16);
  b.rect(0, 0, 16, 16, edge); b.rect(1, 1, 14, 14, border); b.rect(3, 3, 10, 10, fill);
  b.rect(4, 3, 8, 1, hi); b.rect(4, 12, 8, 1, lo);
  b.px(2, 2, hi); b.px(13, 2, hi); b.px(2, 13, lo); b.px(13, 13, lo);
  return b;
}
blit(A, tile('#f0e6cc', '#faf4e2', '#d8ccae', TC, OUT), 0, 164);          // normal
blit(A, tile('#faf0d6', '#ffffff', '#e4d8ba', TCL, OUT), 16, 164);        // hover
blit(A, tile('#dccfb0', '#c8bb9c', '#eadfc2', TCD, OUT), 32, 164);        // pressed
blit(A, tile('#e4e0d4', '#ece8de', '#d0ccbe', '#aaa296', '#9a9488'), 48, 164); // disabled

// ---- close button ---------------------------------------------------------------------------
function closeBtn(hot) {
  var b = new Buf(12, 12);
  b.ell(6, 6, 5.5, 5.5, hot ? TCL : TC);
  b.px(3, 3, hot ? '#f6c4a0' : TCL); b.px(4, 2, hot ? '#f6c4a0' : TCL);
  b.line(3, 3, 8, 8, '#f6efdc', 1); b.line(8, 3, 3, 8, '#f6efdc', 1);
  return outlined(b, OUT);
}
blit(A, closeBtn(false), 64, 164); blit(A, closeBtn(true), 78, 164);

// ---- resource icons -------------------------------------------------------------------------
var wood = new Buf(8, 8);
wood.rect(0, 4, 7, 3, '#8a5a36'); wood.rect(0, 4, 7, 1, '#a6703f'); wood.rect(0, 6, 7, 1, '#6a4326');
wood.rect(1, 1, 6, 3, '#a6703f'); wood.rect(1, 1, 6, 1, '#c58f50'); wood.rect(1, 3, 6, 1, '#7a4c28');
wood.px(6, 5, '#d9a566'); wood.px(6, 2, '#e0b070');
blit(A, outlined(wood, OUT), 96, 164);
var jar = new Buf(8, 8);
jar.ell(3.5, 4.5, 2.8, 3, TC); jar.ell(3, 4, 1.4, 1.8, TCL);
jar.rect(2, 0, 3, 2, TCD); jar.rect(2, 0, 3, 1, TCL);
jar.px(0, 3, TCD); jar.px(7, 3, TCD); jar.px(0, 4, TCD); jar.px(7, 4, TCD); // the handles
jar.rect(1, 4, 5, 1, '#f0e6cc'); // a pale band round the belly
jar.px(3, 7, TCD);
blit(A, outlined(jar, OUT), 106, 164);

IMG.putImageData(A.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/skin_classical.png');
console.log('classical skin done');
