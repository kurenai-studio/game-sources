function hexToRgb(hex) {
  return [parseInt(hex.slice(1, 3), 16), parseInt(hex.slice(3, 5), 16), parseInt(hex.slice(5, 7), 16)];
}
function toLinear(c) { c /= 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
function toSrgb(c) {
  c = Math.max(0, Math.min(1, c));
  return Math.round(255 * (c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055));
}
function lightness(rgb) {
  const y = 0.2126 * toLinear(rgb[0]) + 0.7152 * toLinear(rgb[1]) + 0.0722 * toLinear(rgb[2]);
  return y > 0.008856 ? 116 * Math.cbrt(y) - 16 : 903.3 * y;
}

const RGB = PALETTE.map(hexToRgb);
const LSTAR = RGB.map(lightness);

const DICHROMAT = {
  // Standard LMS projections, applied in linear light so the result is a plausible simulation
  // rather than a hue rotation that happens to look different.
  protan: [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
  deuter: [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]
};

const SET_VIEW = { outline: [11, 14, 20], background: [40, 52, 74], gameplay: [201, 214, 232], hostile: [255, 61, 138] };

function paletteFor(mode) {
  if (mode === 'sets') return CLASSES.map(k => SET_VIEW[k]);
  if (mode === 'grey') {
    return RGB.map(rgb => {
      const y = 0.2126 * toLinear(rgb[0]) + 0.7152 * toLinear(rgb[1]) + 0.0722 * toLinear(rgb[2]);
      const v = toSrgb(y);
      return [v, v, v];
    });
  }
  if (mode === 'protan' || mode === 'deuter') {
    const m = DICHROMAT[mode];
    return RGB.map(rgb => {
      const [r, g, b] = rgb.map(toLinear);
      return [
        toSrgb(m[0][0] * r + m[0][1] * g + m[0][2] * b),
        toSrgb(m[1][0] * r + m[1][1] * g + m[1][2] * b),
        toSrgb(m[2][0] * r + m[2][1] * g + m[2][2] * b)
      ];
    });
  }
  return RGB;
}

// The phase's acceptance criterion is that enemy bullets are distinguishable from every background
// in the level, checked on the real thing. This is that check, run against the scene the page
// draws rather than against the palette in the abstract.
function audit(sceneKey) {
  const findings = [];

  const city = new Fb();
  drawCity(city, 0);
  const cityColours = new Set();
  for (let y = 0; y < H; y++) {
    for (let x = PLAY_X0; x <= PLAY_X1; x++) cityColours.add(city.at(x, y));
  }
  for (const c of cityColours) {
    if (CLASSES[c] === GAMEPLAY || CLASSES[c] === HOSTILE) {
      findings.push({ ok: false, text: 'the background uses ' + NAMES[c] + ', which is ' + CLASSES[c] + '-only' });
    }
  }

  const brightestBackground = Math.max(...[...cityColours].map(c => LSTAR[c]));
  const bulletBody = LSTAR[30], bulletCore = LSTAR[31];
  findings.push({
    ok: bulletBody - brightestBackground >= 10,
    text: 'enemy bullet body sits ' + (bulletBody - brightestBackground).toFixed(1) +
      ' points of L* above the brightest background pixel in this scene (' +
      NAMES[[...cityColours].reduce((a, b) => LSTAR[a] > LSTAR[b] ? a : b)] + ')'
  });
  findings.push({
    ok: bulletCore - brightestBackground >= 10,
    text: 'enemy bullet core sits ' + (bulletCore - brightestBackground).toFixed(1) + ' points above it'
  });

  for (const [id, s] of Object.entries(SPRITES)) {
    const hostile = id.startsWith('shot-e');
    for (const row of s.art) {
      for (const ch of row) {
        const c = CHARS[ch];
        if (c < 0 || CLASSES[c] === OUTLINE) continue;
        if (hostile && CLASSES[c] !== HOSTILE) {
          findings.push({ ok: false, text: id + ' is enemy fire and uses ' + NAMES[c] });
        }
        if (!hostile && CLASSES[c] !== GAMEPLAY) {
          findings.push({ ok: false, text: id + ' is a gameplay sprite and uses ' + NAMES[c] });
        }
      }
    }
  }

  const fb = renderScene(sceneKey, 0);
  const counts = { outline: 0, background: 0, gameplay: 0, hostile: 0 };
  for (let y = 0; y < H; y++) {
    for (let x = PLAY_X0; x <= PLAY_X1; x++) counts[CLASSES[fb.at(x, y)]]++;
  }
  const total = 208 * H;
  findings.push({
    ok: counts.hostile / total < 0.06,
    text: 'enemy fire covers ' + (100 * counts.hostile / total).toFixed(2) +
      '% of the playfield - intermediate density, not bullet hell'
  });

  if (!findings.some(f => !f.ok)) findings.unshift({ ok: true, text: 'no rule was broken by this scene' });
  return { findings, counts, brightestBackground };
}

if (typeof module !== 'undefined') {
  module.exports = { validateSprites, audit, renderScene, SCENES, SPRITES, PALETTE, LSTAR, NAMES, CLASSES };
}
