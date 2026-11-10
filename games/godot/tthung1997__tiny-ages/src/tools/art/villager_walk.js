// @open art/reference/villager_walk.png
// @canvas 112x30
// Transparent 4-frame walk cycle (farmer, facing right), 28x30 cells, for in-engine use.
// Feet are on cell row 27. Frame order matches vil() walk frames 0..3.
var Z = new Buf(112, 30);
for (var f = 0; f < 4; f++) {
  var tb = new Buf(27, 27);
  vil({ pal: PAL.red, role: 'farmer', pose: 'walk', f: f })(tb);
  blit(Z, outlined(tb, OUT), f * 28, 0);
}
SPR.layer(0).cel(0).image.putImageData(Z.d);
SPR.save();
console.log('villager walk done');
