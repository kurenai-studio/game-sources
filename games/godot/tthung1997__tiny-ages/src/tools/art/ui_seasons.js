// @open art/reference/ui_seasons.png
// @canvas 48x12
// The season glyphs for the strip: four 12x12 cells in one 48x12 sheet -> art/reference/
// ui_seasons.png and game/assets/ui/season_glyphs.png. Cells: 0 spring (a sprout), 1 summer (a
// sun), 2 autumn (a leaf), 3 winter (a snowflake). Mirrored in game/scripts/view/season_look.gd
// (GLYPH_COUNT) and strip_icons.gd.
seed = 9;
var IMG = SPR.layer(0).cel(0).image;
var SHEET = new Buf(48, 12);

var ICONS = [
  function (b) { b.rect(4, 4, 1, 5, '#3a7a3a'); b.ell(2, 3, 2, 1.5, '#58b05f'); b.ell(7, 2, 2.4, 1.6, '#7cd070'); b.px(4, 9, '#8a5a36'); },
  function (b) { b.ell(5, 5, 2.6, 2.6, '#ffd84a'); b.rect(4, 0, 2, 1, '#ffd84a'); b.rect(4, 9, 2, 1, '#ffd84a'); b.rect(0, 4, 1, 2, '#ffd84a'); b.rect(9, 4, 1, 2, '#ffd84a'); b.px(1, 1, '#ffd84a'); b.px(8, 1, '#ffd84a'); b.px(1, 8, '#ffd84a'); b.px(8, 8, '#ffd84a'); },
  function (b) { b.ell(5, 4, 3.5, 3.5, '#e8873a'); b.ell(4, 3, 1.5, 1.5, '#f2b05a'); b.line(5, 5, 5, 9, '#8a5a36', 1); b.px(7, 6, '#c8602a'); },
  function (b) { b.rect(5, 0, 1, 10, '#e6f1ff'); b.rect(0, 5, 10, 1, '#e6f1ff'); b.line(1, 1, 8, 8, '#bcd8f2', 1); b.line(8, 1, 1, 8, '#bcd8f2', 1); b.rect(4, 4, 3, 3, '#ffffff'); }
];
for (var n = 0; n < ICONS.length; n++) {
  var cell = new Buf(10, 10); ICONS[n](cell);
  blit(SHEET, outlined(cell, OUT), n * 12, 0);
}

IMG.putImageData(SHEET.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/season_glyphs.png');
console.log('season glyphs done');
