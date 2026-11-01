const stack = document.getElementById('stack');
const overlay = document.getElementById('overlay');
const inner = document.getElementById('inner');
const octx = overlay.getContext('2d');

const state = { scene: 'escalation', view: 'normal', zoom: 2, hitboxes: false, squint: false, guides: false, drift: false };
let scroll = 0, raf = 0;

const SCENE_OPTS = [
  ['escalation', 'Escalation', 'tank, carrier, mixed fire'],
  ['boss', 'Boss fight', 'the bar and five colliders'],
  ['hit', 'Just took a hit', 'blink, flash, a life gone']
];
const TOGGLES = [
  ['hitboxes', 'Hitboxes', 'what actually collides'],
  ['squint', 'Squint', 'R5 and R7'],
  ['guides', 'HUD guides', '04-hud-layout.md'],
  ['drift', 'Scroll', 'R9, velocity separation']
];

function setDrift() {
  cancelAnimationFrame(raf);
  if (!state.drift) return;
  const step = () => { scroll = (scroll + 1) % 640; paint(); raf = requestAnimationFrame(step); };
  raf = requestAnimationFrame(step);
}

function paint() {
  blitTo(stack, renderScene(state.scene, scroll), state.view, state.zoom);
  overlay.width = stack.width; overlay.height = stack.height;
  paintOverlay();
}

function paintOverlay() {
  const z = state.zoom;
  octx.clearRect(0, 0, overlay.width, overlay.height);
  octx.lineWidth = Math.max(1, z * 0.5);

  if (state.guides) {
    octx.strokeStyle = 'rgba(47,191,212,.55)';
    octx.setLineDash([z * 2, z * 2]);
    // Straight out of the tables in 04-hud-layout.md: label, then the widget under it.
    const boxes = [
      [12, 14, 30, 7], [12, 24, 57, 9], [12, 44, 30, 7], [12, 54, 33, 9],
      [12, 74, 30, 7], [12, 84, 57, 7], [12, 104, 30, 7], [12, 114, 29, 13],
      [12, 146, 36, 7], [12, 156, 17, 17], [34, 161, 48, 7],
      [362, 14, 30, 7], [412, 24, 56, 11], [362, 44, 24, 7], [347, 20, 8, 230]
    ];
    for (const [x, y, w, h] of boxes) octx.strokeRect(x * z + .5, y * z + .5, w * z, h * z);
    octx.setLineDash([]);
    octx.strokeStyle = 'rgba(255,201,74,.5)';
    octx.strokeRect(PLAY_X0 * z + .5, .5, 208 * z, H * z);
  }

  if (state.hitboxes) {
    const colour = {
      player: 'rgba(157,242,250,.95)', enemy: 'rgba(255,201,74,.9)',
      hostile: 'rgba(255,255,255,.95)', pickup: 'rgba(127,224,138,.95)'
    };
    for (const c of colliders(state.scene)) {
      octx.strokeStyle = colour[c.kind];
      octx.beginPath();
      octx.arc((c.x + .5) * z, (c.y + .5) * z, c.r * z, 0, Math.PI * 2);
      octx.stroke();
    }
  }
}

function draw() {
  renderOptions(document.getElementById('scene-opts'), SCENE_OPTS,
    k => state.scene === k, k => { state.scene = k; draw(); }, 'radio');
  renderOptions(document.getElementById('view-opts'), VIEW_OPTS,
    k => state.view === k, k => { state.view = k; draw(); }, 'radio');
  renderOptions(document.getElementById('toggle-opts'), TOGGLES,
    k => state[k], k => { state[k] = !state[k]; setDrift(); draw(); }, 'toggle');
  renderOptions(document.getElementById('zoom-opts'), zoomOptions(),
    z => state.zoom === z, z => { state.zoom = z; draw(); }, 'radio');

  inner.classList.toggle('squint', state.squint);
  const sc = SCENES[state.scene];
  document.getElementById('scene-label').textContent = sc.label;
  document.getElementById('scene-note').textContent = sc.note;

  paint();
  const rows = validateSprites().map(p => ({ ok: false, text: p })).concat(audit(state.scene).findings);
  checksInto(document.getElementById('checks'), rows);
  reportScale(stack, document.getElementById('scale-note'), state.zoom);
}

function buildLegend() {
  const legend = document.getElementById('legend');
  const items = [['#9DF2FA', 'player'], ['#FFC94A', 'enemy'], ['#FFFFFF', 'enemy fire'], ['#7FE08A', 'pickup']];
  legend.innerHTML = '<span style="width:100%">Hitbox overlay</span>' + items.map(
    ([c, label]) => '<span><i style="background:' + c + '"></i>' + label + '</span>').join('');
}

function buildPalette() {
  const groups = [['Background-legal', BACKGROUND], ['Gameplay-only', GAMEPLAY],
    ['Reserved — enemy fire', HOSTILE], ['Shared outline', OUTLINE]];
  document.getElementById('palette-panel').innerHTML = groups.map(([label, kind]) => {
    const swatches = PALETTE.map((hex, i) => [hex, i]).filter(([, i]) => CLASSES[i] === kind)
      .map(([hex, i]) => '<b style="background:' + hex + '" title="' + hex + ' L* ' +
        LSTAR[i].toFixed(1) + '"><span>' + NAMES[i] + '</span></b>').join('');
    return '<div class="swatches"><span>' + label + '</span><div class="ramp">' + swatches + '</div></div>';
  }).join('');
}

buildLegend();
buildPalette();
draw();
addEventListener('resize', () => reportScale(stack, document.getElementById('scale-note'), state.zoom));
