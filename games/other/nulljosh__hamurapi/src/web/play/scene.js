// Draws the city. A line-for-line port of app/App/Scene.swift: same layout, same timings, same sprites.
let SPR = {};                 // name -> [x, y, w, h] on the sheet
const SHEET = new Image();
const LOOKS = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"];
const INK = "#23262d", ACCENT = "#b5502c", GOOD = "#33692a";

// Every sprite sits on one sheet, so the art arrives whole or not at all.
function loadSprites() {
  return Promise.all([
    fetch("sprites.json").then(r => r.json()).then(map => { SPR = map; }),
    new Promise((done, fail) => { SHEET.onload = done; SHEET.onerror = () => fail(new Error("sprites.png did not load")); SHEET.src = "sprites.png"; }),
  ]);
}

// Deterministic pseudo-random in [0, 1) so every sprite keeps its own habits from frame to frame.
function rnd(i, salt) {
  let x = (Math.imul(i, 7919) + Math.imul(salt, 104729) + 12345) | 0;
  x = Math.imul(x ^ (x >>> 15), 0x2C1B3C6D); x = Math.imul(x ^ (x >>> 12), 0x297A2D39); x ^= x >>> 15;
  return (x >>> 0) % 100000 / 100000;
}
const smooth = v => { const c = Math.min(Math.max(v, 0), 1); return c * c * (3 - 2 * c); };
const villagers = people => people <= 0 ? 0 : Math.min(Math.max(Math.trunc(people / 4), 1), 40);
const graves = starved => Math.min(Math.trunc((starved + 3) / 4), 12);
const black = a => `rgba(0,0,0,${a})`, white = a => `rgba(255,255,255,${a})`;

// snap: {year, people, acres, grain, planted, starved, report, reportStart, frozenAge, grade, omen, cats, yearStart}
function paintScene(cv, snap, now, reserve, reduceMotion) {
  const dpr = window.devicePixelRatio || 1, cw = cv.clientWidth, chh = cv.clientHeight;
  if (cv.width !== Math.round(cw * dpr) || cv.height !== Math.round(chh * dpr)) { cv.width = Math.round(cw * dpr); cv.height = Math.round(chh * dpr); }
  const ctx = cv.getContext("2d");
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.imageSmoothingEnabled = false;
  const still = reduceMotion || snap.frozenAge != null;
  const t = still ? 1 : now / 1000;
  const s0 = Math.max(2, Math.round(Math.min(cw / 300, chh / 190))), s = s0 * dpr;  // canvas pixels per art pixel
  const W = cw / s0, UH = Math.max(80, (chh - reserve) / s0), hz = UH * 0.40, total = chh / s0;
  const r = snap.report;
  const rt = !r ? 999 : snap.frozenAge != null ? snap.frozenAge : reduceMotion ? 999 : Math.max(0, t - snap.reportStart);

  const w = n => SPR[n]?.[2] || 0, h = n => SPR[n]?.[3] || 0;
  function put(name, x, y, flip = false, alpha = 1) {
    const at = SPR[name];
    if (!at || alpha <= 0) return;
    const px = Math.round(x * s), py = Math.round(y * s), sw = at[2] * s, sh = at[3] * s;
    ctx.globalAlpha = Math.min(1, alpha);
    if (flip) { ctx.save(); ctx.translate(px + sw, py); ctx.scale(-1, 1); ctx.drawImage(SHEET, at[0], at[1], at[2], at[3], 0, 0, sw, sh); ctx.restore(); }
    else ctx.drawImage(SHEET, at[0], at[1], at[2], at[3], px, py, sw, sh);
    ctx.globalAlpha = 1;
  }
  function stand(name, cx, footY, flip = false, alpha = 1, shadow = true, lift = 0) {  // lift: the body bobs, the shadow stays down
    const sw = w(name), sh = h(name);
    if (shadow && alpha > 0) {
      ctx.fillStyle = black(0.13 * alpha);
      ctx.beginPath(); ctx.ellipse((cx + 1) * s, footY * s, sw * 0.42 * s, 1.6 * s, 0, 0, 2 * Math.PI); ctx.fill();
    }
    put(name, cx - sw / 2, footY - sh + 1 - lift, flip, alpha);
  }
  function rect(x, y, rw, rh, color) { ctx.fillStyle = color; ctx.fillRect(x * s, y * s, rw * s, rh * s); }
  function label(text, x, y, from, color) {  // a number that floats up and fades, like "+4,000"
    const age = rt - from;
    if (age <= 0 || age >= 1.8) return;
    ctx.globalAlpha = age < 1.3 ? 1 : Math.max(0, 1 - (age - 1.3) / 0.5);
    ctx.font = `800 ${Math.max(13 * dpr, 5.5 * s)}px -apple-system,system-ui,"Segoe UI",sans-serif`;
    ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.lineJoin = "round";
    ctx.strokeStyle = "#fff"; ctx.lineWidth = 3 * dpr;
    ctx.strokeText(text, x * s, (y - age * 9) * s);
    ctx.fillStyle = color; ctx.fillText(text, x * s, (y - age * 9) * s);
    ctx.globalAlpha = 1;
  }
  function glow(cx, cy, rad, rgb, a) {
    const g = ctx.createRadialGradient(cx * s, cy * s, 0, cx * s, cy * s, rad * s);
    g.addColorStop(0, `rgba(${rgb},${a})`); g.addColorStop(1, `rgba(${rgb},0)`);
    ctx.fillStyle = g; ctx.fillRect((cx - rad) * s, (cy - rad) * s, rad * 2 * s, rad * 2 * s);
  }
  const fmt = n => n.toLocaleString("en-US");

  // layout
  const granaryX = W - 20;
  const laneMin = Math.max(hz + 24, UH * 0.52), laneMax = Math.max(laneMin + 8, UH * 0.64);
  const riverTop = UH * 0.68, fieldTop = UH * 0.78;
  const fieldRows = Math.max(1, Math.trunc((UH - 4 - fieldTop) / 13)), fieldCols = Math.max(4, Math.trunc((W - 12) / 11));
  const plotSpread = (W - 12) / fieldCols;
  function wander(id, at) {  // where villager `id` has wandered to; they pace their own lane
    const margin = 8, span = W - 2 * margin;
    const u = (rnd(id, 4) * 2 * span + (5 + rnd(id, 3) * 7) * at) % (2 * span);
    return { x: margin + (u < span ? u : 2 * span - u), y: laneMin + rnd(id, 5) * (laneMax - laneMin), right: u < span };
  }

  // a jolt when something bad lands
  if (r && ((r.rats > 0 && rt > 1.4 && rt < 1.7) || (r.starved > 0 && rt > 1.8 && rt < 2.1) || (r.plague && rt > 3.4 && rt < 3.9)))
    ctx.translate((Math.trunc(rt * 40) % 2 === 0 ? 1 : -1) * s, (Math.trunc(rt * 31) % 2 === 0 ? 1 : -1) * s * 0.5);

  // sky
  // The reign is one long day: dawn in year one, a starry evening by year ten.
  const glide = !r ? 1 : smooth(rt / 3);
  const p = Math.min(Math.max(snap.year - 2 + glide, 0), 9) / 9;
  const dawn = smooth((0.25 - p) / 0.25), dusk = smooth((p - 0.55) / 0.45);
  const mix = (a, b, k) => a.map((v, i) => v + (b[i] - v) * k), css = c => `rgb(${c.map(v => Math.round(v * 255)).join(",")})`;
  let g = ctx.createLinearGradient(0, 0, 0, hz * s);
  g.addColorStop(0, css(mix(mix([0.985, 0.985, 0.98], [0.99, 0.955, 0.95], dawn), [0.56, 0.65, 0.82], dusk)));
  g.addColorStop(1, css(mix([0.925, 0.94, 0.955], [0.84, 0.88, 0.94], dusk)));
  ctx.fillStyle = g; ctx.fillRect(-4 * s, -4 * s, cv.width + 8 * s, hz * s + 4 * s);
  if (dusk > 0.3) for (let i = 0; i < 40; i++)
    rect(Math.round(rnd(i, 50) * W), Math.round(rnd(i, 51) * hz * 0.7), 1, 1, white((dusk - 0.3) / 0.7 * (0.6 + 0.4 * Math.sin(t * 2 + i))));
  const sx = W * (0.30 + 0.45 * p), sy = hz * (0.80 - 0.26 * Math.sin(p * Math.PI));
  glow(sx, sy, 34, "181,80,44", 0.22);
  for (let k = 0; k < 5; k++) {  // slow shafts of light
    const a = -0.9 + k * 0.45 + Math.sin(t * 0.2 + k) * 0.05;
    ctx.fillStyle = white(0.16); ctx.beginPath(); ctx.moveTo(sx * s, sy * s);
    ctx.lineTo((sx + Math.sin(a) * 260 - 9) * s, (sy + Math.cos(a) * 260) * s);
    ctx.lineTo((sx + Math.sin(a) * 260 + 9) * s, (sy + Math.cos(a) * 260) * s); ctx.fill();
  }
  put(`sun_${Math.trunc(t / 0.7) % 2}`, sx - w("sun_0") / 2, sy - h("sun_0") / 2);
  for (const [k, color] of [[0, "#e6e9ed"], [1, "#dadee3"]]) {  // two ridges of far hills
    ctx.fillStyle = color; ctx.beginPath(); ctx.moveTo(-4 * s, hz * s);
    for (let x = -4; x <= W + 4; x += 3)
      ctx.lineTo(x * s, (hz - (9 - k * 4) - (7 - k * 2) * Math.sin(x * (0.021 + k * 0.013) + 1.3 + k * 2.1) - 3 * Math.sin(x * 0.057 + k)) * s);
    ctx.lineTo((W + 4) * s, hz * s); ctx.fill();
  }
  [["cloud_a", 0.18, 7, 0.18], ["cloud_b", 0.55, 4, 0.34], ["cloud_a", 0.82, 5.5, 0.10], ["cloud_b", 0.33, 3, 0.06]].forEach((c, i) => {
    const span = W + 70;
    put(c[0], (c[1] * span + t * c[2]) % span - 40, hz * c[3] + 3 + (i % 2) * 3);
  });
  for (let b = 0; b < 3; b++) {
    const span = W + 40;
    put(`bird_${Math.trunc(t * 3 + b) % 2}`, (W * rnd(b, 1) + t * (14 + b * 5)) % span - 20, hz * (0.25 + 0.2 * rnd(b, 2)) + Math.sin(t + b * 2) * 3);
  }

  // ground
  g = ctx.createLinearGradient(0, hz * s, 0, cv.height);
  g.addColorStop(0, "#f4f4f1"); g.addColorStop(1, "#e6e6e2");
  ctx.fillStyle = g; ctx.fillRect(-4 * s, hz * s, cv.width + 8 * s, cv.height - hz * s + 4 * s);
  for (let i = 0; i < Math.trunc(W * (total - hz) / 70); i++)
    rect(Math.round(rnd(i, 20) * W), Math.round(hz + 2 + rnd(i, 21) * (total - hz - 2)), rnd(i, 22) < 0.3 ? 2 : 1, 1, black(0.055));

  // town
  const zw = w("ziggurat"), zh = h("ziggurat"), zcx = 5 + zw / 2, zfoot = hz + 10, ztop = zfoot - zh + 1;
  stand("ziggurat", zcx, zfoot);
  const fl = Math.trunc(t * 8) % 2;
  for (const fx of [zcx - zw / 2 + 10.5, zcx + zw / 2 - 10.5]) glow(fx, ztop + 13, 9 + fl, "255,184,77", 0.35);
  put(`flame_${fl}`, zcx - zw / 2 + 8, ztop + 17 - h("flame_0") + 1);
  put(`flame_${1 - fl}`, zcx + zw / 2 - 8 - w("flame_0"), ztop + 17 - h("flame_0") + 1);
  if (snap.grade !== "F") {  // a deposed king leaves the roof empty
    const grieving = r && ((r.starved > 0 && rt > 1.8 && rt < 5) || (r.plague && rt > 4.4 && rt < 7));
    const waving = snap.grade === "A+" || (r && r.yield >= 4 && rt > 0.8 && rt < 2.6) || Math.trunc(t / 2.2) % 3 === 0;
    stand(grieving ? "king_2" : `king_${waving ? Math.trunc(t * 2.5) % 2 : 0}`, zcx - 9, ztop + 9, false, 1, false);
  }
  const x0 = zcx + zw / 2 + 14, x1 = granaryX - 34;
  const cols = Math.max(1, Math.trunc((x1 - x0) / 20) + 1), n = Math.min(Math.max(Math.trunc(snap.people / 6), 1), cols * 2);
  for (let row = 0; row < 2; row++) for (let i = row; i < n; i += 2) {
    const col = Math.trunc(i / 2), name = ["house_a", "house_b", "house_c"][(i * 7 + 1) % 3];
    const cx = x0 + col * 20 + row * 9, foot = hz + 9 + row * 12;
    stand(name, cx, foot);
    if (row === 0 && col % 2 === 0) for (let k = 0; k < 3; k++) {  // cooking smoke
      const age = (t * 0.35 + k / 3 + i * 0.37) % 1;
      rect(cx + 3 + Math.sin(age * 6 + i) * 1.5, foot - h(name) - age * 13, 1.5 + age * 2, 1.5 + age * 2, black(0.16 * (1 - age)));
    }
  }
  [0.40, 0.66, 0.90].forEach((f, i) => { if (W * f < granaryX - 26) stand(`palm_${Math.trunc(t * 1.2 + i) % 2}`, W * f, hz + 11 + (i % 2) * 2); });
  const ratsIn = r && r.rats > 0 && rt > 1.4 && rt < 3.2;
  stand("granary", granaryX + (ratsIn ? Math.trunc(t * 20) % 2 : 0), hz + 11);
  for (let i = 0; i < Math.min(Math.max(Math.trunc(snap.grain / 700), 0), 10); i++) {
    const tier = i < 6 ? 0 : 1, k = tier === 0 ? i : i - 6;
    stand("sack", granaryX - 19 - k * 7 - tier * 3.5, hz + 12 - tier * 5, false, 1, tier === 0);
  }
  if (snap.cats) for (let k = 0; k < 2; k++) {  // they pace in front of the barn all year
    const u = (t * 9 + k * 17) % 44, right = u < 22;
    stand(`cat_${Math.trunc(t * 5 + k) % 2}`, granaryX - 36 + (right ? u : 44 - u) + k * 6, hz + 16 + k * 4, !right);
  }

  // caravan on the near bank, with long gaps between visits
  { const span = W * 2.2 + 90, cx = (t * 7 + 40) % span - 30, bob = Math.trunc(t * 2) % 2;
    stand(`camel_${bob}`, cx, riverTop - 1); stand(`camel_${1 - bob}`, cx - 30, riverTop - 1); }

  // river
  { const flood = snap.omen === "flood", top = riverTop - (flood ? 5 : 0), hgt = flood ? 13 : 7;
    g = ctx.createLinearGradient(0, top * s, 0, (top + hgt) * s);
    g.addColorStop(0, "#b5d6f2"); g.addColorStop(1, "#8fbae6");
    ctx.fillStyle = g; ctx.fillRect(-4 * s, top * s, cv.width + 8 * s, hgt * s);
    rect(-4, top, W + 8, 1, white(0.7)); rect(-4, top + hgt, W + 8, 1, black(0.10));
    let i = 0;
    for (let x = -((t * (flood ? 22 : 6)) % 12); x < W; x += 12, i++) rect(x, top + 2 + (i % 3) * 1.5, 5, 1, white(0.75));
    const boatX = (t * 9) % (W + 60) - 30;
    for (let k = 1; k <= 3; k++) rect(boatX - 9 - k * 5, top + 5 + (k % 2), 3, 1, white(0.8 - k * 0.2));  // wake
    stand("boat", boatX, top + 5 + Math.sin(t * 2) * 0.6, false, 1, false);
    const clock = t / 3.7, jump = Math.trunc(clock), age = (clock - jump) * 3.7;  // a fish jumps every few seconds
    if (age < 0.9) {
      const fx = 20 + rnd(jump, 60) * (W - 40), k = age / 0.9;
      put("fish", fx + k * 10, top + 1 - Math.sin(k * Math.PI) * 9);
      if (k < 0.15 || k > 0.85) rect(fx + (k < 0.5 ? 0 : 10) - 1, top + 1, 8, 1, white(0.9));
    } }

  // fields
  { const all = Math.min(Math.max(Math.trunc(snap.acres / 25), 0), fieldRows * fieldCols), planted = Math.min(all, Math.trunc((snap.planted + 24) / 25));
    for (let i = 0; i < all; i++) {
      const x = 6 + (i % fieldCols) * plotSpread + (plotSpread - 9) / 2, y = fieldTop + Math.trunc(i / fieldCols) * 13, sown = i < planted;
      rect(x, y + 2, 9, 11, black(sown ? 0.06 : 0.028)); rect(x, y + 12, 9, 1, black(sown ? 0.05 : 0.02));
      if (!sown) continue;
      for (let f = 0; f < 3; f++) rect(x + 1 + f * 3, y + 3, 1, 9, black(0.035));
      const sway = Math.trunc(t * 2 + i * 0.37) % 2;
      let name = `wheat_0_${sway}`;
      if (r) name = rt < 0.5 ? `wheat_1_${sway}` : r.yield >= 3 ? `wheat_2_${sway}` : `wheat_dry_${sway}`;
      else if (snap.grade) name = `wheat_2_${sway}`;
      put(name, x, y);
    }
    // Sheep graze whatever open ground is left below the fields.
    const pasture = fieldTop + Math.trunc((all + fieldCols - 1) / fieldCols) * 13 + 10, floor = total - 6;
    if (floor - pasture > 12) for (let k = 0; k < Math.min(6, Math.trunc((floor - pasture) / 10) + 2); k++) {
      const span = W - 30, u = (rnd(k, 80) * 2 * span + t * (1.5 + rnd(k, 81) * 2)) % (2 * span);
      const grazing = Math.trunc(t * 0.4 + rnd(k, 82) * 5) % 3 === 0;
      stand(`sheep_${grazing ? 1 : Math.trunc(t * 2 + k) % 2}`, 15 + (u < span ? u : 2 * span - u), pasture + rnd(k, 83) * (floor - pasture), u >= span);
    }
    if (all > 0) stand(`flag_${Math.trunc(t * 3) % 2}`, 4, fieldTop + 1, false, 1, false);
    if (!r) for (let b = 0; b < 4; b++) {  // butterflies
      const open = Math.trunc(t * 9 + b) % 2 === 0;
      rect(W * (0.2 + 0.2 * b) + Math.sin(t * 0.7 + b * 2) * 14, fieldTop - 4 + Math.sin(t * 1.3 + b) * 5 + (b % 2) * 8, open ? 3 : 1, open ? 1 : 2, b % 2 === 0 ? ACCENT : "#3b7bc6");
    }
    if (!r && !snap.grade && planted > 0) {  // an ox works the top row while you decide
      const span = W + 40, u = (t * 8) % (span * 2), right = u < span;
      stand(`ox_${Math.trunc(t * 3) % 2}`, (right ? u : span * 2 - u) - 20, fieldTop + 1, !right);
    } }

  // graves
  { const before = graves(snap.starved - (r ? r.starved : 0)), shown = r && rt < 2.4 ? before : graves(snap.starved);
    for (let k = 0; k < shown; k++) stand("tombstone", W - 8 - k * 9, laneMax + 6 - (k % 2) * 3); }

  // people
  { const folk = [], after = villagers(snap.people);
    if (r) {
      const before = villagers(r.peopleBefore), alive = villagers(r.peopleBefore - r.starved);
      const grown = Math.max(alive, villagers(r.peopleBefore - r.starved + r.born));
      const fade = id => r.plague && id >= after && rt > 4.4 ? Math.max(0, 1 - (rt - 4.4) / 0.8) : 1;
      for (let id = 0; id < before; id++) if (id < alive || rt <= 1.8) { const q = wander(id, t); folk.push({ ...q, id, alpha: id < alive ? fade(id) : 1 }); }
      for (let id = alive; id < grown; id++) {  // newcomers walk in from the left
        const start = 2.4 + (id - alive) * 0.12;
        if (rt <= start) continue;
        const q = wander(id, t), k = smooth((rt - start) / 2.4);
        folk.push({ x: -10 * (1 - k) + q.x * k, y: q.y, right: k < 1 ? true : q.right, id, alpha: fade(id) });
      }
    } else for (let id = 0; id < after; id++) folk.push({ ...wander(id, t), id, alpha: 1 });
    if (snap.omen === "refugees") for (let k = 0; k < 7; k++)
      folk.push({ x: 6 + (k % 4) * 7 + Math.trunc(k / 4) * 3, y: laneMin + 2 + Math.trunc(k / 4) * 7, right: true, id: 100 + k, alpha: -1 });
    const sick = r && r.plague && rt > 3.4 && rt < 6.6;
    const party = snap.grade === "A+" || snap.omen === "festival" || (r && r.yield >= 4 && rt > 0.8 && rt < 2.6);
    folk.sort((a, b) => a.y - b.y);
    // Now and then two of them settle it the old way: one vanishes into a cloud of dust and fists.
    const bout = t / 9, round = Math.trunc(bout), boutAge = (bout - round) * 9;
    const brawler = !r && !snap.grade && !snap.omen && after >= 6 && boutAge < 2.6 ? Math.trunc(rnd(round, 70) * after) : -1;
    for (const f of folk) {
      if (f.alpha === 0) continue;
      const look = LOOKS[f.id % LOOKS.length];
      if (f.id === brawler) {
        stand(`scuffle_${Math.trunc(t * 9) % 2}`, f.x, f.y + 1);
        for (let k = 0; k < 3; k++) rect(f.x - 9 + rnd(Math.trunc(t * 6) + k, 71) * 18, f.y - 14 + rnd(Math.trunc(t * 6) + k, 72) * 8, 1, 1, "#e8b02e");
      } else if (f.alpha < 0) stand(`villager_${look}_1`, f.x, f.y);
      else if (sick) stand(`villager_sick_${Math.trunc(t * 6 + f.id) % 4}`, f.x, f.y, !f.right, f.alpha);
      else if (party && f.id % 2 === 0) stand(`cheer_${look}_${Math.trunc(t * 5 + f.id) % 2}`, f.x, f.y, false, f.alpha);
      else { const step = Math.trunc(t * 6 + f.id) % 4; stand(`villager_${look}_${step}`, f.x, f.y, !f.right, f.alpha, true, step % 2); }
    }
    if (snap.omen === "caravan") for (let k = 0; k < 3; k++) stand(`camel_${k % 2}`, 26 + k * 30, laneMax + 3); }

  // the year plays out
  if (r) {
    const gx = granaryX, gy = hz - 8;
    for (let i = 0; i < Math.min(Math.trunc(r.harvest / 150), 40); i++) {  // grain flies to the granary
      const q = (rt - 0.2 - i * 0.045) / 1.2;
      if (q <= 0 || q >= 1) continue;
      const fx = 10 + plotSpread * Math.trunc(rnd(i, 6) * fieldCols), fy = fieldTop + Math.trunc(rnd(i, 7) * fieldRows) * 13;
      put("grain", fx + (gx - fx) * q, fy + (gy - fy) * q - Math.sin(q * Math.PI) * 18);
    }
    label(`+${fmt(r.harvest)}`, gx - 44, hz + 2, 0.9, r.yield >= 3 ? GOOD : INK);
    if (r.rats > 0) {
      for (let i = 0; i < Math.min(Math.trunc(r.rats / 60) + 3, 14); i++) {
        const start = 0.3 + i * 0.12, inP = smooth((rt - start) / 1.3), outP = smooth((rt - 3.0 - i * 0.05) / 1.2);
        if (rt <= start || outP >= 1) continue;
        put(`rat_${Math.trunc(t * 8 + i) % 2}`, (W + 8) + (gx - 10 - (W + 8)) * inP + (W + 8 - gx + 10) * outP + rnd(i, 12) * 8, hz + 9 + rnd(i, 8) * 9, outP > 0);
      }
      label(`-${fmt(r.rats)}`, gx - 44, hz + 12, 1.6, ACCENT);
    }
    const alive = villagers(r.peopleBefore - r.starved), before = villagers(r.peopleBefore);
    if (r.starved > 0) {  // the dead leave as ghosts
      for (let id = alive; id < before; id++) {
        const age = rt - 1.8;
        if (age <= 0 || age >= 3) continue;
        const q = wander(id, snap.frozenAge == null ? snap.reportStart + 1.8 : 1);
        put("ghost", q.x - 5 + Math.sin(age * 3 + id) * 1.5, q.y - 13 - age * 12, false, Math.max(0, 1 - age / 3));
      }
      label(`-${fmt(r.starved)}`, W / 2, laneMin - 16, 1.9, ACCENT);
    }
    if (r.born > 0) label(`+${fmt(r.born)}`, 22, laneMin - 16, 2.6, INK);
    if (r.plague) {
      if (rt > 3.2 && rt < 7.2) put("plague", -36 + (W + 72) * (rt - 3.2) / 4.0, laneMin - 30, false, 0.9);
      for (let i = 0; i < 6; i++) {
        const age = rt - 4.4 - i * 0.15;
        if (age > 0 && age < 1.8) put("skull", W * (0.15 + 0.14 * i), laneMin - 6 - age * 12, false, Math.max(0, 1 - age / 1.8));
      }
      label(`-${fmt(r.peopleBefore - r.starved + r.born - r.peopleAfter)}`, W / 2, laneMin - 26, 4.5, ACCENT);
    }
    // weather: dust on a failed harvest, fog with the plague
    if (r.yield <= 2 && rt > 0.4 && rt < 7) {
      const a = Math.min(1, (rt - 0.4) / 0.8) * Math.min(1, (7 - rt) / 1.5);
      for (let i = 0; i < 46; i++) rect((rnd(i, 30) * (W + 30) + t * (50 + rnd(i, 31) * 60)) % (W + 30) - 15, hz + rnd(i, 32) * (UH - hz), 3 + rnd(i, 33) * 5, 1, black(0.10 * a));
    }
    if (r.plague && rt > 3.2 && rt < 7.4) {
      const a = Math.min(1, (rt - 3.2) / 1.0) * Math.min(1, (7.4 - rt) / 1.2);
      ctx.fillStyle = `rgba(115,158,51,${0.13 * a})`; ctx.fillRect(-4 * s, -4 * s, cv.width + 8 * s, cv.height + 8 * s);
      for (let i = 0; i < 30; i++) rect(rnd(i, 36) * W + Math.sin(t + i) * 4, UH - (rnd(i, 34) * UH + t * (6 + rnd(i, 35) * 8)) % UH, 1, 1, `rgba(94,128,43,${0.5 * a})`);
    }
  }
  if (snap.grade === "F") {  // rain on a ruined reign
    ctx.fillStyle = "rgba(51,61,77,0.14)"; ctx.fillRect(-4 * s, -4 * s, cv.width + 8 * s, cv.height + 8 * s);
    for (let i = 0; i < 90; i++) {
      const fall = (rnd(i, 37) * total + t * (150 + rnd(i, 38) * 60)) % total;
      rect((rnd(i, 39) * (W + 40) - fall * 0.25 + W + 40) % (W + 40), fall, 1, 4, "rgba(92,115,148,0.45)");
    }
  }
  if (snap.grade === "A+") {  // fireworks and confetti on a great one
    const colors = ["181,80,44", "59,123,198", "232,176,46", "88,153,59"];
    for (let b = 0; b < 3; b++) {
      const clock = t / 1.7 + b * 0.37, k0 = Math.trunc(clock), age = (clock - k0) * 1.7;
      const cx = W * (0.2 + 0.6 * rnd(k0 * 3 + b, 40)), cy = hz * (0.25 + 0.5 * rnd(k0 * 3 + b, 41));
      if (age < 1.3) for (let k = 0; k < 18; k++) {
        const a = k / 18 * 2 * Math.PI, d = 26 * (1 - Math.exp(-age * 3));
        rect(cx + Math.cos(a) * d, cy + Math.sin(a) * d + age * age * 6, 2, 2, `rgba(${colors[(k0 + b) % 4]},${Math.max(0, 1 - age / 1.3)})`);
      }
    }
    for (let i = 0; i < 70; i++)
      rect(rnd(i, 11) * W + Math.sin(t * 2 + i) * 3, (t * (12 + rnd(i, 9) * 18) + rnd(i, 10) * UH) % (UH + 10) - 5, 2, 2, `rgb(${colors[i % 4]})`);
  }

  // each year opens with its number
  const since = t - (snap.yearStart || 0);
  if (snap.yearStart > 0 && !r && !snap.grade && since >= 0 && since < 2.2) {
    ctx.globalAlpha = Math.min(1, since / 0.3) * Math.min(1, (2.2 - since) / 0.6);
    ctx.font = `800 ${Math.max(26 * dpr, 11 * s)}px -apple-system,system-ui,"Segoe UI",sans-serif`;
    ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillStyle = INK;
    ctx.fillText(`Year ${snap.year}`, cv.width / 2, hz * 0.45 * s);
    ctx.globalAlpha = 1;
  }

  // vignette
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  g = ctx.createRadialGradient(cv.width / 2, cv.height * 0.4, Math.min(cv.width, cv.height) * 0.45, cv.width / 2, cv.height * 0.4, Math.max(cv.width, cv.height) * 0.8);
  g.addColorStop(0, "rgba(0,0,0,0)"); g.addColorStop(1, "rgba(0,0,0,0.07)");
  ctx.fillStyle = g; ctx.fillRect(0, 0, cv.width, cv.height);
}
