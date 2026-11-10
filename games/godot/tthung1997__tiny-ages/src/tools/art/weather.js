// @open art/reference/weather.png
// @canvas 384x480
// Rain and snow, one 384-wide sheet of 80-pixel rows (the size of the viewport) -> game/assets/
// world/weather.png. Light and shade only, with no outline (it is weather, not an object); the
// game fades the sprite with its own alpha. Rows are mirrored in game/scripts/view/
// weather_layer.gd: change both together.
//   0-2 rain (a falling loop)         3-5 snow (a falling loop)
seed = 77;
var IMG = SPR.layer(0).cel(0).image;
var S = new Buf(384, 480), i, j, k, x, y;
function row(r) { return r * 80; }

// ---- rain: streaks that fall 9 pixels a frame and repeat every 27, so three frames loop. Each is
// four pixels, dark at the tail and white at the head, so it reads over green, stone and snow ----
var streaks = [];
for (i = 0; i < 110; i++) streaks.push([Math.floor(rnd() * 384), Math.floor(rnd() * 27)]);
for (k = 0; k < 3; k++) for (i = 0; i < streaks.length; i++) for (j = 0; j < 3; j++) {
  x = streaks[i][0]; y = (streaks[i][1] + 9 * k) % 27 + 27 * j;
  if (y > 75) continue;
  S.px(x - 1, row(k) + y, '#4a6a9c'); S.px(x - 1, row(k) + y + 1, '#5f86bf');
  S.px(x, row(k) + y + 2, '#a9c9ee'); S.px(x, row(k) + y + 3, '#f4faff');
}

// ---- snow: flakes that fall 6 pixels a frame (period 18) and sway; each has a cool shadow pixel
// so it shows on pale ground ----
var flakes = [];
for (i = 0; i < 110; i++) flakes.push([Math.floor(rnd() * 384), Math.floor(rnd() * 18), rnd() < 0.3]);
for (k = 0; k < 3; k++) for (i = 0; i < flakes.length; i++) for (j = 0; j < 5; j++) {
  x = flakes[i][0] + (k == 1 ? 1 : (k == 2 ? -1 : 0)); y = (flakes[i][1] + 6 * k) % 18 + 18 * j;
  if (y > 77) continue;
  S.px(x + 1, row(3 + k) + y + 1, '#7f95b8');
  S.px(x, row(3 + k) + y, '#ffffff');
  if (flakes[i][2]) { S.px(x + 1, row(3 + k) + y, '#ffffff'); S.px(x, row(3 + k) + y + 1, '#ffffff'); S.px(x + 2, row(3 + k) + y + 1, '#7f95b8'); S.px(x + 1, row(3 + k) + y + 2, '#7f95b8'); }
}

IMG.putImageData(S.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/world/weather.png');
console.log('weather done');
