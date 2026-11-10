// @open art/reference/workshop_stages.png
// @canvas 184x48
// Workshop construction stages, left to right: site, frame, half-built, complete.
seed = 3;
var W = 184, H = 48, Z = new Buf(W, H), x, y, i;
for (y = 0; y < H; y++) for (x = 0; x < W; x++) Z.px(x, y, y < 14 ? '#bde1f0' : (y < 18 ? '#e8f4ee' : '#74b24f'));
for (i = 0; i < 120; i++) Z.px(Math.floor(rnd() * W), 18 + Math.floor(rnd() * 30), rnd() < .5 ? '#8fc95a' : '#528f3a');
var fns = [shop0, shop1, shop2, shop3];
for (i = 0; i < 4; i++) {
  var tb = new Buf(42, 36); fns[i](tb);
  var ox = i * 46 + 1, oy = 6;
  Z.ell(ox + 21, oy + 34, 19, 2, '#4a8a38');
  blit(Z, outlined(tb, OUT), ox, oy);
}
SPR.layer(0).cel(0).image.putImageData(Z.d);
SPR.save();
console.log('workshop stages done');
