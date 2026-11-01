// Shared interface pieces. Everything here only defines functions, so the engine still loads in
// node without a DOM - which is what lets check.js run the pages' interface code at all.

function mkButton(label, hint, active, role, onClick) {
  const b = document.createElement('button');
  b.className = 'opt';
  b.type = 'button';
  if (role === 'radio') { b.setAttribute('role', 'radio'); b.setAttribute('aria-checked', String(active)); }
  else b.setAttribute('aria-pressed', String(active));
  b.innerHTML = '<span class="mark">' + (active ? '&gt;' : '') + '</span><span>' + label +
    (hint ? ' <small>' + hint + '</small>' : '') + '</span>';
  b.addEventListener('click', onClick);
  return b;
}

function renderOptions(container, items, isActive, onPick, role) {
  container.textContent = '';
  for (const [key, label, hint] of items) {
    container.appendChild(mkButton(label, hint, isActive(key), role, () => onPick(key)));
  }
}

const VIEW_OPTS = [
  ['normal', 'Normal', ''],
  ['grey', 'Greyscale', 'R3, the value gap'],
  ['deuter', 'Deuteranopia', 'R4'],
  ['protan', 'Protanopia', 'R4'],
  ['sets', 'Set map', 'R1, the two sets']
];

// Rasterises a framebuffer of any size onto a canvas at an integer factor, smoothing off. The
// intermediate canvas exists so the browser never resamples: it copies whole pixels or nothing.
function blitTo(canvas, fb, view, zoom) {
  const colours = paletteFor(view);
  const src = document.createElement('canvas');
  src.width = fb.w; src.height = fb.h;
  const sctx = src.getContext('2d');
  const image = sctx.createImageData(fb.w, fb.h);
  const data = image.data;
  for (let i = 0; i < fb.w * fb.h; i++) {
    const c = colours[fb.d[i]];
    data[i * 4] = c[0]; data[i * 4 + 1] = c[1]; data[i * 4 + 2] = c[2]; data[i * 4 + 3] = 255;
  }
  sctx.putImageData(image, 0, 0);
  canvas.width = fb.w * zoom; canvas.height = fb.h * zoom;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(src, 0, 0, canvas.width, canvas.height);
}

// The project forbids fractional scaling, so the page says out loud whether what you are looking
// at is actually an integer multiple or something the browser resampled.
function reportScale(canvas, note, zoom) {
  const shown = canvas.getBoundingClientRect().width;
  const exact = Math.abs(shown - canvas.width) < 0.5;
  note.textContent = exact ? 'integer scale ×' + zoom
    : 'browser is scaling this fractionally — ' + Math.round(shown) + ' px shown for ' + canvas.width;
  note.className = exact ? 'scale-ok' : 'scale-bad';
}

function checksInto(list, rows) {
  list.textContent = '';
  for (const f of rows) {
    const li = document.createElement('li');
    const flag = document.createElement('span');
    flag.className = 'flag ' + (f.ok ? 'pass' : 'fail');
    flag.textContent = f.ok ? 'PASS' : 'FAIL';
    const text = document.createElement('span');
    text.textContent = f.text;
    li.append(flag, text);
    list.appendChild(li);
  }
}

function zoomOptions() { return [[1, '×1', '480 × 270'], [2, '×2', '960 × 540'], [3, '×3', '1440 × 810']]; }
