const stack = document.getElementById('stack');
const overlay = document.getElementById('overlay');
const inner = document.getElementById('inner');
const octx = overlay.getContext('2d');

const state = { screen: 'menu', view: 'normal', zoom: 2, guides: false, squint: false };

const SCREEN_OPTS = [
  ['menu', 'Main menu', 'play, options, quit'],
  ['ship', 'Ship selection', 'one ship, its stats'],
  ['options', 'Options', 'volumes and the mouse'],
  ['pause', 'Pause', 'over a frozen playfield'],
  ['victory', 'Victory', 'the end-of-level bonus'],
  ['defeat', 'Defeat', 'retry or menu']
];
const TOGGLES = [['guides', 'Safe area', '24 px from every edge'], ['squint', 'Squint', 'does the hierarchy hold']];

// The flow the spec describes, so the screens are read as a sequence rather than as six pictures.
const FLOW = [
  ['Main menu', 'menu'],
  ['Ship selection', 'ship'],
  ['Level 1', null],
  ['Pause, at any point', 'pause'],
  ['Victory, with a life left', 'victory'],
  ['Defeat, with none', 'defeat']
];

function draw() {
  renderOptions(document.getElementById('scene-opts'), SCREEN_OPTS,
    k => state.screen === k, k => { state.screen = k; draw(); }, 'radio');
  renderOptions(document.getElementById('view-opts'), VIEW_OPTS,
    k => state.view === k, k => { state.view = k; draw(); }, 'radio');
  renderOptions(document.getElementById('toggle-opts'), TOGGLES,
    k => state[k], k => { state[k] = !state[k]; draw(); }, 'toggle');
  renderOptions(document.getElementById('zoom-opts'), zoomOptions(),
    z => state.zoom === z, z => { state.zoom = z; draw(); }, 'radio');

  const sc = SCREENS[state.screen];
  document.getElementById('scene-label').textContent = sc.label;
  document.getElementById('scene-note').textContent = sc.note;
  inner.classList.toggle('squint', state.squint);

  blitTo(stack, renderScreen(state.screen), state.view, state.zoom);
  overlay.width = stack.width; overlay.height = stack.height;
  paintGuides();
  reportScale(stack, document.getElementById('scale-note'), state.zoom);
  checksInto(document.getElementById('checks'), screenChecks());
}

function paintGuides() {
  octx.clearRect(0, 0, overlay.width, overlay.height);
  if (!state.guides) return;
  const z = state.zoom;
  octx.lineWidth = Math.max(1, z * 0.5);
  octx.setLineDash([z * 2, z * 2]);
  octx.strokeStyle = 'rgba(255,201,74,.6)';
  octx.strokeRect(SAFE * z + .5, SAFE * z + .5, (480 - SAFE * 2) * z, (270 - SAFE * 2) * z);
  octx.setLineDash([]);
  octx.strokeStyle = 'rgba(47,191,212,.7)';
  octx.beginPath();
  octx.moveTo(TITLE_X * z + .5, 0);
  octx.lineTo(TITLE_X * z + .5, overlay.height);
  octx.moveTo(0, TITLE_Y * z + .5);
  octx.lineTo(overlay.width, TITLE_Y * z + .5);
  octx.stroke();
}

// The screens have no bullets to measure, so what is worth checking is that they stayed inside the
// palette and inside the safe area, and that nothing the spec excludes crept back in.
function screenChecks() {
  const rows = [];
  const fb = renderScreen(state.screen);

  let outside = 0;
  for (let y = 0; y < 270; y++) {
    for (let x = 0; x < 480; x++) {
      const inSafe = x >= SAFE && x < 480 - SAFE && y >= SAFE && y < 270 - SAFE;
      if (!inSafe && ![0, 1, 2, 3].includes(fb.at(x, y))) outside++;
    }
  }
  rows.push({ ok: outside === 0, text: outside === 0
    ? 'nothing but ground and framing sits outside the 24 px safe area'
    : outside + ' px of content sit outside the safe area' });

  const used = new Set();
  for (let i = 0; i < fb.d.length; i++) used.add(fb.d[i]);
  const bad = [...used].filter(c => c < 0 || c >= PALETTE.length);
  rows.push({ ok: bad.length === 0, text: bad.length === 0
    ? 'every pixel is one of the 32 colours of ls32'
    : bad.length + ' pixels are outside the palette' });

  const reserved = [...used].filter(c => CLASSES[c] === HOSTILE);
  rows.push({ ok: reserved.length === 0, text: reserved.length === 0
    ? 'the reserved hue band does not appear - there is no enemy fire on a menu'
    : 'the screen uses ' + reserved.map(c => NAMES[c]).join(', ') + ', which belong to enemy fire' });

  rows.push({ ok: true, text: 'colours in use: ' + [...used].sort((a, b) => a - b).map(c => NAMES[c]).join(' ') });
  return rows;
}

function buildFlow() {
  const list = document.getElementById('flow');
  list.innerHTML = FLOW.map(([label, key]) => '<li>' + (key
    ? '<button class="link" type="button" data-screen="' + key + '">' + label + '</button>'
    : '<span>' + label + '</span>') + '</li>').join('');
  for (const b of list.children) {
    const button = b.children && b.children[0];
    if (button && button.dataset && button.dataset.screen) {
      button.addEventListener('click', () => { state.screen = button.dataset.screen; draw(); });
    }
  }
}

buildFlow();
draw();
addEventListener('resize', () => reportScale(stack, document.getElementById('scale-note'), state.zoom));
