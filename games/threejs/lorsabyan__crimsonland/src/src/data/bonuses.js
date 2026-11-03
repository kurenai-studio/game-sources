// Pickups dropped by the horde. `icon` paints into the sprite atlas at startup.
const TAU = Math.PI * 2;
const line = (c, pts) => { c.beginPath(); pts.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y))); c.stroke(); };
const poly = (c, pts) => { c.beginPath(); pts.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y))); c.closePath(); c.fill(); };

export const BONUSES = {
  points: {
    name: '+500', col: [1, 0.82, 0.3], weight: 26,
    icon: (c, r) => { c.beginPath(); c.arc(0, 0, r * 0.82, 0, TAU); c.stroke(); poly(c, [[0, -r * 0.5], [r * 0.14, -r * 0.14], [r * 0.5, 0], [r * 0.14, r * 0.14], [0, r * 0.5], [-r * 0.14, r * 0.14], [-r * 0.5, 0], [-r * 0.14, -r * 0.14]]); },
    apply: (g) => g.addScore(500),
  },
  medkit: {
    name: 'Medkit', col: [1, 0.25, 0.28], weight: 14,
    icon: (c, r) => { c.fillRect(-r * 0.26, -r * 0.8, r * 0.52, r * 1.6); c.fillRect(-r * 0.8, -r * 0.26, r * 1.6, r * 0.52); },
    apply: (g) => g.player.heal(30),
  },
  weapon: {
    name: 'Weapon', col: [0.7, 0.95, 1], weight: 22,
    icon: (c, r) => { c.fillRect(-r * 0.9, -r * 0.3, r * 1.8, r * 0.38); c.fillRect(-r * 0.86, -r * 0.1, r * 0.5, r * 0.8); c.fillRect(r * 0.1, -r * 0.5, r * 0.9, r * 0.22); },
    apply: (g, d) => g.player.giveWeapon(d.weapon),
  },
  nuke: {
    name: 'Nuke', col: [1, 0.5, 0.15], weight: 4,
    icon: (c, r) => {
      c.beginPath(); c.arc(0, 0, r * 0.2, 0, TAU); c.fill();
      for (let i = 0; i < 3; i++) { const a = i * TAU / 3 - Math.PI / 2; c.beginPath(); c.moveTo(0, 0); c.arc(0, 0, r * 0.9, a - 0.5, a + 0.5); c.closePath(); c.fill(); }
    },
    apply: (g, d) => g.nuke(d.x, d.z),
  },
  freeze: {
    name: 'Freeze', col: [0.5, 0.85, 1], weight: 7,
    icon: (c, r) => { for (let i = 0; i < 3; i++) { const a = i * Math.PI / 3, x = Math.cos(a) * r * 0.9, y = Math.sin(a) * r * 0.9; line(c, [[-x, -y], [x, y]]); for (const s of [-1, 1]) { const m = 0.6, nx = -y * 0.26, ny = x * 0.26; line(c, [[s * x * m + nx, s * y * m + ny], [s * x * 0.86, s * y * 0.86], [s * x * m - nx, s * y * m - ny]]); } } },
    apply: (g) => g.freezeAll(5.5),
  },
  firering: {
    name: 'Fire Ring', col: [1, 0.45, 0.15], weight: 9,
    icon: (c, r) => { c.beginPath(); c.arc(0, 0, r * 0.32, 0, TAU); c.fill(); for (let i = 0; i < 8; i++) { const a = i * TAU / 8; line(c, [[Math.cos(a) * r * 0.55, Math.sin(a) * r * 0.55], [Math.cos(a) * r * 0.95, Math.sin(a) * r * 0.95]]); } },
    apply: (g, d) => g.shots.ring(d.x, d.z, 28, 'plasma', 42),
  },
  shock: {
    name: 'Shock Chain', col: [0.7, 0.75, 1], weight: 8,
    icon: (c, r) => poly(c, [[r * 0.2, -r * 0.95], [-r * 0.5, r * 0.15], [-r * 0.06, r * 0.15], [-r * 0.26, r * 0.95], [r * 0.54, -r * 0.2], [r * 0.08, -r * 0.2]]),
    apply: (g, d) => g.shots.shockChain(d.x, d.z, 14, 180),
  },
  reflex: {
    name: 'Reflex Boost', col: [0.95, 0.9, 0.5], weight: 9, timer: 'reflex', time: 7,
    icon: (c, r) => { line(c, [[-r * 0.6, -r * 0.85], [r * 0.6, -r * 0.85], [-r * 0.6, r * 0.85], [r * 0.6, r * 0.85], [-r * 0.6, -r * 0.85]]); },
  },
  shield: {
    name: 'Shield', col: [0.45, 0.8, 1], weight: 8, timer: 'shield', time: 8,
    icon: (c, r) => { c.beginPath(); c.moveTo(0, -r * 0.92); c.lineTo(r * 0.76, -r * 0.6); c.lineTo(r * 0.7, r * 0.2); c.quadraticCurveTo(r * 0.5, r * 0.7, 0, r * 0.95); c.quadraticCurveTo(-r * 0.5, r * 0.7, -r * 0.7, r * 0.2); c.lineTo(-r * 0.76, -r * 0.6); c.closePath(); c.fill(); },
  },
  speed: {
    name: 'Speed', col: [0.5, 1, 0.55], weight: 8, timer: 'speed', time: 9,
    icon: (c, r) => { for (const o of [-0.5, 0.2]) line(c, [[r * o, -r * 0.7], [r * (o + 0.62), 0], [r * o, r * 0.7]]); },
  },
  fireammo: {
    name: 'Fire Rounds', col: [1, 0.35, 0.1], weight: 8, timer: 'fire', time: 7,
    icon: (c, r) => { c.beginPath(); c.moveTo(0, -r * 0.95); c.bezierCurveTo(r * 0.3, -r * 0.4, r * 0.82, -r * 0.1, r * 0.62, r * 0.42); c.bezierCurveTo(r * 0.5, r * 0.9, -r * 0.5, r * 0.95, -r * 0.62, r * 0.42); c.bezierCurveTo(-r * 0.76, 0, -r * 0.2, -r * 0.2, 0, -r * 0.95); c.fill(); },
  },
  xp2: {
    name: 'Double XP', col: [1, 0.72, 1], weight: 7, timer: 'xp2', time: 10,
    icon: (c, r) => { c.font = `${Math.round(r * 1.75)}px Teko, Impact, sans-serif`; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText('2X', 0, r * 0.12); },
  },
  overdrive: {
    name: 'Overdrive', col: [1, 0.95, 0.5], weight: 8, timer: 'overdrive', time: 8,
    icon: (c, r) => { for (const y of [-0.05, 0.55]) line(c, [[-r * 0.72, r * (y + 0.3)], [0, r * (y - 0.4)], [r * 0.72, r * (y + 0.3)]]); },
  },
};

for (const [id, b] of Object.entries(BONUSES)) b.id = id;
export const BONUS_LIST = Object.values(BONUSES);
BONUS_LIST.forEach((b, i) => { b.index = i; });
