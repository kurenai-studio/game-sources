// @open art/reference/game_icon.png
// @canvas 32x32
// The game icon: a campfire under a starry sky, with a small villager by the fire. Fire is the one
// thing every age has, and it stays readable at taskbar size. 32x32 -> art/reference/game_icon.png;
// `python tools/art/make_icon.py` scales it (nearest) into game/icon.png and game/icon.ico.
var IMG = SPR.layer(0).cel(0).image;
var S = new Buf(32, 32);

function band(b, x0, y0, w, h, cols) { // vertical colour bands
  var n = cols.length, i;
  for (i = 0; i < n; i++) b.rect(x0, y0 + Math.floor(h * i / n), w, Math.ceil(h / n), cols[i]);
}
function glow(b, cx, cy, rx, ry, c) { // dithered warm light
  var x, y;
  for (y = Math.floor(cy - ry); y <= Math.ceil(cy + ry); y++) {
    for (x = Math.floor(cx - rx); x <= Math.ceil(cx + rx); x++) {
      var dx = (x - cx) / rx, dy = (y - cy) / ry;
      if (dx * dx + dy * dy <= 1 && ((x + y) & 1) == 0) b.px(x, y, c);
    }
  }
}
function flame(b, x, y) { // 7 wide, 9 tall flame with a bright heart
  b.tri(x + 3, y, 9, 3, '#f59e2b', '#e5732b');
  b.tri(x + 3, y + 3, 6, 2, '#ffcf4a', '#ffbe3a');
  b.tri(x + 3, y + 5, 4, 1, '#fff2a0', '#fff2a0');
}

band(S, 0, 0, 32, 22, ['#151a34', '#1b2142', '#232a52', '#2d3562', '#3a4276']);
var STARS = [[4, 3], [11, 6], [24, 4], [28, 9], [18, 2], [7, 11], [27, 15]], i;
for (i = 0; i < STARS.length; i++) S.px(STARS[i][0], STARS[i][1], '#fff8d0');
S.px(22, 5, '#ffffff');
S.rect(0, 22, 32, 10, '#2f5a3a'); S.rect(0, 22, 32, 1, '#3f7a45'); S.rect(0, 23, 32, 2, '#2a4f34');
glow(S, 16, 22, 12, 9, '#6a4a3a');
glow(S, 16, 22, 7, 6, '#c9743a');
S.rect(9, 26, 14, 2, WOOD); S.rect(9, 26, 14, 1, WOODL);
S.rect(8, 25, 2, 1, '#9aa0aa'); S.rect(22, 25, 2, 1, '#9aa0aa');
flame(S, 13, 16);
S.rect(24, 23, 3, 3, '#e0614a'); S.rect(24, 21, 3, 2, SK); S.rect(24, 20, 3, 1, '#5a3a26');
S.rect(24, 26, 3, 1, '#2b2d42');
// clear the four corner pixels so the square reads as a tile
S.rect(0, 0, 1, 1, '#00000000'); S.rect(31, 0, 1, 1, '#00000000');
S.rect(0, 31, 1, 1, '#00000000'); S.rect(31, 31, 1, 1, '#00000000');

IMG.putImageData(S.d); SPR.save();
console.log('game icon done');
