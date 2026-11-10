// @open art/reference/ui_icons.png
// @canvas 110x20
// The strip's icons, one 110x20 sheet: two frames of the idea bulb (18x20 each, the second lit
// with rays), the journal book (16x20), the menu gear (16x20), the wood and food icons for the
// stock gauge (12x12 each), its two trend arrows (7x5, up above down) and its three pip rows
// (10x4 each, one, two or three pips lit, stacked) -> art/reference/ui_icons.png and
// game/assets/ui/icons.png. Frame x positions are mirrored in game/scripts/ui/strip_icons.gd.
seed = 5;
var IMG = SPR.layer(0).cel(0).image;

function bulbIcon(b, on) { // 14x16: glass, highlight, screw base
  b.ell(7, 6, 5, 5.5, on ? '#ffe27a' : '#f0d060');
  b.ell(8, 8, 3, 3.5, on ? '#f9d04e' : '#e2bc4a');
  b.px(4, 3, '#fff8d0'); b.px(5, 2, '#fff8d0'); b.px(4, 4, '#fff8d0');
  b.rect(5, 11, 4, 2, '#9aa0aa'); b.rect(5, 11, 4, 1, '#bcc0cc'); b.rect(6, 13, 2, 1, '#6a6f7a');
}
function bookIcon(b) { // 14x14: brown cover, pages, a red ribbon
  b.rect(1, 1, 12, 12, '#8a5a36'); b.rect(1, 1, 2, 12, '#6a4326');
  b.rect(3, 2, 9, 10, '#f3e9d2');
  b.rect(5, 4, 6, 1, '#c9b99a'); b.rect(5, 6, 6, 1, '#c9b99a'); b.rect(5, 8, 4, 1, '#c9b99a');
  b.rect(10, 9, 2, 5, '#e8504a');
}

function gearIcon(b) { // 12x12: eight teeth round a ring, a hole in the middle, grey stone
  var rows = ['....xxxx....', '.xx.xxxx.xx.', '.xxxxxxxxxx.', '..xxxxxxxx..',
    'xxxx....xxxx', 'xxxx....xxxx', 'xxxx....xxxx', 'xxxx....xxxx',
    '..xxxxxxxx..', '.xxxxxxxxxx.', '.xx.xxxx.xx.', '....xxxx....'];
  function on(x, y) { return y >= 0 && y < 12 && x >= 0 && x < 12 && rows[y].charAt(x) == 'x'; }
  for (var y = 0; y < 12; y++) for (var x = 0; x < 12; x++) {
    if (!on(x, y)) continue;
    b.px(x, y, !on(x, y + 1) ? '#6a6f7a' : !on(x, y - 1) ? '#bcc0cc' : '#9aa0aa');
  }
}

function woodIcon(b) { // 10x10: two stacked logs, end grain on the right
  b.rect(1, 1, 8, 4, WOOD); b.rect(1, 1, 8, 1, WOODL); b.ell(8.5, 3, 1.5, 2, '#d9a566'); b.px(8, 3, '#b07f44');
  b.rect(0, 5, 8, 4, WOOD); b.rect(0, 5, 8, 1, WOODL); b.ell(7.5, 7, 1.5, 2, '#d9a566'); b.px(7, 7, '#b07f44');
}
function foodIcon(b) { // 10x10: a haunch of meat on the bone
  b.ell(4, 4.5, 3.8, 3.4, '#b86a4a'); b.ell(3, 3.5, 2, 1.6, '#d98a68');
  b.rect(7, 6, 3, 2, '#e9dcc0'); b.px(9, 5, '#e9dcc0'); b.px(9, 8, '#e9dcc0');
}
function arrowIcon(b, up, c) { // 5x3: a small triangle
  var rows = up ? ['..x..', '.xxx.', 'xxxxx'] : ['xxxxx', '.xxx.', '..x..'];
  for (var y = 0; y < 3; y++) for (var x = 0; x < 5; x++) if (rows[y].charAt(x) == 'x') b.px(x, y, c);
}
function pipsIcon(b, lit) { // 8x2: three pips, `lit` of them bright
  for (var i = 0; i < 3; i++) b.rect(i * 3, 0, 2, 2, i < lit ? '#f3e9d2' : '#6a6f7a');
}

var SHEET = new Buf(110, 20);
for (var f = 0; f < 2; f++) {
  var tb = new Buf(14, 16); bulbIcon(tb, f == 1);
  blit(SHEET, outlined(tb, OUT), f * 18 + 1, 2);
  if (f == 1) { // rays around the lit bulb
    var rx = f * 18;
    SHEET.rect(rx + 8, 0, 2, 1, '#ffe27a'); SHEET.rect(rx, 9, 1, 2, '#ffe27a'); SHEET.rect(rx + 17, 9, 1, 2, '#ffe27a');
    SHEET.px(rx + 2, 3, '#ffe27a'); SHEET.px(rx + 15, 3, '#ffe27a');
  }
}
var bk = new Buf(14, 14); bookIcon(bk);
blit(SHEET, outlined(bk, OUT), 36, 2);
var gr = new Buf(12, 12); gearIcon(gr);
blit(SHEET, outlined(gr, OUT), 53, 3);
var wd = new Buf(10, 10); woodIcon(wd); blit(SHEET, outlined(wd, OUT), 68, 0);
var fd = new Buf(10, 10); foodIcon(fd); blit(SHEET, outlined(fd, OUT), 80, 0);
var au = new Buf(5, 3); arrowIcon(au, true, '#a8e08a'); blit(SHEET, outlined(au, OUT), 92, 0);
var ad = new Buf(5, 3); arrowIcon(ad, false, '#f0a060'); blit(SHEET, outlined(ad, OUT), 92, 6);
for (var lv = 1; lv <= 3; lv++) {
  var pp = new Buf(8, 2); pipsIcon(pp, lv); blit(SHEET, outlined(pp, OUT), 100, (lv - 1) * 6);
}

IMG.putImageData(SHEET.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/icons.png');
console.log('ui icons done');
