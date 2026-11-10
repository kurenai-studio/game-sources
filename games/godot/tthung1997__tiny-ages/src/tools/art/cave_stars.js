// @open art/reference/cave_stars.png
// @canvas 384x56
// The night sky's stars: one transparent 384x56 layer (the height of the sky) of single pixels,
// with a few brighter ones in a plus shape -> game/assets/world/cave/stars.png. The game fades
// it in with the dark; it does not scroll with the world, like the sun and moon.
seed = 21;
var IMG = SPR.layer(0).cel(0).image;
var S = new Buf(384, 56), i, x, y;

for (i = 0; i < 90; i++) {
  x = Math.floor(rnd() * 384);
  y = Math.floor(rnd() * rnd() * 40) + 1; // thicker towards the top, the far hills hide the rest
  S.px(x, y, rnd() < 0.7 ? '#ffffff' : '#cfe3ff');
}
for (i = 0; i < 14; i++) {
  x = 6 + Math.floor(rnd() * 372);
  y = 4 + Math.floor(rnd() * 26);
  S.px(x, y, '#ffffff');
  S.px(x - 1, y, '#9fb8e0'); S.px(x + 1, y, '#9fb8e0'); S.px(x, y - 1, '#9fb8e0'); S.px(x, y + 1, '#9fb8e0');
}

IMG.putImageData(S.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/world/cave/stars.png');
console.log('stars done');
