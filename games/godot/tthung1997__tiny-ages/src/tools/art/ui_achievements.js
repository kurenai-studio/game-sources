// @open art/reference/ui_achievements.png
// @canvas 680x20
// The achievement icons, one 680x20 sheet of 34 round medals (20x20 each, in the order of
// AchievementPresenter.ICON_ORDER, then a plain rosette for any achievement without its own)
// -> art/reference/ui_achievements.png and game/assets/ui/achievements.png. The cell order is
// mirrored in game/scripts/ui/achievement_presenter.gd; append new icons at the end.
seed = 11;
var IMG = SPR.layer(0).cel(0).image;
var INK = '#2b2d42', CREAM = '#f3e9d2', RIM = '#a8843c';

function fire(g) {
  g.rect(2, 10, 8, 2, WOOD); g.rect(2, 10, 8, 1, WOODL);
  g.ell(6, 7, 3.2, 3.6, '#e8504a'); g.ell(6, 7.5, 2.2, 2.8, '#f59a3a'); g.ell(6, 8.5, 1.2, 1.6, '#ffe27a');
  g.rect(5, 4, 2, 1, '#e8504a'); g.px(6, 3, '#e8504a'); g.px(6, 2, '#e8504a');
}
function stoneTools(g) {
  g.line(2, 10, 7, 5, WOOD, 2);
  g.rect(7, 1, 4, 5, '#9aa0aa'); g.rect(7, 1, 1, 5, '#bcc0cc'); g.rect(10, 2, 1, 3, '#6a6f7a');
  g.px(7, 6, '#e8504a'); g.px(6, 7, '#e8504a');
}
function food(g) {
  g.ell(5, 6, 3.6, 3.2, '#b86a4a'); g.ell(4, 5, 2, 1.6, '#d98a68');
  g.rect(8, 7, 3, 2, '#c9b99a'); g.px(10, 6, '#c9b99a'); g.px(10, 9, '#c9b99a');
}
function stories(g) {
  g.ell(6, 5, 4.6, 3.4, '#8fbfe0'); g.ell(5, 4, 2.6, 1.6, '#b8dcf0');
  g.px(3, 8, '#8fbfe0'); g.px(2, 9, '#8fbfe0'); g.px(4, 8, '#8fbfe0');
  g.px(4, 5, INK); g.px(6, 5, INK); g.px(8, 5, INK);
}
function group(g) {
  g.rect(1, 6, 4, 5, WOOD); g.ell(3, 4, 1.6, 1.6, SK); g.ell(3, 3.3, 1.7, 1, '#4a3320');
  g.rect(7, 6, 4, 5, '#4a7fa8'); g.ell(9, 4, 1.6, 1.6, SK); g.ell(9, 3.3, 1.7, 1, '#4a3320');
  g.rect(4, 5, 4, 6, '#a8452f'); g.ell(6, 3, 1.8, 1.8, SK); g.ell(6, 2.2, 1.9, 1.1, '#4a3320');
}
function garden(g) {
  g.rect(6, 6, 1, 5, '#3f9a52'); g.rect(4, 8, 2, 1, '#3f9a52'); g.rect(7, 7, 2, 1, '#3f9a52');
  var p = [[6, 1.6], [4, 3], [8, 3], [4.8, 5], [7.2, 5]];
  for (var i = 0; i < p.length; i++) g.ell(p[i][0], p[i][1], 1.4, 1.4, '#b07ce8');
  g.ell(6, 3.4, 1, 1, '#ffe27a');
}
function roof(g) {
  for (var y = 0; y < 5; y++) g.rect(5 - y, 1 + y, 2 + 2 * y, 1, '#d9a566');
  g.rect(1, 5, 10, 1, '#b07f44');
  g.rect(2, 6, 8, 5, '#b86a4a'); g.rect(5, 8, 2, 3, '#3a2a22');
}
function harvest(g) {
  g.line(4, 8, 3, 2, '#8fb843'); g.line(6, 8, 6, 1, '#8fb843'); g.line(8, 8, 9, 2, '#8fb843');
  g.ell(3, 2.5, 1, 1.6, '#e6c84a'); g.ell(6, 1.8, 1, 1.6, '#e6c84a'); g.ell(9, 2.5, 1, 1.6, '#e6c84a');
  g.ell(6, 9, 5, 2.8, '#c58f50'); g.rect(1, 8, 10, 1, '#8f4f38'); g.px(3, 10, '#8f4f38'); g.px(6, 11, '#8f4f38'); g.px(9, 10, '#8f4f38');
}
function clay(g) {
  g.ell(6, 7, 4.2, 3.6, '#b86a4a'); g.px(4, 6, '#d98a68'); g.px(4, 7, '#d98a68');
  g.rect(4, 2, 4, 2, '#b86a4a'); g.rect(3, 2, 6, 1, '#8f4f38'); g.rect(2, 7, 8, 1, '#8f4f38'); g.rect(4, 10, 4, 1, '#8f4f38');
}
function cloth(g) {
  for (var j = 0; j < 5; j++) for (var i = 0; i < 5; i++)
    g.rect(1 + i * 2, 1 + j * 2, 2, 2, (i + j) % 2 ? '#e8c46a' : '#4aa0c8');
}
function village(g) {
  for (var h = 0; h < 2; h++) {
    var ox = h ? 6 : 1;
    g.rect(ox, 7, 5, 4, '#b86a4a'); g.rect(ox + 2, 9, 1, 2, '#3a2a22');
    g.rect(ox - 1, 6, 7, 1, '#d9a566'); g.rect(ox, 5, 5, 1, '#d9a566'); g.rect(ox + 1, 4, 3, 1, '#d9a566');
  }
}
function greenStone(g) {
  g.ell(6, 7, 4.8, 3.8, '#2f8f66'); g.ell(5, 6, 2.6, 1.8, '#5ccf94'); g.px(4, 5, '#c8f5de');
  g.rect(3, 10, 6, 1, '#1f6648');
}
function field(g) {
  g.rect(1, 2, 10, 9, '#8f6a3a');
  for (var r = 0; r < 4; r++) for (var x = 2; x < 11; x += 2) { g.px(x, 3 + 2 * r, '#7cd070'); g.px(x, 2 + 2 * r, '#3f9a52'); }
}
function pen(g) {
  g.rect(1, 5, 10, 1, WOODL); g.rect(1, 8, 10, 1, WOODL);
  g.rect(1, 3, 1, 8, WOOD); g.rect(5, 3, 2, 8, WOOD); g.rect(10, 3, 1, 8, WOOD);
}
function butterfly(g) {
  g.ell(3.5, 4, 2.8, 2.6, '#b07ce8'); g.ell(8.5, 4, 2.8, 2.6, '#b07ce8');
  g.ell(4, 8, 2, 2, '#d8b8ff'); g.ell(8, 8, 2, 2, '#d8b8ff');
  g.px(3, 4, '#ffe27a'); g.px(9, 4, '#ffe27a');
  g.rect(6, 3, 1, 7, INK); g.px(5, 2, INK); g.px(7, 2, INK);
}
function crucible(g) {
  g.rect(1, 4, 5, 1, '#f59a3a'); g.rect(1, 5, 5, 4, '#6f6c78'); g.rect(2, 9, 3, 1, '#6f6c78');
  g.rect(1, 5, 1, 4, '#8d8a93'); g.px(2, 4, '#ffe27a'); g.px(3, 4, '#ffe27a');
  g.line(6, 4, 8, 6, '#f59a3a', 1); g.px(8, 7, '#ffe27a');
  g.rect(7, 8, 5, 3, '#d9a23a'); g.rect(7, 8, 5, 1, '#f7d56a'); g.rect(7, 10, 5, 1, '#9a6a1f');
}
function alloy(g) {
  g.rect(3, 3, 7, 2, '#f7d56a'); g.rect(1, 5, 10, 5, '#d9a23a');
  g.rect(1, 5, 10, 1, '#f7d56a'); g.rect(1, 9, 10, 1, '#9a6a1f'); g.rect(10, 5, 1, 5, '#9a6a1f');
  g.px(3, 7, '#c8ccd6'); g.px(4, 7, '#c8ccd6'); g.px(4, 8, '#9aa0aa'); g.px(7, 6, '#c8ccd6');
  g.px(8, 8, '#c8ccd6'); g.px(8, 7, '#9aa0aa');
}
function brickWall(g) {
  g.rect(1, 2, 10, 8, '#e8d4a8');
  for (var r = 0; r < 4; r++) for (var b = -1; b < 3; b++) {
    var bx = 1 + b * 4 + (r % 2) * 2;
    var x0 = Math.max(bx, 1), x1 = Math.min(bx + 3, 11);
    if (x1 > x0) g.rect(x0, 2 + r * 2, x1 - x0, 1, (b + r) % 2 ? '#c98a55' : '#b86a4a');
  }
}
function wheel(g) {
  g.ell(6, 6, 5, 5, WOOD); g.ell(6, 6, 3.6, 3.6, CREAM);
  g.line(6, 2, 6, 10, WOOD, 1); g.line(2, 6, 10, 6, WOOD, 1);
  g.line(3, 3, 9, 9, WOOD, 1); g.line(9, 3, 3, 9, WOOD, 1);
  g.ell(6, 6, 1.6, 1.6, '#d9a23a'); g.px(5, 5, '#f7d56a'); g.px(6, 1, WOODL); g.px(1, 6, WOODL);
}
function town(g) {
  g.rect(4, 4, 4, 6, '#c98a55'); g.rect(4, 4, 1, 6, '#e0a874');
  for (var y = 0; y < 3; y++) g.rect(5 - y, 1 + y, 2 + 2 * y, 1, '#b86a4a');
  g.rect(0, 7, 4, 3, '#b86a4a'); g.rect(8, 7, 4, 3, '#b86a4a');
  g.rect(0, 6, 4, 1, '#d9a566'); g.rect(8, 6, 4, 1, '#d9a566');
  g.rect(5, 7, 2, 3, '#3a2a22'); g.px(5, 6, '#3a2a22'); g.px(6, 6, '#3a2a22'); g.rect(0, 10, 12, 1, '#8f6a3a');
}
function sail(g) {
  g.rect(6, 1, 1, 7, WOOD); g.tri(6, 1, 6, 4, '#f3e9d2', '#e8504a');
  g.rect(2, 7, 9, 2, WOOD); g.rect(1, 7, 1, 1, WOOD); g.rect(2, 7, 9, 1, WOODL);
  for (var x = 0; x < 12; x++) { g.px(x, 9 + (x % 4 < 2 ? 0 : 1), '#4a9ac8'); g.px(x, 10 + (x % 4 < 2 ? 0 : 1), '#8fbfe0'); }
}
function rosette(g) {
  g.rect(3, 8, 2, 3, '#e8504a'); g.rect(7, 8, 2, 3, '#c43a34');
  g.ell(6, 5, 3.6, 3.6, '#e8504a'); g.ell(6, 5, 1.8, 1.8, CREAM);
}

// ---- the Iron Age (issue #35) -----------------------------------------------------------------
var FE = '#4a505c', FEL = '#9aa5b5', FED = '#2c313b';
function bloom(g) { // first_bloom: a glowing lump of iron held in tongs
  g.line(0, 11, 5, 7, FE, 1); g.line(2, 11, 6, 8, FE, 1); g.px(0, 10, FEL); g.px(1, 11, FED);
  g.ell(7.5, 4.5, 3.6, 3, '#e8504a'); g.ell(7.5, 4.5, 2.7, 2.2, '#f59a3a'); g.ell(7.5, 4.5, 1.4, 1.2, '#ffe27a');
  g.px(6, 3, '#fff6c8'); g.px(5, 6, FEL); g.px(4, 7, FEL); g.px(10, 1, '#ffe27a'); g.px(11, 3, '#f59a3a');
}
function shareSheaf(g) { // fuller_harvest: a sheaf of wheat over an iron plough share
  var tops = [[1, 2], [3.5, 1], [6, 0], [8.5, 1], [11, 2]];
  for (var t = 0; t < tops.length; t++) {
    g.line(6, 7, Math.round(tops[t][0]), Math.round(tops[t][1]) + 1, '#a8a040', 1);
    g.ell(tops[t][0], tops[t][1], 1.1, 1.7, '#e6c84a'); g.px(tops[t][0], tops[t][1], '#f7e48a');
  }
  g.rect(5, 5, 3, 2, '#a8452f'); g.px(5, 5, '#d8674a');
  g.rect(3, 8, 9, 1, FEL); g.rect(2, 9, 8, 1, FE); g.rect(1, 10, 6, 1, FE); g.px(0, 11, FEL); g.px(1, 11, FEL);
  g.px(11, 8, FED); g.px(10, 9, FED); g.px(7, 10, FED);
}
function hillFort(g) { // the_hill_fort: a ringed hill with a timber rampart on top
  g.ell(6, 12, 6.2, 6.4, '#5fae58'); g.ell(6, 12, 4.6, 4.6, '#4a9a4a');
  g.px(1, 8, '#3f7a3a'); g.px(2, 7, '#3f7a3a'); g.px(10, 8, '#3f7a3a'); g.px(9, 7, '#3f7a3a');
  g.rect(3, 5, 6, 4, '#b0793f'); g.rect(3, 5, 6, 1, '#d9a566'); g.rect(3, 8, 6, 1, '#8a5a36');
  for (var s = 3; s < 9; s += 2) { g.px(s, 4, '#b0793f'); g.px(s, 3, '#d9a566'); }
  g.rect(5, 6, 2, 3, FED); g.px(5, 6, FE); g.px(6, 6, FE);
  g.px(2, 10, '#3f7a3a'); g.px(9, 10, '#3f7a3a'); g.rect(4, 10, 4, 1, '#3f7a3a');
}
function weighedCoin(g) { // silver_by_weight: a balance with a silver coin in one pan
  g.rect(5, 2, 2, 8, FE); g.rect(5, 2, 1, 8, FEL); g.rect(3, 10, 6, 1, FED); g.rect(4, 9, 4, 1, FE);
  g.rect(1, 2, 10, 1, FEL); g.px(0, 3, FEL); g.px(11, 3, FEL);
  g.line(1, 3, 1, 6, FED, 1); g.line(10, 3, 10, 6, FED, 1);
  g.rect(0, 7, 4, 1, FE); g.rect(8, 7, 4, 1, FE);
  g.ell(2, 5, 2.1, 2.1, '#6e7788'); g.ell(2, 5, 1.3, 1.3, '#f4f7fb'); g.px(2, 4, '#9aa5b5');
  g.rect(9, 5, 2, 2, '#6f6c78'); g.px(9, 5, '#8d8a93');
}
function tablet(g) { // written_word: a clay tablet pressed with signs
  g.rect(2, 1, 8, 10, '#c98a55'); g.rect(3, 0, 6, 12, '#c98a55');
  g.rect(2, 1, 1, 9, '#e0a874'); g.rect(3, 0, 5, 1, '#e0a874'); g.rect(9, 2, 1, 9, '#8f4f38'); g.rect(3, 11, 6, 1, '#8f4f38');
  var rows = [[4, 6, 8], [4, 5, 8], [5, 7], [4, 6, 7]];
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) { g.px(rows[r][c], 2 + r * 2, INK); g.px(rows[r][c], 3 + r * 2, r % 2 ? '#6a3f2a' : INK); }
  }
}
function longship(g) { // name_abroad: a deep-keeled ship under a square sail, a pennant at the mast
  g.rect(6, 0, 1, 8, WOOD); g.rect(7, 0, 3, 1, '#e8504a'); g.px(10, 1, '#e8504a');
  g.rect(2, 2, 9, 5, '#f3e9d2'); g.rect(2, 2, 9, 1, '#ffffff'); g.rect(2, 4, 9, 1, '#4a7fa8'); g.rect(2, 6, 9, 1, '#d8c8a0');
  g.rect(6, 2, 1, 5, WOOD);
  g.rect(1, 8, 10, 2, '#5a3a26'); g.rect(1, 8, 10, 1, '#8a5a36'); g.rect(3, 10, 6, 1, '#3a281a');
  g.px(0, 7, '#8a5a36'); g.px(0, 8, '#5a3a26'); g.px(11, 7, '#8a5a36'); g.px(11, 8, '#5a3a26');
  for (var x = 0; x < 12; x++) g.px(x, 11, (x % 4 < 2) ? '#4a9ac8' : '#8fbfe0');
}

// ---- the Classical Age (issue #40) ------------------------------------------------------------
var LS = '#e6dcc4', LSL = '#f6efdc', LSD = '#a89c80', TC = '#c0623a', TCL = '#e08a58', TCD = '#8a3f24';
function pavedStreets(g) { // paved_streets: dressed paving stones laid in rows
  var rows = [[0, 3], [3, 4], [7, 3], [10, 2]];
  for (var r = 0; r < 4; r++) for (var c = 0; c < 3; c++) {
    var w = 4, x0 = (r % 2) * 2 + c * 4 - 1;
    g.rect(Math.max(x0, 0), 1 + r * 3, Math.min(w, 12 - Math.max(x0, 0)) - (x0 < 0 ? 0 : 0), 2, (r + c) % 2 ? '#b4aea0' : '#9c9688');
    g.px(Math.max(x0, 0), 1 + r * 3, '#d0cabc');
  }
  g.rect(0, 11, 12, 1, '#6f6a5e');
}
function aqueduct(g) { // water_from_afar: arches carrying a channel of water
  g.rect(0, 2, 12, 2, '#4a9ac8'); g.rect(0, 2, 12, 1, '#8fbfe0');
  g.rect(0, 4, 12, 7, LS); g.rect(0, 4, 12, 1, LSL); g.rect(0, 10, 12, 1, LSD);
  for (var a = 0; a < 3; a++) {
    var cx = 2 + a * 4;
    g.rect(cx - 1, 7, 3, 4, '#5a4a38'); g.px(cx - 1, 6, '#5a4a38'); g.px(cx + 1, 6, '#5a4a38'); g.px(cx, 5, '#5a4a38');
  }
  g.px(11, 5, '#4a9ac8'); g.px(11, 6, '#8fbfe0');
}
function law(g) { // written_law: a scroll with lines of writing and a red seal
  g.rect(2, 1, 8, 9, '#f6efdc'); g.rect(2, 1, 8, 1, '#ffffff'); g.rect(2, 9, 8, 1, '#d8cdb0');
  g.ell(2, 5, 1.2, 4.6, '#d8cdb0'); g.ell(10, 5, 1.2, 4.6, '#d8cdb0'); g.ell(2, 5, 0.6, 4, LSL); g.ell(10, 5, 0.6, 4, LSL);
  for (var l = 0; l < 4; l++) g.rect(4, 2 + l * 2, l % 2 ? 4 : 5, 1, '#6a5a3a');
  g.ell(8, 9, 2, 2, '#c43a34'); g.ell(8, 9, 1, 1, '#e8504a'); g.px(6, 10, '#c43a34'); g.px(10, 10, '#c43a34');
}
function square(g) { // the_square: a colonnade under a pediment
  g.tri(6, 0, 4, 6, LSL, LS); g.rect(0, 3, 12, 1, LSD);
  g.rect(0, 4, 12, 1, LS);
  for (var c = 0; c < 4; c++) { var x = 1 + c * 3; g.rect(x, 5, 2, 5, LS); g.rect(x, 5, 1, 5, LSL); g.rect(x + 1, 5, 1, 5, LSD); }
  g.rect(0, 10, 12, 1, LSD); g.rect(0, 11, 12, 1, '#8a8068');
  g.px(6, 2, TC);
}
function lamp(g) { // lamp_and_stage: an oil lamp with its flame
  g.ell(6, 8, 4.4, 2.6, TC); g.ell(5, 7.4, 2.6, 1.2, TCL); g.rect(1, 8, 2, 1, TCD);
  g.rect(9, 7, 3, 1, TCD); g.px(11, 6, TCD); g.rect(4, 5, 3, 2, TCD);
  g.ell(6, 4, 1.6, 2.2, '#f59a3a'); g.ell(6, 4.6, 0.9, 1.3, '#ffe27a'); g.px(6, 1, '#f59a3a'); g.px(6, 2, '#f59a3a');
  g.rect(3, 10, 6, 1, TCD);
}
function triremeSail(g) { // wider_world: a ship under oars, towns on either shore
  g.rect(6, 0, 1, 7, WOOD); g.tri(6, 0, 6, 4, '#f3e9d2', '#c0623a');
  g.rect(1, 6, 10, 2, '#5a3a26'); g.rect(1, 6, 10, 1, '#8a5a36'); g.px(0, 5, '#8a5a36'); g.px(11, 5, '#8a5a36');
  g.line(2, 8, 0, 10, WOOD, 1); g.line(5, 8, 4, 11, WOOD, 1); g.line(8, 8, 9, 11, WOOD, 1); g.line(10, 8, 11, 10, WOOD, 1);
  for (var x = 0; x < 12; x++) g.px(x, 11 - (x % 4 < 2 ? 0 : 1), (x % 4 < 2) ? '#4a9ac8' : '#8fbfe0');
}
var GLYPHS = [fire, stoneTools, food, stories, group, garden, roof, harvest, clay, cloth, village,
  greenStone, field, pen, butterfly, crucible, alloy, brickWall, wheel, town, sail,
  bloom, shareSheaf, hillFort, weighedCoin, tablet, longship,
  pavedStreets, aqueduct, law, square, lamp, triremeSail, rosette];
var SHEET = new Buf(680, 20);
for (var i = 0; i < GLYPHS.length; i++) {
  var medal = new Buf(18, 18);
  medal.ell(8.5, 8.5, 8.6, 8.6, RIM); medal.ell(8.5, 8.5, 7.2, 7.2, CREAM);
  var g = new Buf(12, 12); GLYPHS[i](g);
  blit(medal, g, 3, 3);
  blit(SHEET, outlined(medal, OUT), i * 20, 0);
}

IMG.putImageData(SHEET.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/achievements.png');
console.log('ui achievements done');
