// Balfysica van een tennisbal. Puur rekenwerk zonder three-import, zodat Node het kan testen.
// Assen: y omhoog, grond op y = 0. Eenheden: m, s, kg, rad/s.

export const R = 0.0335; // straal (diameter 6,7 cm)
export const M = 0.058; // massa
export const G = 9.81;
export const WATER_Y = -0.06; // wateroppervlak van de vijver
export const BED_Y = -0.6; // vijverbodem

const RHO = 1.2; // lucht
const RHO_W = 1000;
const CD = 0.55;
const AREA = Math.PI * R * R;
const VOL = (4 / 3) * Math.PI * R ** 3;
const INERTIA = 1.5 / R; // r·m/I voor een holle bol (I = ⅔mr²), per massa-eenheid
const V_ROL = 0.25; // onder deze inslagsnelheid rolt de bal in plaats van te stuiten

// e = restitutie, mu = glijwrijving, rol = rolweerstand, graaf = deel van de vaart dat de bal bij inslag verliest.
// e van beton is geijkt op de valproef uit de tennisbalnorm (zie test), inclusief luchtweerstand.
export const SURFACES = {
  beton: { e: 0.78, mu: 0.6, rol: 0.02, graaf: 0 },
  gras: { e: 0.5, mu: 0.5, rol: 0.12, graaf: 0.08 },
  modder: { e: 0.25, mu: 0.45, rol: 0.3, graaf: 0.35 },
  zand: { e: 0.15, mu: 0.7, rol: 0.5, graaf: 0.6 },
  sneeuw: { e: 0.1, mu: 0.25, rol: 0.45, graaf: 0.7 },
  water: { e: 0.1, mu: 0.5, rol: 0.5, graaf: 0.5 }, // de vijverbodem
};

const HOUT = { e: 0.5, mu: 0.6 }; // boomstam

const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const lerp = (a, b, t) => a + (b - a) * t;

// Regen (nat 0..1) maakt de bal glad en verandert gras in modder.
export function surfaceProps(name, nat = 0) {
  const s = SURFACES[name] || SURFACES.gras;
  const m = SURFACES.modder;
  const k = name === 'gras' ? nat : 0;
  return {
    e: lerp(s.e, m.e, k),
    mu: lerp(s.mu, m.mu, k) * (1 - 0.4 * nat),
    rol: lerp(s.rol, m.rol, k),
    graaf: lerp(s.graaf, m.graaf, k),
  };
}

// Wrijvingsimpuls in het contactpunt met normaal n en normaalimpuls jn (per massa-eenheid):
// remt het glijden af en zet het om in spin. 0,4·u maakt van glijden zuiver rollen (holle bol).
function grip(v, w, nx, ny, nz, jn, mu) {
  // snelheid van het contactpunt, v + ω × (−R·n), zonder het deel langs de normaal
  let ux = v.x - R * (w.y * nz - w.z * ny), uy = v.y - R * (w.z * nx - w.x * nz), uz = v.z - R * (w.x * ny - w.y * nx);
  const un = ux * nx + uy * ny + uz * nz;
  ux -= un * nx; uy -= un * ny; uz -= un * nz;
  const u = Math.hypot(ux, uy, uz);
  if (u < 1e-9) return;
  const k = -Math.min(0.4 * u, mu * jn) / u;
  const jx = k * ux, jy = k * uy, jz = k * uz;
  v.x += jx; v.y += jy; v.z += jz;
  w.x -= INERTIA * (ny * jz - nz * jy); w.y -= INERTIA * (nz * jx - nx * jz); w.z -= INERTIA * (nx * jy - ny * jx);
}

export function newBall(p = { x: 0, y: R, z: 0 }, v = { x: 0, y: 0, z: 0 }, w = { x: 0, y: 0, z: 0 }) {
  return { p: { ...p }, v: { ...v }, w: { ...w }, rust: false, inWater: false, kalm: 0, events: [] };
}

// Deel van het balvolume dat onder water zit (bolkap).
export function submerged(ball, surf) {
  if (surf !== 'water') return 0;
  const d = clamp(WATER_Y - (ball.p.y - R), 0, 2 * R);
  return (Math.PI * d * d * (3 * R - d)) / 3 / VOL;
}

// env: { surfaceAt(x, z), nat, geenLucht, grenzen: {x0, x1, z0, z1}, obstakels: [{x, z, r, h}] }
export function step(b, dt, env = {}) {
  if (b.rust) return;
  const { p, v, w } = b;
  const at = env.surfaceAt || (() => 'gras');
  const x0 = p.x, z0 = p.z;
  const surf0 = at(x0, z0);
  const sub = submerged(b, surf0);
  const sp = Math.hypot(v.x, v.y, v.z);

  // Krachten per massa-eenheid: zwaartekracht, opwaartse kracht, Magnus.
  let ax = 0, ay = -G + (RHO_W * G * sub * VOL) / M, az = 0;
  const wm = Math.hypot(w.x, w.y, w.z);
  if (!env.geenLucht && sp > 1e-6 && wm > 1e-3) {
    const cl = 1 / (2 + sp / (R * wm));
    const k = ((0.5 * RHO * AREA * cl * sp * sp) / M / (wm * sp)) * (1 - sub);
    ax += k * (w.y * v.z - w.z * v.y);
    ay += k * (w.z * v.x - w.x * v.z);
    az += k * (w.x * v.y - w.y * v.x);
  }
  v.x += ax * dt; v.y += ay * dt; v.z += az * dt;

  // Kwadratische weerstand, impliciet zodat het ook in water stabiel blijft.
  const kd = (0.5 * CD * AREA * ((env.geenLucht ? 0 : RHO) * (1 - sub) + RHO_W * sub)) / M;
  const damp = 1 / (1 + kd * sp * dt) / (1 + 3 * sub * dt);
  v.x *= damp; v.y *= damp; v.z *= damp;
  const spinDamp = 1 / (1 + (0.05 + 8 * sub) * dt);
  w.x *= spinDamp; w.y *= spinDamp; w.z *= spinDamp;

  p.x += v.x * dt; p.y += v.y * dt; p.z += v.z * dt;

  const g = env.grenzen;
  if (g) {
    if (p.x < g.x0 || p.x > g.x1) { p.x = clamp(p.x, g.x0, g.x1); v.x *= -0.4; }
    if (p.z < g.z0 || p.z > g.z1) { p.z = clamp(p.z, g.z0, g.z1); v.z *= -0.4; }
  }

  // Staande cilinders (boomstammen): terugkaatsen met verlies, de bast neemt spin over.
  for (const o of env.obstakels || []) {
    const dx = p.x - o.x, dz = p.z - o.z, dd = Math.hypot(dx, dz), min = o.r + R;
    if (p.y - R > o.h || dd >= min || dd < 1e-9) continue;
    const nx = dx / dd, nz = dz / dd, vn = v.x * nx + v.z * nz;
    p.x = o.x + nx * min; p.z = o.z + nz * min;
    if (vn >= 0) continue;
    const jn = -(1 + HOUT.e) * vn;
    v.x += jn * nx; v.z += jn * nz;
    grip(v, w, nx, 0, nz, jn, HOUT.mu * (1 - 0.4 * (env.nat || 0)));
    b.events.push({ type: 'stuit', surf: 'hout', speed: -vn, x: p.x, z: p.z });
  }

  let surf = at(p.x, p.z);
  // De oever is een wandje: een bal die in het water ligt rolt niet het gras op.
  if (surf0 === 'water' && surf !== 'water' && p.y - R < 0) {
    p.x = x0; p.z = z0; v.x *= -0.3; v.z *= -0.3;
    surf = 'water';
  }
  const water = surf === 'water';
  if (water && !b.inWater && p.y - R < WATER_Y) {
    b.inWater = true;
    b.events.push({ type: 'plons', surf, speed: sp, x: p.x, z: p.z });
  } else if (!water) b.inWater = false;

  const floor = water ? BED_Y : 0;
  if (p.y - R <= floor) {
    p.y = floor + R;
    const s = surfaceProps(surf, env.nat);
    if (v.y < -V_ROL) {
      const vin = -v.y;
      grip(v, w, 0, 1, 0, (1 + s.e) * vin, s.mu);
      v.y = s.e * vin;
      const keep = 1 - s.graaf;
      v.x *= keep; v.z *= keep; w.x *= keep; w.z *= keep; w.y *= 0.8 * keep;
      b.events.push({ type: 'stuit', surf, speed: vin, x: p.x, z: p.z });
    } else {
      if (v.y < 0) v.y = 0;
      grip(v, w, 0, 1, 0, G * dt, s.mu);
      const vh = Math.hypot(v.x, v.z);
      const dec = s.rol * G * dt;
      if (vh <= dec + 0.02) {
        v.x = v.y = v.z = w.x = w.y = w.z = 0;
        b.rust = true;
      } else {
        const k = (vh - dec) / vh;
        v.x *= k; v.z *= k; w.x *= k; w.z *= k;
        w.y /= 1 + 5 * dt;
      }
    }
  }

  // Drijvend uitgedobberd.
  b.kalm = sub > 0 && sp < 0.05 ? b.kalm + dt : 0;
  if (b.kalm > 0.4) { v.x = v.y = v.z = w.x = w.y = w.z = 0; b.rust = true; }
}

// Waar raakt de bal voor het eerst de grond of het water? Voor de hond en de score.
export function predictLanding(ball, env, maxT = 8) {
  const b = newBall(ball.p, ball.v, ball.w);
  b.inWater = ball.inWater;
  const dt = 1 / 120;
  for (let t = 0; t < maxT; t += dt) {
    step(b, dt, env);
    if (b.events.some((e) => e.surf !== 'hout') || b.rust) return { x: b.p.x, z: b.p.z, t }; // een stam is geen landing
  }
  return { x: b.p.x, z: b.p.z, t: maxT };
}
