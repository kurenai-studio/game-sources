// Frame data for every move (60 frames = 1 second).
// s = startup, a = active, r = recovery, dmg = damage, h = height (high | mid | low | air)
// reach = how far in front of the body (px) the hit lands, hs/bs = hitstun/blockstun frames
// push = pushback (px/frame), kd = knockdown, launch = velocity given on a knockdown hit
// chains = which move comes next if you press P or K while this one connects (combos)
export const MOVES = {
  jab:   { id: 'jab',   s: 4,  a: 3,  r: 9,  dmg: 5,  h: 'high', reach: 62, hs: 15, bs: 9,  push: 3, lunge: 1.5, chains: { p: 'jab2', k: 'kick' } },
  jab2:  { id: 'jab2',  s: 5,  a: 3,  r: 11, dmg: 6,  h: 'high', reach: 66, hs: 17, bs: 10, push: 3.5, lunge: 3, chains: { p: 'upper', k: 'spin' } },
  upper: { id: 'upper', s: 8,  a: 4,  r: 20, dmg: 10, h: 'mid',  reach: 58, hs: 24, bs: 14, push: 3, lunge: 4, kd: true, launch: { vx: 2.5, vy: -13 }, antiAir: true },
  spin:  { id: 'spin',  s: 9,  a: 4,  r: 20, dmg: 11, h: 'mid',  reach: 84, hs: 24, bs: 14, push: 8, lunge: 4, kd: true, launch: { vx: 7, vy: -7 } },
  kick:  { id: 'kick',  s: 8,  a: 4,  r: 14, dmg: 8,  h: 'mid',  reach: 86, hs: 20, bs: 12, push: 4.5, lunge: 1.5, chains: { k: 'round' } },
  round: { id: 'round', s: 10, a: 5,  r: 20, dmg: 12, h: 'high', reach: 92, hs: 24, bs: 15, push: 9, lunge: 3.5, kd: true, launch: { vx: 8, vy: -6 } },
  lowp:  { id: 'lowp',  s: 5,  a: 3,  r: 10, dmg: 4,  h: 'low',  reach: 60, hs: 16, bs: 8,  push: 3, crouch: true, chains: { p: 'upper', k: 'sweep' } },
  sweep: { id: 'sweep', s: 10, a: 4,  r: 20, dmg: 8,  h: 'low',  reach: 92, hs: 22, bs: 13, push: 5, lunge: 2.5, crouch: true, kd: true, launch: { vx: 2, vy: -4 } },
  rush:  { id: 'rush',  s: 12, a: 5,  r: 18, dmg: 12, h: 'mid',  reach: 70, hs: 24, bs: 15, push: 8, lunge: 9, kd: true, launch: { vx: 6, vy: -9 }, special: true },
  fly:   { id: 'fly',   s: 14, a: 6,  r: 18, dmg: 13, h: 'mid',  reach: 82, hs: 24, bs: 16, push: 9, lunge: 7, kd: true, launch: { vx: 8, vy: -8 }, special: true },
  airp:  { id: 'airp',  s: 4,  a: 12, r: 0,  dmg: 7,  h: 'air',  reach: 60, hs: 16, bs: 10, push: 5, air: true },
  airk:  { id: 'airk',  s: 6,  a: 12, r: 0,  dmg: 9,  h: 'air',  reach: 80, hs: 18, bs: 11, push: 6, air: true },
  // character-specific specials (replace rush/fly for some fighters)
  emote: { id: 'emote', s: 14, a: 1,  r: 20, dmg: 0,  h: 'mid',  reach: 0,  hs: 0,  bs: 0,  push: 0, special: true, spawn: 'lol' },
  roast: { id: 'roast', s: 12, a: 1,  r: 20, dmg: 0,  h: 'mid',  reach: 0,  hs: 0,  bs: 0,  push: 0, special: true, spawn: 'roastwave' },
  beep:  { id: 'beep',  s: 11, a: 6,  r: 20, dmg: 11, h: 'mid',  reach: 112, hs: 24, bs: 16, push: 10, kd: true, launch: { vx: 9, vy: -7 }, special: true, fx: 'beep' },
  grab:  { id: 'grab',  s: 5,  a: 3,  r: 22, dmg: 0,  h: 'grab', reach: 56, hs: 0,  bs: 0,  push: 0, grab: true },
};

export const THROW = { breakWindow: 10, length: 30, dmg: 12 };
export const SUPER = { freeze: 32, recover: 26, dmg: 22, chip: 6, speed: 10 };

export const totalFrames = (m) => m.s + m.a + m.r;

// Which move a button starts, from the stick direction (forward / down / neutral).
export function pickMove(button, { down = false, forward = false, air = false } = {}) {
  if (button === 'g') return 'grab';
  if (air) return button === 'p' ? 'airp' : 'airk';
  if (down) return button === 'p' ? 'lowp' : 'sweep';
  if (forward) return button === 'p' ? 'rush' : 'fly';
  return button === 'p' ? 'jab' : 'kick';
}

// Combo damage scaling: every extra hit in a combo does a bit less.
export const comboScale = (hits) => Math.max(0.5, Math.pow(0.88, hits));
