// @open art/reference/ui_skin_iron.png
// @canvas 384x192
// The Iron Age panel skin (docs: ages I-series), one atlas -> game/assets/ui/skin_iron.png, laid out
// exactly like the Cave, Settled and Bronze skins (ui_skin_hide.js, ui_skin_clay.js, ui_skin_bronze.js):
//   (0,0,384,160)            the panel: a forged dark-iron frame (riveted plate beams top and bottom,
//                            a post each side, rust-orange trim and flecks) round a pale limewashed
//                            wall with soft grey streaks (it stays light so the dark ink reads), a
//                            ring-chain under the title and a glowing bloom of iron
//   y=164: four 16x16 iron-bound button states (normal, hover, pressed, disabled)
//          at x = 0, 16, 32, 48 (a 9-patch with 4 px margins): a pale steel face, dark iron straps
//          and rust rivets in the corners, so the dark button text keeps its contrast
//   y=164: the iron close button, 14x14, normal at x=64 and hover at x=78
//   y=164: 10x10 resource icons: wood (a log with an iron axe head) at x=96, food (a sack of grain)
//          at x=106
// The regions are mirrored in game/scripts/ui/panel_skin.gd. Keep the panel at the size of
// PanelHost (WIDTH x HEIGHT).
seed = 35;
var IMG = SPR.layer(0).cel(0).image;
var PW = 384, PH = 160;
var A = new Buf(384, 192);
var P = new Buf(PW, PH);
var x, y, i;

var FE = '#3d424d', FEL = '#6e7788', FED = '#262a32', FEH = '#9aa5b5';
var RUST = '#b8572a', RUSTL = '#e0793a', RUSTD = '#7a3a1c';

// ---- the limewashed wall --------------------------------------------------------------------
P.rect(0, 0, PW, PH, '#dcdad0');
for (i = 0; i < 90; i++) { // broad soft patches of lighter and darker wash
  var ex = Math.floor(rnd() * PW), ey = Math.floor(rnd() * PH);
  P.ell(ex, ey, 6 + rnd() * 16, 2 + rnd() * 5, rnd() < 0.5 ? '#e4e2d9' : '#d5d3c9');
}
for (y = 12; y < PH - 10; y += 13) { // faint stone courses, broken here and there
  for (x = 8; x < PW - 8; x++) if (rnd() < 0.82) P.px(x, y + Math.floor(rnd() * 2), '#cfcdc3');
}
for (i = 0; i < 70; i++) { // soft grey streaks where rain has run down the wash
  var sx = 8 + Math.floor(rnd() * (PW - 16)), sy = 8 + Math.floor(rnd() * (PH - 30)), sl = 6 + Math.floor(rnd() * 16);
  for (var k = 0; k < sl; k++) P.px(sx + (rnd() < 0.15 ? 1 : 0), sy + k, rnd() < 0.7 ? '#cbc9c0' : '#d3d1c8');
}
for (i = 0; i < 600; i++) P.px(Math.floor(rnd() * PW), Math.floor(rnd() * PH), rnd() < 0.5 ? '#cdcbc1' : '#ebe9e0');

// ---- the forged-iron frame ------------------------------------------------------------------
function rivet(cx, cy) {
  P.rect(cx - 1, cy - 1, 3, 3, FED); P.rect(cx - 1, cy - 1, 2, 2, FEL); P.px(cx - 1, cy - 1, FEH);
}
function rustFleck(x0, y0, w, h) { // rust bleeding through the black
  for (var q = 0; q < w * h / 16; q++) P.px(x0 + Math.floor(rnd() * w), y0 + Math.floor(rnd() * h), rnd() < 0.6 ? RUST : RUSTL);
}
function beam(y0, top) { // top: the rust trim runs on its lower edge, else on its upper edge
  P.rect(0, y0, PW, 7, FE);
  P.rect(0, y0, PW, 1, OUT); P.rect(0, y0 + 6, PW, 1, OUT);
  if (top) { P.rect(0, y0 + 1, PW, 1, FEL); P.rect(0, y0 + 4, PW, 1, FED); P.rect(0, y0 + 5, PW, 1, RUST); }
  else { P.rect(0, y0 + 1, PW, 1, RUST); P.rect(0, y0 + 2, PW, 1, FEL); P.rect(0, y0 + 5, PW, 1, FED); }
  for (var sx = 28; sx < PW - 24; sx += 64) { // a forge-welded seam between plates
    P.rect(sx, y0 + 2, 1, 3, FED); P.rect(sx + 1, y0 + 2, 1, 3, FEL);
  }
  rustFleck(8, y0 + 2, PW - 16, 3);
}
function post(x0, left) {
  P.rect(x0, 0, 6, PH, FE);
  P.rect(x0, 0, 1, PH, OUT); P.rect(x0 + 5, 0, 1, PH, OUT);
  P.rect(x0 + (left ? 1 : 4), 0, 1, PH, FEL);
  P.rect(x0 + (left ? 4 : 1), 0, 1, PH, RUST);
  P.rect(x0 + 2, 0, 1, PH, FED); P.rect(x0 + 3, 0, 1, PH, FE);
  rustFleck(x0 + 2, 8, 2, PH - 16);
}
post(0, true); post(PW - 6, false);
beam(0, true); beam(PH - 7, false);
var rxs = [3, PW - 4], rys = [3, PH - 4];
for (i = 0; i < 2; i++) for (var j = 0; j < 2; j++) rivet(rxs[i], rys[j]); // the four corners
for (x = 48; x < PW - 40; x += 48) { rivet(x, 3); rivet(x, PH - 4); }
for (y = 40; y < PH - 20; y += 40) { rivet(3, y); rivet(PW - 4, y); }
// shadow where the wall meets the frame, and rust-stained runs under a few rivets
for (x = 6; x < PW - 6; x++) { P.px(x, 7, '#bdbbb1'); P.px(x, PH - 8, '#e6e4db'); }
for (y = 8; y < PH - 8; y++) { P.px(6, y, '#e6e4db'); P.px(PW - 7, y, '#bdbbb1'); }
for (x = 48; x < PW - 40; x += 48) {
  var run = 3 + Math.floor(rnd() * 4);
  for (var r = 0; r < run; r++) P.px(x + (rnd() < 0.2 ? 1 : 0), 8 + r, r < run - 1 ? '#d4b79c' : '#caa588');
}
// the corners of the whole panel are cut, so it does not look like a screen
var corners = [[0, 0], [PW - 1, 0], [0, PH - 1], [PW - 1, PH - 1]];
for (i = 0; i < corners.length; i++) P.d[(corners[i][1] * PW + corners[i][0]) * 4 + 3] = 0;

// ---- a glowing bloom of iron near the close button -------------------------------------------
function bloom(hx, hy) {
  var g = new Buf(14, 9);
  g.ell(6.5, 4.5, 6.4, 3.8, FE); g.ell(5.5, 3.5, 4.2, 2.2, FEL);
  g.px(3, 2, FEH); g.px(4, 2, FEH); g.px(2, 3, FEH);
  g.ell(7.5, 5.5, 3.2, 1.8, RUST); g.ell(7.5, 5.5, 2, 1.1, RUSTL);
  g.px(7, 5, '#ffd9a0'); g.px(8, 5, '#ffd9a0');
  g.px(11, 3, FED); g.px(1, 5, FED); g.px(5, 7, FED);
  blit(P, outlined(g, OUT), hx, hy);
}
bloom(PW - 55, 16);
// a ring-chain under where the title sits: flat rings joined by edge-on links
function ringLink(cx, cy) { // 7x5, a dark ring with a lit top and a shaded bottom
  P.rect(cx + 1, cy, 5, 1, FEL); P.rect(cx + 1, cy + 4, 5, 1, FED);
  P.rect(cx, cy + 1, 1, 3, FE); P.rect(cx + 6, cy + 1, 1, 3, FED);
  P.px(cx + 1, cy + 1, FE); P.px(cx + 5, cy + 3, FED);
}
for (x = 12; x + 9 <= 108; x += 9) {
  ringLink(x, 24);
  P.rect(x + 7, 25, 2, 3, FED); P.px(x + 7, 25, FEL); P.px(x + 8, 25, FE); // the edge-on link between two rings
}
P.px(94, 24, RUSTL); P.px(96, 28, RUST); P.px(100, 26, RUST); // rust on the last links
blit(A, P, 0, 0);blit(A, P, 0, 0);

// ---- iron-bound buttons ---------------------------------------------------------------------
function bound(fill, hi, lo, strap, rivetC, edge) {
  var b = new Buf(16, 16);
  b.rect(0, 0, 16, 16, edge); b.rect(1, 1, 14, 14, fill);
  b.rect(2, 1, 12, 1, hi); b.rect(2, 14, 12, 1, lo);
  var cx = [1, 14], cy = [1, 14], sxd = [1, -1], syd = [1, -1];
  for (var a = 0; a < 2; a++) for (var c = 0; c < 2; c++) { // a dark iron strap bracket round each corner
    var px0 = cx[a], py0 = cy[c], dx = sxd[a], dy = syd[c];
    b.px(px0, py0, strap); b.px(px0 + dx, py0, strap); b.px(px0 + 2 * dx, py0, strap);
    b.px(px0, py0 + dy, strap); b.px(px0, py0 + 2 * dy, strap);
    b.px(px0 + dx, py0 + dy, rivetC);
  }
  return b;
}
blit(A, bound('#aeb6c4', '#d8dee8', '#8a93a4', FE, RUSTL, OUT), 0, 164);         // normal
blit(A, bound('#c4ccd8', '#eef2f8', '#9ea8ba', FE, '#ff9a54', OUT), 16, 164);    // hover
blit(A, bound('#97a0b0', '#7a8394', '#bcc4d2', FED, RUST, OUT), 32, 164);        // pressed
blit(A, bound('#c8c8c0', '#d8d8d0', '#b0b0a8', '#8a8a86', '#a09890', '#8a8a86'), 48, 164); // disabled

// ---- iron close button ----------------------------------------------------------------------
function closeBtn(hot) {
  var b = new Buf(12, 12);
  b.ell(6, 6, 5.5, 5.5, hot ? '#6e7788' : '#4a505c');
  b.px(3, 3, hot ? '#c4ccd8' : '#9aa5b5'); b.px(4, 2, hot ? '#c4ccd8' : '#9aa5b5');
  b.line(3, 3, 8, 8, hot ? '#ffb070' : RUSTL, 1); b.line(8, 3, 3, 8, hot ? '#ffb070' : RUSTL, 1);
  return outlined(b, OUT);
}
blit(A, closeBtn(false), 64, 164); blit(A, closeBtn(true), 78, 164);

// ---- resource icons -------------------------------------------------------------------------
var wood = new Buf(8, 8);
wood.rect(0, 3, 7, 4, '#8a5a36'); wood.rect(0, 3, 7, 1, '#a6703f'); wood.rect(0, 6, 7, 1, '#6a4326');
wood.ell(6.5, 4.5, 1.5, 1.8, '#d9a566'); wood.px(6, 4, '#a6703f');
wood.rect(1, 0, 3, 3, '#aab4c4'); wood.rect(1, 0, 3, 1, '#d8dee8'); wood.px(3, 2, '#6e7788'); // the axe head, bitten in
wood.px(2, 3, '#aab4c4');
blit(A, outlined(wood, OUT), 96, 164);
var sack = new Buf(8, 8);
sack.ell(3.5, 4.5, 3.4, 3, '#c9b07a'); sack.ell(3, 4, 1.8, 1.6, '#e0cc98');
sack.rect(2, 0, 3, 2, '#c9b07a'); sack.rect(2, 1, 3, 1, '#7a5a3a'); // the neck, tied
sack.px(2, 0, '#a8905c'); sack.px(4, 0, '#a8905c'); sack.px(5, 6, '#a8905c'); sack.px(2, 6, '#a8905c');
sack.px(6, 3, '#e6c84a'); sack.px(7, 2, '#e6c84a'); // a few spilled grains
blit(A, outlined(sack, OUT), 106, 164);

IMG.putImageData(A.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/skin_iron.png');
console.log('iron skin done');
