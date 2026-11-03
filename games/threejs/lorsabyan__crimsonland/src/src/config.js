// Global constants, URL flags and quality tiers.
const params = new URLSearchParams(location.search);

export const TITLE = 'Crimsonland';
export const REPO = 'https://github.com/lorsabyan/crimsonland';
export const ARENA = 32;                 // half-size of the playable square, world units
export const OUTER = ARENA + 18;         // half-size of the ground mesh
export const CAM = { fov: 32, pitch: 66 * Math.PI / 180, dist: 30, look: 0.2, lookMax: 6, follow: 7 };

export const FLAGS = {
  debug: params.has('debug'),
  webgl: params.has('webgl'),
  autoplay: params.has('autoplay'),
  human: params.get('autoplay') === 'human',
  mode: params.get('mode'),
  biome: params.get('biome'),
  quality: params.get('quality'),
  mute: params.has('mute'),
  selftest: params.has('selftest'),
};

export const REDUCED_MOTION = matchMedia('(prefers-reduced-motion: reduce)').matches;
export const IS_TOUCH = matchMedia('(pointer: coarse)').matches;

export const TIERS = {
  high: { name: 'high', dpr: 2, msaa: true, shadow: 2048, decal: 4096, tex: 1024, lights: 4, particleScale: 1, grass: 1400, rocks: 170 },
  medium: { name: 'medium', dpr: 1.5, msaa: false, shadow: 1536, decal: 3072, tex: 1024, lights: 3, particleScale: 0.75, grass: 800, rocks: 130 },
  low: { name: 'low', dpr: 1.25, msaa: false, shadow: 0, decal: 2048, tex: 512, lights: 2, particleScale: 0.5, grass: 300, rocks: 90 },
};

export function pickTier(saved) {
  const q = FLAGS.quality || saved;
  if (TIERS[q]) return TIERS[q];
  const small = Math.min(innerWidth, innerHeight) < 500;
  if (IS_TOUCH || small) return TIERS.low;
  return (navigator.hardwareConcurrency || 8) >= 8 ? TIERS.high : TIERS.medium;
}
