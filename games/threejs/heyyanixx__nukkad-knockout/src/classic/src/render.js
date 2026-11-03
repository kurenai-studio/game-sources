import { W, H, FLOOR_Y, cowX } from './game.js';
import { SUPER } from './moves.js';

const GOLD = '#e3b65a', INK = '#0a0a0c';
const rad = (d) => (d * Math.PI) / 180;

// ---------------- stage backgrounds (static layer cached per stage) ----------------
const cache = {};
function seeded(seed) { let s = seed; return () => ((s = (s * 16807) % 2147483647) / 2147483647); }

function buildStage(id) {
  const c = document.createElement('canvas'); c.width = W; c.height = H;
  const g = c.getContext('2d'); const r = seeded(id === 'tapri' ? 42 : 77);
  if (id === 'tapri') {
    const sky = g.createLinearGradient(0, 0, 0, FLOOR_Y); sky.addColorStop(0, '#07070f'); sky.addColorStop(1, '#22142e');
    g.fillStyle = sky; g.fillRect(0, 0, W, H);
    for (let i = 0; i < 60; i++) { g.fillStyle = `rgba(255,255,255,${0.2 + r() * 0.6})`; g.fillRect(r() * W, r() * 220, 1.5, 1.5); }
    g.fillStyle = '#f3e7c0'; g.beginPath(); g.arc(800, 80, 30, 0, 7); g.fill();
    g.fillStyle = '#22142e'; g.beginPath(); g.arc(812, 72, 26, 0, 7); g.fill();
    // far buildings
    for (let x = -20; x < W; x += 50 + r() * 40) {
      const bw = 50 + r() * 60, bh = 120 + r() * 170;
      g.fillStyle = '#120d1c'; g.fillRect(x, FLOOR_Y - 60 - bh, bw, bh + 60);
      for (let wy = FLOOR_Y - 50 - bh; wy < FLOOR_Y - 80; wy += 18) for (let wx = x + 6; wx < x + bw - 10; wx += 14)
        if (r() < 0.35) { g.fillStyle = r() < 0.7 ? '#e3b65a55' : '#7fd3ff44'; g.fillRect(wx, wy, 7, 9); }
    }
    // chai tapri (stall)
    g.fillStyle = '#3a2416'; g.fillRect(60, 300, 240, 120);
    g.fillStyle = '#5a3a22'; g.fillRect(50, 290, 260, 16);
    g.fillStyle = '#c0392b'; g.beginPath(); g.moveTo(40, 290); g.lineTo(320, 290); g.lineTo(300, 250); g.lineTo(60, 250); g.closePath(); g.fill();
    for (let i = 0; i < 7; i++) { g.fillStyle = i % 2 ? '#f4efe4' : '#c0392b'; g.fillRect(60 + i * 34, 250, 34, 12); }
    g.fillStyle = INK; g.fillRect(110, 214, 140, 34); g.strokeStyle = GOLD; g.lineWidth = 2; g.strokeRect(110, 214, 140, 34);
    g.fillStyle = GOLD; g.font = 'bold 20px Arial Black, Impact, sans-serif'; g.textAlign = 'center'; g.fillText('CHAI ₹10', 180, 238);
    g.fillStyle = '#8a8f99'; g.beginPath(); g.ellipse(120, 300, 22, 16, 0, 0, 7); g.fill(); g.fillRect(138, 290, 14, 5);
    for (let i = 0; i < 5; i++) { g.fillStyle = '#b5652a'; g.fillRect(170 + i * 20, 284, 12, 12); }
    // lamp post
    g.fillStyle = '#2a2a33'; g.fillRect(860, 180, 8, FLOOR_Y - 180); g.fillRect(820, 178, 48, 6);
    const lamp = g.createRadialGradient(826, 190, 4, 826, 300, 200); lamp.addColorStop(0, 'rgba(255,214,140,0.35)'); lamp.addColorStop(1, 'rgba(255,214,140,0)');
    g.fillStyle = lamp; g.fillRect(620, 180, 340, 300);
    // road
    const road = g.createLinearGradient(0, FLOOR_Y - 40, 0, H); road.addColorStop(0, '#2b2630'); road.addColorStop(1, '#141218');
    g.fillStyle = road; g.fillRect(0, FLOOR_Y - 30, W, H);
    g.fillStyle = '#3a3440'; g.fillRect(0, FLOOR_Y - 34, W, 6);
    for (let x = 20; x < W; x += 120) { g.fillStyle = '#e3b65a66'; g.fillRect(x, FLOOR_Y + 30, 60, 5); }
  } else {
    const sky = g.createLinearGradient(0, 0, 0, FLOOR_Y); sky.addColorStop(0, '#2a1a4a'); sky.addColorStop(0.55, '#c2457a'); sky.addColorStop(1, '#ffad4a');
    g.fillStyle = sky; g.fillRect(0, 0, W, H);
    g.fillStyle = '#ffd98a'; g.beginPath(); g.arc(480, 330, 70, 0, 7); g.fill();
    g.fillStyle = 'rgba(255,217,138,0.25)'; g.beginPath(); g.arc(480, 330, 110, 0, 7); g.fill();
    for (let x = -10; x < W; x += 30 + r() * 30) {
      const bw = 40 + r() * 50, bh = 60 + r() * 140;
      g.fillStyle = '#5a2850'; g.fillRect(x, FLOOR_Y - 90 - bh, bw, bh + 90);
      if (r() < 0.4) { g.fillStyle = '#3e1c3a'; g.fillRect(x + 8, FLOOR_Y - 110 - bh, 24, 22); g.fillRect(x + 12, FLOOR_Y - 88 - bh, 3, 10); g.fillRect(x + 26, FLOOR_Y - 88 - bh, 3, 10); }
    }
    // metro viaduct
    g.fillStyle = '#3a1f3c'; g.fillRect(0, 300, W, 16);
    for (let x = 40; x < W; x += 160) g.fillRect(x, 316, 18, FLOOR_Y - 316);
    // clothesline
    g.strokeStyle = '#222'; g.lineWidth = 1.5; g.beginPath(); g.moveTo(560, 360); g.quadraticCurveTo(700, 385, 900, 362); g.stroke();
    const cols = ['#e0402f', '#29d3ff', '#f2d43c', '#ffffff'];
    for (let i = 0; i < 6; i++) { g.fillStyle = cols[i % 4]; g.fillRect(590 + i * 48, 368 + Math.sin(i) * 4, 26, 30 + (i % 2) * 10); }
    // terrace floor + parapet
    g.fillStyle = '#7a6a66'; g.fillRect(0, FLOOR_Y - 60, W, 26);
    g.fillStyle = '#5c4f4c'; g.fillRect(0, FLOOR_Y - 36, W, 6);
    const fl = g.createLinearGradient(0, FLOOR_Y - 30, 0, H); fl.addColorStop(0, '#8d7f78'); fl.addColorStop(1, '#4e4542');
    g.fillStyle = fl; g.fillRect(0, FLOOR_Y - 30, W, H);
    g.strokeStyle = '#00000022'; for (let x = 0; x < W; x += 80) { g.beginPath(); g.moveTo(x, FLOOR_Y - 30); g.lineTo(x - 40, H); g.stroke(); }
    // water tank
    g.fillStyle = '#1d1d1d'; g.fillRect(70, 330, 90, 80); g.fillRect(64, 322, 102, 12); g.fillStyle = '#2c2c2c'; g.fillRect(80, 410, 8, 30); g.fillRect(142, 410, 8, 30);
  }
  if (id === 'platform') {
    const sky = g.createLinearGradient(0, 0, 0, FLOOR_Y); sky.addColorStop(0, '#1b2a3a'); sky.addColorStop(1, '#3d5466');
    g.fillStyle = sky; g.fillRect(0, 0, W, H);
    for (let x = -10; x < W; x += 40 + r() * 30) { const bh = 80 + r() * 120; g.fillStyle = '#22303d'; g.fillRect(x, 250 - bh, 50 + r() * 40, bh + 40); }
    // roof + pillars
    g.fillStyle = '#2a2a2e'; g.fillRect(0, 0, W, 60); g.fillStyle = '#e3b65a'; g.fillRect(0, 60, W, 5);
    for (let x = 60; x < W; x += 220) { g.fillStyle = '#4a4a52'; g.fillRect(x, 65, 16, FLOOR_Y - 95); }
    // far track + train area
    g.fillStyle = '#1c1c20'; g.fillRect(0, 300, W, 90); g.fillStyle = '#6b6b70'; g.fillRect(0, 372, W, 4); g.fillRect(0, 384, W, 4);
    for (let x = 0; x < W; x += 24) { g.fillStyle = '#3b2f25'; g.fillRect(x, 376, 12, 14); }
    // station board (fictional)
    g.fillStyle = '#f2d43c'; g.fillRect(360, 100, 240, 56); g.strokeStyle = INK; g.lineWidth = 4; g.strokeRect(360, 100, 240, 56);
    g.fillStyle = INK; g.font = 'bold 26px Arial Black, Impact, sans-serif'; g.textAlign = 'center'; g.fillText('NUKKAD JN.', 480, 138);
    g.fillStyle = '#ddd'; g.beginPath(); g.arc(760, 120, 24, 0, 7); g.fill(); g.strokeStyle = INK; g.lineWidth = 3; g.stroke(); g.beginPath(); g.moveTo(760, 120); g.lineTo(760, 104); g.moveTo(760, 120); g.lineTo(772, 124); g.stroke();
    // chai cart
    g.fillStyle = '#7a3b1e'; g.fillRect(90, 360, 120, 50); g.fillStyle = '#c0392b'; g.fillRect(84, 330, 132, 14); g.fillStyle = '#8a8f99'; g.beginPath(); g.ellipse(120, 352, 16, 11, 0, 0, 7); g.fill();
    dotS(g, 110, 418, 12); dotS(g, 190, 418, 12);
    // platform floor + yellow line
    g.fillStyle = '#8a8478'; g.fillRect(0, 390, W, 12);
    const fl = g.createLinearGradient(0, 402, 0, H); fl.addColorStop(0, '#7d776c'); fl.addColorStop(1, '#4a463f'); g.fillStyle = fl; g.fillRect(0, 402, W, H);
    g.fillStyle = '#f2d43c'; g.fillRect(0, 404, W, 7);
    for (let x = 0; x < W; x += 60) { g.fillStyle = '#00000018'; g.fillRect(x, 411, 2, H); }
  }
  // HEYYANIXX wall tag
  g.save(); g.globalAlpha = 0.18; g.fillStyle = GOLD; g.font = 'bold 26px Arial Black, Impact, sans-serif'; g.textAlign = 'center';
  g.fillText('HEYYANIXX', id === 'tapri' ? 560 : id === 'platform' ? 700 : 300, id === 'tapri' ? 330 : id === 'platform' ? 200 : 290); g.restore();
  return c;
}

function dotS(g, x, y, r) { g.fillStyle = '#111'; g.beginPath(); g.arc(x, y, r, 0, 7); g.fill(); }

function drawStage(ctx, game, frame) {
  const id = game.stage;
  if (!cache[id]) cache[id] = buildStage(id);
  ctx.drawImage(cache[id], 0, 0);
  if (id === 'platform' && game.trainT > 0) {
    const x = W + 60 - game.trainT * 14;
    ctx.fillStyle = '#b8402f'; ctx.fillRect(x, 300, 1400, 76); ctx.fillStyle = '#f2d43c'; ctx.fillRect(x, 346, 1400, 6);
    for (let k = 0; k < 40; k++) { ctx.fillStyle = '#1d2733'; ctx.fillRect(x + 30 + k * 34, 312, 22, 22); }
    ctx.fillStyle = '#ffffcc'; ctx.beginPath(); ctx.arc(x + 10, 340, 7, 0, 7); ctx.fill();
  }
  if (id === 'tapri') {
    // flickering string lights
    for (let i = 0; i < 24; i++) {
      const x = 20 + i * 40, y = 140 + Math.sin(i * 0.5) * 12 + (i % 2) * 6;
      const on = (Math.sin(frame * 0.07 + i * 1.7) > -0.6);
      ctx.fillStyle = on ? ['#ff5a5a', '#e3b65a', '#5affb4', '#7fd3ff'][i % 4] : '#333';
      ctx.beginPath(); ctx.arc(x, y, 4, 0, 7); ctx.fill();
      if (on) { ctx.fillStyle = 'rgba(255,220,150,0.08)'; ctx.beginPath(); ctx.arc(x, y, 12, 0, 7); ctx.fill(); }
    }
    ctx.strokeStyle = '#111'; ctx.lineWidth = 1; ctx.beginPath();
    for (let i = 0; i < 24; i++) { const x = 20 + i * 40, y = 140 + Math.sin(i * 0.5) * 12 + (i % 2) * 6; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); } ctx.stroke();
    // chai steam
    for (let i = 0; i < 3; i++) { const t = (frame * 0.6 + i * 20) % 60; ctx.fillStyle = `rgba(255,255,255,${0.25 - t / 260})`; ctx.beginPath(); ctx.arc(120 + Math.sin((frame + i * 30) * 0.05) * 6, 282 - t, 6 + t / 8, 0, 7); ctx.fill(); }
  } else if (id === 'terrace') {
    // kites
    for (let i = 0; i < 4; i++) {
      const x = 150 + i * 220 + Math.sin(frame * 0.013 + i) * 30, y = 90 + i % 2 * 50 + Math.cos(frame * 0.02 + i * 2) * 14;
      ctx.save(); ctx.translate(x, y); ctx.rotate(Math.sin(frame * 0.03 + i) * 0.3);
      ctx.fillStyle = ['#ff3b6b', '#e3b65a', '#29d3ff', '#7bd23c'][i]; ctx.beginPath(); ctx.moveTo(0, -16); ctx.lineTo(12, 0); ctx.lineTo(0, 18); ctx.lineTo(-12, 0); ctx.closePath(); ctx.fill();
      ctx.restore(); ctx.strokeStyle = 'rgba(255,255,255,0.35)'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(x, y + 18); ctx.quadraticCurveTo(x + 40, y + 160, x + 10 * i, 440); ctx.stroke();
    }
    // metro train passing every ~12 s
    const tt = frame % 720;
    if (tt < 260) {
      const x = -460 + tt * 6;
      ctx.fillStyle = '#d8d8e0'; ctx.fillRect(x, 262, 440, 38);
      ctx.fillStyle = '#e3b65a'; ctx.fillRect(x, 288, 440, 5);
      for (let k = 0; k < 14; k++) { ctx.fillStyle = '#334'; ctx.fillRect(x + 10 + k * 31, 268, 20, 14); }
    }
  }
}

// ---------------- fighters ----------------
function pose(f, frame) {
  const P = { lean: 6, legF: [16, 4], legB: [-14, -4], armF: [38, 150], armB: [28, 142], rot: 0, lift: 0 };
  const b = Math.sin(frame * 0.09 + f.side) * 2.5;
  P.lean += b;
  const crouchLegs = () => { P.legF = [78, -22]; P.legB = [24, -72]; P.lean = 16; };
  const st = f.state, a = f.attack;
  const ext = () => {
    if (!a) return 0; const m = a.move, fr = a.frame;
    if (fr < m.s) return fr / m.s; if (fr < m.s + m.a) return 1; return Math.max(0, 1 - (fr - m.s - m.a) / Math.max(1, m.r));
  };
  if (st === 'walk') {
    const c = f.walkCycle;
    P.legF = [Math.sin(c) * 26, Math.sin(c) * 26 - 12 - Math.abs(Math.cos(c)) * 10];
    P.legB = [-Math.sin(c) * 26, -Math.sin(c) * 26 - 12 - Math.abs(Math.sin(c)) * 10];
  }
  if (st === 'crouch') { crouchLegs(); P.armF = [55, 160]; P.armB = [45, 150]; }
  if ((st === 'idle' || st === 'walk' || st === 'crouch') && f.holdingBack) { P.armF = [72, 172]; P.armB = [58, 166]; P.lean -= 6; }
  if (st === 'blockstun') { if (f.isLow) crouchLegs(); P.armF = [72, 172]; P.armB = [58, 166]; P.lean = -8; }
  if (st === 'jump') { P.legF = [70, -30]; P.legB = [36, -64]; P.armF = [120, 160]; P.armB = [100, 150]; }
  if (st === 'attack' || st === 'airattack') {
    const e = ext(), id = a ? a.move.id : 'jab';
    if (st === 'airattack') { P.legF = [70, -30]; P.legB = [36, -64]; }
    switch (id) {
      case 'jab': case 'jab2': case 'rush': case 'airp':
        P.armF = [38 + 54 * e, 150 - 62 * e]; P.armB = [10, 120]; P.lean = 6 + (id === 'rush' ? 26 : 12) * e;
        if (id === 'jab2') { P.armB = [38 + 54 * e, 150 - 62 * e]; P.armF = [10, 120]; }
        break;
      case 'lowp': crouchLegs(); P.armF = [40 + 50 * e, 150 - 62 * e]; P.armB = [30, 140]; P.lean = 22; break;
      case 'upper': P.armF = [40 + 135 * e, 150 + 25 * e]; P.armB = [20, 130]; P.lean = 6 - 14 * e; P.legF = [8, 0]; P.legB = [-22, -6]; break;
      case 'kick': case 'fly': case 'airk':
        P.legF = [16 + 80 * e, 4 + 88 * e]; P.legB = [-8, -6]; P.lean = 6 - 18 * e; P.armF = [60, 150]; P.armB = [-20, 60];
        if (id === 'fly') P.lift = -34 * e;
        break;
      case 'round': case 'spin': P.legF = [16 + 96 * e, 4 + 104 * e]; P.legB = [-4, -4]; P.lean = 6 - 30 * e; P.armF = [80, 120]; P.armB = [-40, 40]; break;
      case 'sweep': crouchLegs(); P.legF = [78 + 12 * e, -22 + 112 * e]; P.lean = 28; P.armF = [70, 90]; P.armB = [20, 100]; break;
      case 'beep': P.armF = [90, 90]; P.armB = [70, 120]; P.lean = 10 * e; break;
      case 'emote': P.armF = [150 + 20 * Math.sin(frame * 0.5), 190]; P.armB = [20, 10]; P.lean = -4; break;
      case 'roast': P.armF = [60, 168]; P.armB = [40, 100]; P.lean = 12 * e; break;
      case 'grab': P.armF = [40 + 45 * e, 90]; P.armB = [40 + 40 * e, 95]; P.lean = 10 * e; break;
    }
  }
  if (st === 'throw') { const k = Math.min(1, f.throwT / 15); P.armF = [85 + 70 * k, 120 + 50 * k]; P.armB = [80 + 70 * k, 120 + 50 * k]; P.lean = -10 * k; }
  if (st === 'hitstun' || st === 'grabbed') { P.lean = -22; P.armF = [-25, 20]; P.armB = [-50, -10]; P.legF = [20, 10]; P.legB = [-10, -20]; }
  if (st === 'dizzy') { P.lean = Math.sin(frame * 0.2) * 14; P.armF = [12, 8]; P.armB = [-8, -4]; }
  if (st === 'launched' || (st === 'ko' && f.airborne)) { P.rot = -Math.min(80, f.t * 6); P.armF = [150, 180]; P.armB = [120, 170]; P.legF = [40, 20]; P.legB = [10, -10]; }
  if (st === 'knockdown' || (st === 'ko' && !f.airborne)) { P.rot = -90; P.armF = [160, 175]; P.armB = [140, 165]; P.legF = [5, 0]; P.legB = [-5, 0]; P.lean = 0; }
  if (st === 'getup') { P.rot = -90 * (f.stun / 16); }
  if (st === 'victory') { const j = Math.abs(Math.sin(frame * 0.12)); P.armF = [175, 180]; P.armB = [150 - 30 * j, 170]; P.lift = -10 * j; P.lean = -4; }
  if (st === 'super') { P.armF = [115, 125]; P.armB = [105, 115]; P.lean = -6; P.lift = -6 * Math.sin(frame * 0.4); }
  if (st === 'badla') { const k = (f.superT % 6) < 3; P.armF = k ? [92, 90] : [20, 120]; P.armB = k ? [20, 120] : [92, 90]; P.lean = 24; }
  if (st === 'taunt') { P.armF = [150 + 25 * Math.sin(frame * 0.6), 200]; P.armB = [30, 20]; P.lean = -8 + 6 * Math.sin(frame * 0.3); }
  if (st === 'intro') { P.armF = [100 + 30 * Math.sin(frame * 0.2), 160]; }
  return P;
}

const dir = (deg, facing) => [Math.sin(rad(deg)) * facing, Math.cos(rad(deg))];

function seg(ctx, pts, width, color) {
  ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  ctx.strokeStyle = INK; ctx.lineWidth = width + 5; ctx.beginPath(); ctx.moveTo(pts[0][0], pts[0][1]); for (const p of pts.slice(1)) ctx.lineTo(p[0], p[1]); ctx.stroke();
  ctx.strokeStyle = color; ctx.lineWidth = width; ctx.beginPath(); ctx.moveTo(pts[0][0], pts[0][1]); for (const p of pts.slice(1)) ctx.lineTo(p[0], p[1]); ctx.stroke();
}
function dot(ctx, x, y, r, color) { ctx.fillStyle = INK; ctx.beginPath(); ctx.arc(x, y, r + 2.5, 0, 7); ctx.fill(); ctx.fillStyle = color; ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.fill(); }

export function drawFighter(ctx, f, frame, opts = {}) {
  const c = f.char, L = c.look, s = c.scale, fc = f.facing, wide = L.wide || 1;
  const P = pose(f, frame);
  const thigh = 38 * s, shin = 38 * s, torso = 50 * s, headR = 17 * s * (opts.bigHead ? 1.75 : 1), ua = 27 * s, fa = 25 * s;
  // legs relative to hip, then ground the lowest foot
  const legPts = (lg) => { const d1 = dir(lg[0], fc), d2 = dir(lg[1], fc); const k = [d1[0] * thigh, d1[1] * thigh]; return [[0, 0], k, [k[0] + d2[0] * shin, k[1] + d2[1] * shin]]; };
  const lf = legPts(P.legF), lb = legPts(P.legB);
  const hipH = Math.max(lf[2][1], lb[2][1]);
  const sx = f.x, sy = FLOOR_Y + f.y;
  ctx.save();
  // shadow
  ctx.fillStyle = 'rgba(0,0,0,0.35)'; ctx.beginPath(); ctx.ellipse(sx, FLOOR_Y + 2, 34 * s * wide, 8, 0, 0, 7); ctx.fill();
  ctx.translate(sx, sy + P.lift);
  if (P.rot) ctx.rotate(rad(P.rot) * fc);
  ctx.translate(0, -hipH);
  const hip = [0, 0];
  const lean = rad(P.lean);
  const neck = [Math.sin(lean) * torso * fc, -Math.cos(lean) * torso];
  const head = [neck[0] + Math.sin(lean) * (headR + 3) * fc, neck[1] - Math.cos(lean) * (headR + 3)];
  const sh = [neck[0] * 0.92, neck[1] * 0.92 + 3];
  const armPts = (ar) => { const d1 = dir(ar[0], fc), d2 = dir(ar[1], fc); const e = [sh[0] + d1[0] * ua, sh[1] + d1[1] * ua]; return [sh, e, [e[0] + d2[0] * fa, e[1] + d2[1] * fa]]; };
  const af = armPts(P.armF), ab = armPts(P.armB);
  const legW = (L.thinLegs ? 9 : 13) * s, armW = 10 * s * (wide > 1 ? 1.25 : 1);
  if (f.flash > 0 || opts.silhouette) ctx.globalCompositeOperation = 'source-over';

  // aura for supers / secret boss
  if (f.state === 'super' || f.state === 'badla' || c.id === 'anish') {
    const g = ctx.createRadialGradient(0, -torso * 0.4, 10, 0, -torso * 0.4, 110 * s);
    g.addColorStop(0, (c.superColor || GOLD) + (f.state === 'super' ? 'aa' : '33')); g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, -torso * 0.4, 110 * s, 0, 7); ctx.fill();
  }
  // back arm + back leg
  seg(ctx, ab, armW, shade(L.skin, -20)); dot(ctx, ab[2][0], ab[2][1], 6 * s, shade(L.skin, -20));
  seg(ctx, lb, legW, shade(L.pants, -25)); shoe(ctx, lb, L.shoes, fc, s);
  if (L.extra === 'selfie') { const h = ab[2]; ctx.strokeStyle = '#ccc'; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(h[0], h[1]); ctx.lineTo(h[0] - 10 * fc, h[1] - 60 * s); ctx.stroke(); ctx.fillStyle = '#111'; ctx.fillRect(h[0] - 18 * fc - 6, h[1] - 72 * s, 14, 20); }
  // torso
  const tw = 15 * s * wide;
  ctx.fillStyle = INK; torsoPath(ctx, hip, neck, tw + 3, fc); ctx.fill();
  ctx.fillStyle = L.shirt; torsoPath(ctx, hip, neck, tw, fc); ctx.fill();
  if (L.saree) { ctx.fillStyle = shade(L.shirt, 30); ctx.beginPath(); ctx.moveTo(neck[0] - tw * fc, neck[1] + 4); ctx.lineTo(neck[0] + tw * 0.6 * fc, neck[1]); ctx.lineTo(hip[0] + tw * fc, hip[1]); ctx.lineTo(hip[0] - tw * 0.2 * fc, hip[1] - 8); ctx.closePath(); ctx.fill(); }
  if (L.extra === 'hood') { ctx.strokeStyle = GOLD; ctx.lineWidth = 2; const cx = (hip[0] + neck[0]) / 2, cy = (hip[1] + neck[1]) / 2; ctx.beginPath(); ctx.arc(cx, cy, 7, 0, 7); ctx.moveTo(cx - 11, cy); ctx.lineTo(cx + 11, cy); ctx.moveTo(cx, cy - 11); ctx.lineTo(cx, cy + 11); ctx.stroke(); }
  if (L.extra === 'anish' || L.extra === 'mintu') { ctx.fillStyle = L.acc; ctx.fillRect((hip[0] + neck[0]) / 2 - 3, neck[1] + 6, 6, torso * 0.7); }
  if (L.extra === 'towel') { ctx.fillStyle = L.acc; ctx.beginPath(); ctx.moveTo(neck[0] - 12 * fc, neck[1] + 2); ctx.lineTo(neck[0] + 4 * fc, neck[1] - 2); ctx.lineTo(neck[0] - 16 * fc, neck[1] + 34); ctx.closePath(); ctx.fill(); }
  if (L.saree) { ctx.fillStyle = L.pants; ctx.beginPath(); ctx.moveTo(-tw - 2, -4); ctx.lineTo(tw + 2, -4); ctx.lineTo(tw + 10, thigh * 0.95); ctx.lineTo(-tw - 10, thigh * 0.95); ctx.closePath(); ctx.fill(); }
  // front leg
  seg(ctx, lf, legW, L.pants); shoe(ctx, lf, L.shoes, fc, s);
  // head
  drawHead(ctx, head, headR, f, frame, fc);
  // front arm
  seg(ctx, [af[0], af[1]], armW, (L.extra === 'hood' || L.extra === 'anish' || L.extra === 'mintu' || L.extra === 'helmet') ? L.shirt : L.skin);
  seg(ctx, [af[1], af[2]], armW, L.skin); dot(ctx, af[2][0], af[2][1], 6.5 * s, L.skin);
  if (L.extra === 'pan') { const h = af[2], d = dir(P.armF[1], fc); ctx.strokeStyle = '#2a2a2a'; ctx.lineWidth = 5; ctx.beginPath(); ctx.moveTo(h[0], h[1]); ctx.lineTo(h[0] + d[0] * 22, h[1] + d[1] * 22); ctx.stroke(); dot(ctx, h[0] + d[0] * 36, h[1] + d[1] * 36, 15 * s, '#3a3a3a'); }
  if (L.extra === 'mintu' && f.attack && (f.attack.move.id === 'roast' || f.attack.move.id === 'beep')) { const h = af[2]; dot(ctx, h[0] + 6 * fc, h[1] - 8, 6, '#555'); }
  ctx.restore();
  if (f.state === 'dizzy') {
    for (let i = 0; i < 3; i++) { const a2 = frame * 0.12 + i * 2.1; ctx.fillStyle = GOLD; star(ctx, sx + Math.cos(a2) * 26, sy - 160 * s + Math.sin(a2) * 7, 6); }
  }
}

function torsoPath(ctx, hip, neck, w, fc) {
  ctx.beginPath();
  ctx.moveTo(hip[0] - w * 0.85, hip[1] + 4); ctx.lineTo(hip[0] + w * 0.85, hip[1] + 4);
  ctx.lineTo(neck[0] + w * 1.05, neck[1] + 4); ctx.quadraticCurveTo(neck[0], neck[1] - 6, neck[0] - w * 1.05, neck[1] + 4);
  ctx.closePath();
}
function shoe(ctx, leg, color, fc, s) { const f = leg[2]; ctx.fillStyle = INK; ctx.beginPath(); ctx.ellipse(f[0] + 5 * fc, f[1] + 1, 12 * s, 6.5 * s, 0, 0, 7); ctx.fill(); ctx.fillStyle = color; ctx.beginPath(); ctx.ellipse(f[0] + 5 * fc, f[1], 9.5 * s, 4.5 * s, 0, 0, 7); ctx.fill(); }
function star(ctx, x, y, r) { ctx.beginPath(); for (let i = 0; i < 10; i++) { const a = (i * Math.PI) / 5 - Math.PI / 2, rr = i % 2 ? r * 0.45 : r; ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } ctx.closePath(); ctx.fill(); }
export function shade(hex, amt) {
  const n = parseInt(hex.slice(1), 16); const cl = (v) => Math.max(0, Math.min(255, v));
  const r = cl((n >> 16) + amt), g = cl(((n >> 8) & 255) + amt), b = cl((n & 255) + amt);
  return '#' + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
}

function drawHead(ctx, [x, y], r, f, frame, fc) {
  const L = f.char.look;
  // back-of-head items
  if (L.extra === 'bun') dot(ctx, x - r * 0.95 * fc, y - r * 0.5, r * 0.5, L.hair);
  if (L.extra === 'hood') { ctx.fillStyle = INK; ctx.beginPath(); ctx.arc(x - 2 * fc, y - 1, r + 7, 0, 7); ctx.fill(); ctx.fillStyle = L.shirt; ctx.beginPath(); ctx.arc(x - 2 * fc, y - 1, r + 5, 0, 7); ctx.fill(); }
  dot(ctx, x, y, r, L.skin);
  // hair
  ctx.fillStyle = L.hair;
  if (L.extra === 'anish') {
    // anime-style silver spikes swept back
    ctx.beginPath(); ctx.arc(x, y - 1, r * 1.02, Math.PI * 0.95, Math.PI * 2.05); ctx.closePath(); ctx.fill();
    for (let i = 0; i < 7; i++) {
      const a = Math.PI * (1.0 + i * 0.16) , b0 = a - 0.2, b1 = a + 0.2, len = r * (1.0 + (i % 2 ? 0.35 : 0.7));
      const sweep = -fc * r * 0.35;
      ctx.beginPath(); ctx.moveTo(x + Math.cos(b0) * r * 0.9, y + Math.sin(b0) * r * 0.9);
      ctx.lineTo(x + Math.cos(a) * (r + len) * 0.95 + sweep, y + Math.sin(a) * (r + len) * 0.8);
      ctx.lineTo(x + Math.cos(b1) * r * 0.9, y + Math.sin(b1) * r * 0.9); ctx.closePath(); ctx.fill();
      ctx.strokeStyle = '#8a93a3'; ctx.lineWidth = 1.2; ctx.stroke();
    }
    ctx.fillRect(x + r * 0.1 * fc - 6, y - r * 0.9, 12, r * 0.5);   // fringe
  } else if (L.extra === 'bun') { ctx.beginPath(); ctx.arc(x, y - 2, r, Math.PI, 0); ctx.fill(); }
  else if (L.extra === 'helmet') { ctx.fillStyle = L.acc; ctx.beginPath(); ctx.arc(x, y - 2, r + 3, Math.PI * 1.02, -0.02); ctx.fill(); ctx.fillStyle = '#ffffff55'; ctx.fillRect(x - r * 0.2 * fc - 6, y - r * 0.9, 10, 4); }
  else if (L.extra !== 'hood') { ctx.beginPath(); ctx.arc(x - 2 * fc, y - 3, r * 0.98, Math.PI * 1.05, -0.15); ctx.lineTo(x - r * fc, y); ctx.fill();
    if (L.extra === 'towel' || L.extra === 'mintu') { for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.moveTo(x - 8 + i * 7, y - r * 0.85); ctx.lineTo(x - 4 + i * 7 + 4 * fc, y - r * 1.35); ctx.lineTo(x + i * 7, y - r * 0.8); ctx.fill(); } } }
  if (L.extra === 'headband') { ctx.fillStyle = '#ffffff'; ctx.fillRect(x - r, y - r * 0.55, r * 2, 5); }
  // face
  const ex = x + r * 0.42 * fc, ey = y - 2;
  if (L.redEyes) { ctx.fillStyle = '#ff2a2a'; ctx.shadowColor = '#ff2a2a'; ctx.shadowBlur = 10; ctx.beginPath(); ctx.ellipse(ex, ey, 3.5, 2.6, 0, 0, 7); ctx.fill(); ctx.shadowBlur = 0; }
  else if (f.state === 'dizzy' || f.state === 'ko') { ctx.strokeStyle = INK; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(ex - 3, ey - 3); ctx.lineTo(ex + 3, ey + 3); ctx.moveTo(ex + 3, ey - 3); ctx.lineTo(ex - 3, ey + 3); ctx.stroke(); }
  else { ctx.fillStyle = INK; ctx.beginPath(); ctx.ellipse(ex, ey, 2.4, 3, 0, 0, 7); ctx.fill(); }
  ctx.strokeStyle = INK; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.moveTo(ex - 5 * fc, ey - 6); ctx.lineTo(ex + 4 * fc, ey - (f.state === 'attack' ? 4 : 7)); ctx.stroke();
  if (L.shades) { ctx.fillStyle = '#0b0b0b'; ctx.fillRect(x + (fc > 0 ? -2 : -r - 2), ey - 4, r + 4, 7); ctx.fillStyle = '#ffffff66'; ctx.fillRect(x + (fc > 0 ? 6 : -r + 4), ey - 3, 4, 2); }
  if (L.glasses) { ctx.strokeStyle = '#d4af37'; ctx.lineWidth = 1.6; ctx.beginPath(); ctx.arc(ex, ey, 4.8, 0, 7); ctx.stroke(); }
  if (L.extra === 'mustache') { ctx.fillStyle = INK; ctx.beginPath(); ctx.ellipse(x + r * 0.55 * fc, y + r * 0.35, 8, 3.2, 0, 0, 7); ctx.fill(); }
  if (L.beard) { ctx.fillStyle = L.hair; ctx.beginPath(); ctx.arc(x + 2 * fc, y + 2, r * 0.98, 0.1, Math.PI - 0.1); ctx.fill(); }
  // mouth
  const open = f.state === 'hitstun' || f.state === 'super' || f.state === 'launched' || (f.attack && f.attack.move.special) || f.state === 'victory';
  ctx.fillStyle = L.beard ? '#f0e0d0' : INK;
  if (open) { ctx.beginPath(); ctx.ellipse(x + r * 0.55 * fc, y + r * 0.5, 3.5, 4, 0, 0, 7); ctx.fill(); }
  else { ctx.fillRect(x + r * 0.35 * fc - 3, y + r * 0.5, 7, 2); }
  if (L.bigEars) { ctx.fillStyle = L.skin; ctx.strokeStyle = INK; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(x - r * 0.5 * fc, y - 4); ctx.lineTo(x - r * 1.9 * fc, y - r * 1.1); ctx.lineTo(x - r * 0.4 * fc, y + 6); ctx.closePath(); ctx.fill(); ctx.stroke(); }
  if (L.extra === 'headset' || L.extra === 'mintu') {
    const col = L.rgb ? `hsl(${(frame * 4) % 360},90%,60%)` : L.acc;
    ctx.strokeStyle = INK; ctx.lineWidth = 6; ctx.beginPath(); ctx.arc(x, y, r + 3, Math.PI * 1.1, -0.1); ctx.stroke();
    ctx.strokeStyle = col; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(x, y, r + 3, Math.PI * 1.1, -0.1); ctx.stroke();
    dot(ctx, x - r * 0.2 * fc, y + 1, 6, col);
    ctx.strokeStyle = '#222'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(x - r * 0.2 * fc, y + 4); ctx.quadraticCurveTo(x + r * 0.4 * fc, y + r, x + r * 0.8 * fc, y + r * 0.6); ctx.stroke();
  }
  if (L.extra === 'anish') { ctx.fillStyle = GOLD; ctx.fillRect(x - r * 0.9, y + r * 0.9, r * 1.8, 3); }
}

// ---------------- projectiles ----------------
function drawProjectile(ctx, p, frame) {
  const x = p.x, y = FLOOR_Y + p.y, d = Math.sign(p.vx || p.owner.facing);
  ctx.save(); ctx.translate(x, y);
  switch (p.type) {
    case 'chai': {
      const g = ctx.createLinearGradient(0, -50, 0, 45); g.addColorStop(0, '#f4dfc0'); g.addColorStop(0.3, '#c8853f'); g.addColorStop(1, '#6b3a16');
      ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(-55 * d, 45);
      for (let i = 0; i <= 10; i++) ctx.lineTo((-55 + i * 11) * d, -30 - Math.sin(i * 0.9 + frame * 0.4) * 12 - i * 2);
      ctx.lineTo(55 * d, 45); ctx.closePath(); ctx.fill();
      ctx.fillStyle = '#ffffffaa'; for (let i = 0; i < 6; i++) { ctx.beginPath(); ctx.arc((-40 + i * 16) * d, -40 - Math.sin(frame * 0.3 + i) * 6, 5, 0, 7); ctx.fill(); }
      break;
    }
    case 'auto': {
      ctx.scale(d, 1);
      ctx.fillStyle = '#1f7a3a'; roundRect(ctx, -75, -10, 150, 45, 10); ctx.fill();
      ctx.fillStyle = '#f2d43c'; ctx.beginPath(); ctx.moveTo(-70, -10); ctx.quadraticCurveTo(-60, -60, 10, -58); ctx.lineTo(60, -50); ctx.lineTo(70, -10); ctx.closePath(); ctx.fill();
      ctx.fillStyle = '#20202a'; ctx.fillRect(-40, -45, 60, 32);
      ctx.fillStyle = '#ffffcc'; ctx.beginPath(); ctx.arc(72, 5, 7, 0, 7); ctx.fill();
      ctx.fillStyle = 'rgba(255,255,200,0.25)'; ctx.beginPath(); ctx.moveTo(76, 5); ctx.lineTo(180, -30); ctx.lineTo(180, 40); ctx.closePath(); ctx.fill();
      for (const wx of [-50, 45]) { dot(ctx, wx, 38, 14, '#222'); dot(ctx, wx, 38, 5, '#aaa'); }
      ctx.fillStyle = GOLD; ctx.font = 'bold 13px Arial Black, sans-serif'; ctx.textAlign = 'center'; ctx.fillText('HORN OK PLEASE', 0, 26);
      for (let i = 0; i < 4; i++) { ctx.fillStyle = 'rgba(200,200,200,0.4)'; ctx.beginPath(); ctx.arc(-90 - i * 18 - (frame % 6) * 2, 30 - i * 3, 8 + i * 3, 0, 7); ctx.fill(); }
      break;
    }
    case 'chappal': ctx.rotate(p.spin || 0); ctx.fillStyle = '#7a4b2a'; ctx.beginPath(); ctx.ellipse(0, 0, 26, 11, 0, 0, 7); ctx.fill(); ctx.strokeStyle = '#2a7bd2'; ctx.lineWidth = 4; ctx.beginPath(); ctx.moveTo(-6, -9); ctx.lineTo(4, 0); ctx.lineTo(-6, 9); ctx.stroke(); break;
    case 'reticle': {
      const k = p.age < 38 ? 1 + Math.sin(frame * 0.5) * 0.1 : 1 - (p.age - 38) / 30;
      const col = p.age > 44 ? '#ff2a2a' : GOLD;
      ctx.strokeStyle = col; ctx.lineWidth = 3; ctx.shadowColor = col; ctx.shadowBlur = 12;
      ctx.beginPath(); ctx.arc(0, 0, 30 * k, 0, 7); ctx.moveTo(-44 * k, 0); ctx.lineTo(-14 * k, 0); ctx.moveTo(14 * k, 0); ctx.lineTo(44 * k, 0); ctx.moveTo(0, -44 * k); ctx.lineTo(0, -14 * k); ctx.moveTo(0, 14 * k); ctx.lineTo(0, 44 * k); ctx.stroke();
      ctx.fillStyle = col; ctx.beginPath(); ctx.arc(0, 0, 3, 0, 7); ctx.fill();
      break;
    }
    case 'jelly': {
      const wob = Math.sin(frame * 0.3) * 4;
      ctx.fillStyle = 'rgba(127,230,255,0.55)'; roundRect(ctx, -p.w / 2 - wob / 2, -p.h / 2, p.w + wob, p.h, 14); ctx.fill();
      ctx.strokeStyle = '#dff8ff'; ctx.lineWidth = 3; ctx.stroke();
      ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.fillRect(-p.w / 2 + 6, -p.h / 2 + 10, 6, p.h - 30);
      break;
    }
    case 'pan': ctx.rotate(frame * 0.6); dot(ctx, 0, 0, 17, '#3a3a3a'); ctx.fillStyle = '#555'; ctx.beginPath(); ctx.arc(-4, -4, 9, 0, 7); ctx.fill(); ctx.fillStyle = '#2a2a2a'; ctx.fillRect(14, -4, 22, 8); break;
    case 'like': {
      ctx.fillStyle = '#ff3b6b'; roundRect(ctx, -22, -22, 44, 44, 10); ctx.fill(); ctx.strokeStyle = INK; ctx.lineWidth = 3; ctx.stroke();
      ctx.fillStyle = '#fff'; ctx.fillRect(-12, -2, 7, 14); roundRect(ctx, -3, -4, 16, 16, 3); ctx.fill(); ctx.beginPath(); ctx.moveTo(-3, -4); ctx.lineTo(2, -16); ctx.lineTo(7, -14); ctx.lineTo(6, -4); ctx.fill();
      break;
    }
    case 'ringlight': {
      const a = p.life / 40; ctx.strokeStyle = `rgba(255,255,255,${a})`; ctx.lineWidth = 12; ctx.shadowColor = '#fff'; ctx.shadowBlur = 40; ctx.beginPath(); ctx.arc(0, 0, 40, 0, 7); ctx.stroke();
      break;
    }
    case 'scream': {
      ctx.scale(d, 1);
      for (let i = 0; i < 4; i++) { ctx.strokeStyle = `rgba(255,${90 + i * 40},31,${0.9 - i * 0.2})`; ctx.lineWidth = 8 - i; ctx.beginPath(); ctx.arc(-40 - i * 18, 0, p.h / 2 - i * 10, -0.9, 0.9); ctx.stroke(); }
      ctx.fillStyle = '#fff'; ctx.font = 'bold 30px Impact, Arial Black, sans-serif'; ctx.textAlign = 'center'; ctx.fillText('AAAA!', 0, 10);
      break;
    }
    case 'lol': case 'roastwave': {
      const isLol = p.type === 'lol';
      ctx.fillStyle = isLol ? GOLD : '#ff5a1f'; roundRect(ctx, -38, -24, 76, 44, 18); ctx.fill(); ctx.strokeStyle = INK; ctx.lineWidth = 3; ctx.stroke();
      ctx.beginPath(); ctx.moveTo(-20 * d, 18); ctx.lineTo(-30 * d, 32); ctx.lineTo(-6 * d, 19); ctx.fill();
      ctx.fillStyle = INK; ctx.font = `bold ${isLol ? 26 : 19}px Impact, Arial Black, sans-serif`; ctx.textAlign = 'center'; ctx.fillText(isLol ? 'LOL' : 'ROAST', 0, 8);
      break;
    }
  }
  ctx.restore();
}
function roundRect(ctx, x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }

// ---------------- events ----------------
function drawCow(ctx, e, frame) {
  const x = cowX(e), y = FLOOR_Y, d = e.dir;
  ctx.save(); ctx.translate(x, y); ctx.scale(d, 1);
  const step = Math.sin(frame * 0.3) * 8;
  for (const [lx, ph] of [[-36, 1], [-22, -1], [22, 1], [36, -1]]) seg(ctx, [[lx, -40], [lx + step * ph * 0.5, 0]], 8, '#f2f2f2');
  ctx.fillStyle = INK; roundRect(ctx, -52, -88, 104, 54, 22); ctx.fill(); ctx.fillStyle = '#f7f4ee'; roundRect(ctx, -49, -85, 98, 48, 20); ctx.fill();
  ctx.fillStyle = '#222'; ctx.beginPath(); ctx.ellipse(-18, -66, 14, 10, 0.3, 0, 7); ctx.ellipse(22, -58, 10, 8, 0, 0, 7); ctx.fill();
  dot(ctx, 62, -84, 20, '#f7f4ee'); ctx.fillStyle = '#f0b0b0'; ctx.beginPath(); ctx.ellipse(74, -76, 10, 7, 0, 0, 7); ctx.fill();
  ctx.fillStyle = INK; ctx.beginPath(); ctx.arc(64, -90, 2.5, 0, 7); ctx.fill();
  ctx.strokeStyle = '#d9c38a'; ctx.lineWidth = 4; ctx.beginPath(); ctx.moveTo(52, -100); ctx.lineTo(44, -114); ctx.moveTo(66, -102); ctx.lineTo(72, -116); ctx.stroke();
  ctx.strokeStyle = '#222'; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(-50, -80); ctx.quadraticCurveTo(-66, -60 + step, -60, -40); ctx.stroke();
  ctx.fillStyle = '#e3b65a'; ctx.beginPath(); ctx.arc(52, -68, 5, 0, 7); ctx.fill();
  ctx.restore();
  if (e.t % 90 < 40) { ctx.fillStyle = '#fff'; ctx.font = 'bold 22px Impact, sans-serif'; ctx.textAlign = 'center'; ctx.fillText('MOOO!', x + d * 60, y - 140); }
}

// ---------------- HUD ----------------
function hpColor(p) { return p > 0.5 ? '#3ddc84' : p > 0.25 ? '#f2d43c' : '#ff3b3b'; }
function drawHUD(ctx, game, frame, labels) {
  const [a, b] = game.f;
  for (const f of [a, b]) {
    const left = f.side === 0, x0 = left ? 24 : W - 24, wBar = 360, y = 26;
    const pct = f.hp / f.maxHp, tpct = f.trailHp / f.maxHp;
    ctx.save();
    // frame (slanted)
    const bar = (len, color, yy, hh) => { ctx.fillStyle = color; ctx.beginPath(); if (left) { ctx.moveTo(x0 + 10, yy); ctx.lineTo(x0 + 10 + len, yy); ctx.lineTo(x0 + len, yy + hh); ctx.lineTo(x0, yy + hh); } else { ctx.moveTo(x0 - 10, yy); ctx.lineTo(x0 - 10 - len, yy); ctx.lineTo(x0 - len, yy + hh); ctx.lineTo(x0, yy + hh); } ctx.closePath(); ctx.fill(); };
    bar(wBar + 6, GOLD, y - 3, 28); bar(wBar, '#160f08', y, 22);
    bar(wBar * tpct, '#b3261e', y, 22); bar(wBar * pct, hpColor(pct), y, 22);
    bar(wBar * pct, 'rgba(255,255,255,0.25)', y, 7);
    ctx.fillStyle = '#fff'; ctx.font = 'bold 17px Impact, Arial Black, sans-serif'; ctx.textAlign = left ? 'left' : 'right';
    ctx.strokeStyle = INK; ctx.lineWidth = 4; ctx.strokeText(f.char.name, left ? x0 + 6 : x0 - 6, y + 46); ctx.fillText(f.char.name, left ? x0 + 6 : x0 - 6, y + 46);
    ctx.fillStyle = GOLD; ctx.font = 'bold 12px Arial, sans-serif'; ctx.fillText(labels[f.side], left ? x0 + 6 : x0 - 6, y + 62);
    // round stars
    for (let i = 0; i < 2; i++) { ctx.fillStyle = game.wins[f.side] > i ? GOLD : '#333'; star(ctx, left ? x0 + wBar - 20 - i * 24 : x0 - wBar + 20 + i * 24, y + 42, 9); }
    // JUGAAD meter (bottom)
    const my = H - 34, mw = 220, mx = left ? 24 : W - 24 - mw;
    ctx.fillStyle = '#000000aa'; ctx.fillRect(mx - 4, my - 18, mw + 8, 38);
    ctx.fillStyle = f.meter >= 100 ? (frame % 20 < 10 ? '#fff' : GOLD) : GOLD; ctx.font = 'bold 12px Arial Black, sans-serif'; ctx.textAlign = left ? 'left' : 'right';
    ctx.fillText(f.meter >= 100 ? 'JUGAAD READY!' : 'JUGAAD', left ? mx : mx + mw, my - 4);
    for (let i = 0; i < 4; i++) {
      const sx = left ? mx + i * (mw / 4) : mx + mw - (i + 1) * (mw / 4), fill = Math.max(0, Math.min(1, f.meter / 25 - i));
      ctx.fillStyle = '#2a2216'; ctx.fillRect(sx + 2, my + 2, mw / 4 - 4, 12);
      ctx.fillStyle = f.meter >= 100 ? `hsl(${(frame * 6 + i * 40) % 360},90%,60%)` : GOLD;
      if (left) ctx.fillRect(sx + 2, my + 2, (mw / 4 - 4) * fill, 12); else ctx.fillRect(sx + 2 + (mw / 4 - 4) * (1 - fill), my + 2, (mw / 4 - 4) * fill, 12);
    }
    ctx.restore();
  }
  // timer hexagon
  const t = Math.ceil(game.timer / 60);
  ctx.save(); ctx.translate(W / 2, 46);
  ctx.fillStyle = INK; ctx.strokeStyle = GOLD; ctx.lineWidth = 3; ctx.beginPath();
  for (let i = 0; i < 6; i++) { const ang = Math.PI / 6 + (i * Math.PI) / 3; ctx.lineTo(Math.cos(ang) * 38, Math.sin(ang) * 38); } ctx.closePath(); ctx.fill(); ctx.stroke();
  ctx.fillStyle = t <= 10 && frame % 30 < 15 ? '#ff3b3b' : '#fff'; ctx.font = 'bold 36px Impact, Arial Black, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(String(t), 0, 2);
  ctx.restore();
  ctx.fillStyle = '#ffffff99'; ctx.font = 'bold 11px Arial, sans-serif'; ctx.textAlign = 'center'; ctx.fillText('ROUND ' + game.round, W / 2, 98);
}

function bigText(ctx, text, x, y, size, color, rot = 0, stroke = 8) {
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot);
  ctx.font = `bold ${size}px Impact, "Arial Black", sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.lineJoin = 'round'; ctx.strokeStyle = INK; ctx.lineWidth = stroke; ctx.strokeText(text, 0, 0); ctx.fillStyle = color; ctx.fillText(text, 0, 0);
  ctx.restore();
}

// ---------------- main draw ----------------
export function render(ctx, game, frame, opts = {}) {
  ctx.save();
  const sh = game.shakeAmt || 0;
  if (sh) ctx.translate((Math.random() - 0.5) * sh * 2, (Math.random() - 0.5) * sh * 2);
  if (game.bruhT > 0 && 'filter' in ctx) ctx.filter = 'grayscale(1) contrast(1.2)';
  drawStage(ctx, game, frame);
  const ev = game.event;
  if (ev && ev.type === 'kite') {
    const x = ev.dir === 1 ? -60 + ev.t * 3.4 : W + 60 - ev.t * 3.4, y = 80 + ev.t * 0.9 + Math.sin(ev.t * 0.15) * 30;
    ctx.save(); ctx.translate(x, y); ctx.rotate(ev.t * 0.08); ctx.fillStyle = '#ff3b6b'; ctx.beginPath(); ctx.moveTo(0, -22); ctx.lineTo(16, 0); ctx.lineTo(0, 24); ctx.lineTo(-16, 0); ctx.closePath(); ctx.fill(); ctx.restore();
  }
  // super freeze: darken the world behind the fighters
  if (game.freeze > 0) {
    ctx.fillStyle = 'rgba(0,0,0,0.6)'; ctx.fillRect(-20, -20, W + 40, H + 40);
    const f = game.freezeBy; ctx.save(); ctx.translate(f.x, FLOOR_Y - 80); ctx.strokeStyle = (f.char.superColor || GOLD) + '66'; ctx.lineWidth = 3;
    for (let i = 0; i < 24; i++) { const a = (i / 24) * Math.PI * 2 + frame * 0.05; ctx.beginPath(); ctx.moveTo(Math.cos(a) * 60, Math.sin(a) * 60); ctx.lineTo(Math.cos(a) * 600, Math.sin(a) * 600); ctx.stroke(); } ctx.restore();
  }
  const order = [...game.f].sort((p, q) => (p.attack || p.state === 'super' ? 1 : 0) - (q.attack || q.state === 'super' ? 1 : 0));
  for (const f of order) drawFighter(ctx, f, frame, { bigHead: game.meme });
  for (const p of game.projectiles) drawProjectile(ctx, p, frame);
  if (ev && ev.type === 'cow') drawCow(ctx, ev, frame);
  // particles
  for (const p of game.fx.parts) {
    const a = Math.max(0, p.life / p.max); ctx.globalAlpha = p.soft ? a * 0.5 : Math.min(1, a * 1.5);
    ctx.fillStyle = p.color;
    if (p.confetti) { ctx.save(); ctx.translate(p.x, FLOOR_Y + p.y); ctx.rotate(p.rot); ctx.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2); ctx.restore(); }
    else { ctx.beginPath(); ctx.arc(p.x, FLOOR_Y + p.y, p.size * (p.soft ? 1 + (1 - a) : a), 0, 7); ctx.fill(); }
  }
  ctx.globalAlpha = 1;
  for (const r of game.fx.rings) { ctx.strokeStyle = r.color; ctx.globalAlpha = r.life / 14; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(r.x, FLOOR_Y + r.y, r.r, 0, 7); ctx.stroke(); }
  ctx.globalAlpha = 1;
  for (const t of game.fx.texts) {
    ctx.globalAlpha = Math.min(1, t.life / 15);
    if (t.box) { ctx.fillStyle = t.box; ctx.fillRect(t.x - 70, FLOOR_Y + t.y - 22, 140, 40); }
    bigText(ctx, t.text, t.x, FLOOR_Y + t.y, t.size, t.color, 0, 6);
  }
  ctx.globalAlpha = 1;
  // weather & power cut
  if (ev && ev.type === 'rain') {
    const k = Math.min(1, ev.t / 60, (ev.len - ev.t) / 60);
    ctx.fillStyle = `rgba(10,20,40,${0.3 * k})`; ctx.fillRect(-20, -20, W + 40, H + 40);
    ctx.strokeStyle = `rgba(180,200,255,${0.5 * k})`; ctx.lineWidth = 1.5; ctx.beginPath();
    for (let i = 0; i < 140; i++) { const x = (i * 73 + frame * 9) % (W + 100) - 50, y = (i * 131 + frame * 22) % (H + 40) - 20; ctx.moveTo(x, y); ctx.lineTo(x - 6, y + 16); }
    ctx.stroke();
    if (ev.t % 200 < 4) { ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.fillRect(0, 0, W, H); }
  }
  if (ev && ev.type === 'powercut') {
    const k = Math.min(1, ev.t / 10, (ev.len - ev.t) / 10), flick = (ev.t % 47 < 3) ? 0.4 : 1;
    ctx.fillStyle = `rgba(0,0,5,${0.86 * k * flick})`; ctx.fillRect(-20, -20, W + 40, H + 40);
    for (const f of game.f) { const hy = FLOOR_Y + f.y - 135 * f.char.scale; ctx.fillStyle = '#fff'; ctx.shadowColor = '#fff'; ctx.shadowBlur = 8; ctx.beginPath(); ctx.arc(f.x + 7 * f.facing, hy, 2.5, 0, 7); ctx.fill(); ctx.shadowBlur = 0; }
    const g = ctx.createRadialGradient(game.f[0].x, FLOOR_Y - 60, 10, game.f[0].x, FLOOR_Y - 60, 150); g.addColorStop(0, `rgba(255,240,200,${0.18 * k})`); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  }
  if (ev && ev.type === 'lag') {
    for (let i = 0; i < 6; i++) { const y = (frame * 37 + i * 97) % H; ctx.fillStyle = i % 2 ? 'rgba(255,0,80,0.12)' : 'rgba(0,220,255,0.12)'; ctx.fillRect(0, y, W, 6 + (i * 5) % 18); }
    bigText(ctx, 'PING: 999ms', W / 2, 130, 26, '#ff3b3b', 0, 6);
  }
  if (ev && ev.type === 'moon') { ctx.fillStyle = 'rgba(60,40,140,0.18)'; ctx.fillRect(-20, -20, W + 40, H + 40); bigText(ctx, 'LOW GRAVITY 🌙', W / 2, 130, 24, '#c9b8ff', 0, 6); }
  if (game.flashT > 0) { ctx.fillStyle = game.flashColor; ctx.globalAlpha = Math.min(0.85, game.flashT / 24); ctx.fillRect(-20, -20, W + 40, H + 40); ctx.globalAlpha = 1; }
  ctx.filter = 'none';
  ctx.restore();

  drawHUD(ctx, game, frame, opts.labels || ['1P', 'CPU']);
  // side callouts (combos, move names)
  const bySide = [[], []];
  for (const c of game.callouts) if (c.text) bySide[c.side].push(c);
  for (const side of [0, 1]) bySide[side].slice(-3).forEach((c, i, arr) => {
    const k = c.life / c.max, pop = Math.min(1, (c.max - c.life) / 6);
    ctx.globalAlpha = Math.min(1, k * 3);
    if (c.big) bigText(ctx, c.text, W / 2, 180, 50 * (0.6 + 0.4 * pop), c.color, -0.05, 10);
    else bigText(ctx, c.text, side === 0 ? 210 : W - 210, 150 + (arr.length - 1 - i) * 36, 26 * (0.7 + 0.3 * pop), c.color, side === 0 ? -0.06 : 0.06, 6);
    ctx.globalAlpha = 1;
  });
  if (game.bannerData) {
    const bd = game.bannerData, k = (bd.max - bd.life) / 8;
    ctx.fillStyle = 'rgba(0,0,0,0.55)'; ctx.fillRect(0, H / 2 - 62, W, bd.sub ? 132 : 104);
    ctx.fillStyle = GOLD; ctx.fillRect(0, H / 2 - 62, W, 3); ctx.fillRect(0, H / 2 + (bd.sub ? 67 : 39), W, 3);
    bigText(ctx, bd.text, W / 2, H / 2 - 12, 74 * Math.min(1, 0.5 + k), bd.color, 0, 10);
    if (bd.sub) bigText(ctx, bd.sub, W / 2, H / 2 + 44, 28, '#fff', 0, 6);
  }
  if (game.bruhT > 0) { bigText(ctx, 'BRUH.', W / 2, H / 2, 110, '#ffffff', -0.08, 12); bigText(ctx, 'super miss ho gaya', W / 2, H / 2 + 70, 26, GOLD, -0.08, 6); }
  if (game.freeze > 0) {
    const f = game.freezeBy; ctx.save(); ctx.globalAlpha = 0.95; ctx.fillStyle = f.char.superColor || GOLD;
    ctx.beginPath(); ctx.moveTo(0, 360); ctx.lineTo(W, 300); ctx.lineTo(W, 360); ctx.lineTo(0, 420); ctx.closePath(); ctx.fill(); ctx.restore();
    bigText(ctx, f.char.superName + '!', W / 2, 360, 46, '#fff', -0.06, 10);
  }
}

// Small portrait for the select screen (draws the fighter idle on its own canvas)
export function drawPortrait(canvas, char, frame = 0) {
  const ctx = canvas.getContext('2d'); const k = canvas.width / 160;
  ctx.setTransform(k, 0, 0, k, 0, 0); ctx.clearRect(0, 0, 160, 200);
  const fake = { char, x: 80, y: 0, facing: 1, side: 0, state: 'idle', t: 0, attack: null, holdingBack: false, walkCycle: 0, flash: 0, isLow: false, airborne: false, stun: 0, superT: 0, throwT: 0 };
  ctx.save(); ctx.translate(0, -FLOOR_Y + 185); drawFighter(ctx, fake, frame); ctx.restore();
}
