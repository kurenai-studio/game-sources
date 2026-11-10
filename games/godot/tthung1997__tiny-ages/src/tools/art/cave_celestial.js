// @open art/reference/cave_celestial.png
// @canvas 32x16
// The sun and the moon, one 32x16 sheet of two 16x16 cells: 0 sun | 1 moon -> game/assets/world/
// cave/celestial.png. The game moves them across the sky by the hour (view/day_night.gd) and
// they set behind the far hills. No outline: they are light, not objects. Cell positions are
// mirrored in game/scripts/view/world_layout.gd.
var IMG = SPR.layer(0).cel(0).image;
var SHEET = new Buf(32, 16);

// sun: a pale disc with a dithered corona
var cx = 8, cy = 8, x, y;
for (y = 0; y < 16; y++) for (x = 0; x < 16; x++) {
  var d = Math.sqrt((x - cx + 0.5) * (x - cx + 0.5) + (y - cy + 0.5) * (y - cy + 0.5));
  if (d <= 3.6) SHEET.px(x, y, '#fffbe6');
  else if (d <= 5.2) SHEET.px(x, y, '#fff3c4');
  else if (d <= 7.4 && ((x + y) & 1) == 0) SHEET.px(x, y, '#ffe9a0');
}

// moon: a pale crescent, lit from the right
var mx = 16 + 8, my = 8;
for (y = 0; y < 16; y++) for (x = 16; x < 32; x++) {
  var inDisc = Math.sqrt((x - mx + 0.5) * (x - mx + 0.5) + (y - my + 0.5) * (y - my + 0.5)) <= 6.2;
  var inBite = Math.sqrt((x - mx + 3.2) * (x - mx + 3.2) + (y - my + 1.2) * (y - my + 1.2)) <= 5.6;
  if (inDisc && !inBite) {
    var edge = Math.sqrt((x - mx + 0.5) * (x - mx + 0.5) + (y - my + 0.5) * (y - my + 0.5)) > 5.0;
    SHEET.px(x, y, edge ? '#cfdaea' : '#eef3fa');
  }
}

IMG.putImageData(SHEET.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/world/cave/celestial.png');
console.log('celestial done');
