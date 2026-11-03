/**
 * Quality tiers.
 *
 * Every system reads its budgets from here rather than hard-coding counts, so
 * dropping to "low" genuinely halves the work instead of only turning off a
 * post pass. Tier is auto-detected once, then user-overridable.
 */

export const TIERS = {
  low: {
    label: 'LOW',
    pixelRatio: 1.0,
    shadowMap: 1024,
    shadows: true,
    softShadows: false,
    terrainSegments: 160,
    treeCount: 900,
    grassCount: 0,
    rockCount: 320,
    houseDetail: 0,
    ashCount: 1400,
    emberCount: 500,
    dustCount: 400,
    windCount: 300,
    leafCount: 200,
    rainCount: 3000,
    smokeCount: 110,
    fireParticles: 140,
    sparkCount: 160,
    birdCount: 18,
    cloudCount: 26,
    torchLights: 5,
    envResolution: 128,
    post: { bloom: true, ssao: false, dof: false, godrays: true, grain: true, ca: true, mblur: false, aa: 'fxaa' },
  },
  medium: {
    label: 'MEDIUM',
    pixelRatio: 1.0,
    shadowMap: 2048,
    shadows: true,
    softShadows: true,
    terrainSegments: 224,
    treeCount: 1800,
    grassCount: 14000,
    rockCount: 520,
    houseDetail: 1,
    ashCount: 2600,
    emberCount: 900,
    dustCount: 900,
    windCount: 600,
    leafCount: 420,
    rainCount: 6000,
    smokeCount: 200,
    fireParticles: 220,
    sparkCount: 280,
    birdCount: 30,
    cloudCount: 38,
    torchLights: 5,
    envResolution: 256,
    post: { bloom: true, ssao: false, dof: false, godrays: true, grain: true, ca: false, mblur: false, aa: 'fxaa' },
  },
  high: {
    label: 'HIGH',
    // The default target is a steady 50–60 fps on a typical laptop, not a
    // one-off benchmark screenshot. Ultra remains available for high-end GPUs.
    pixelRatio: 1.15,
    shadowMap: 2048,
    shadows: true,
    softShadows: true,
    terrainSegments: 264,
    treeCount: 2500,
    grassCount: 18000,
    rockCount: 680,
    houseDetail: 1,
    ashCount: 2800,
    emberCount: 1150,
    dustCount: 1000,
    windCount: 700,
    leafCount: 520,
    rainCount: 6500,
    smokeCount: 280,
    fireParticles: 320,
    sparkCount: 420,
    birdCount: 44,
    cloudCount: 52,
    torchLights: 6,
    envResolution: 256,
    post: { bloom: true, ssao: false, dof: false, godrays: true, grain: true, ca: false, mblur: false, aa: 'smaa' },
  },
  ultra: {
    label: 'ULTRA',
    pixelRatio: 1.75,
    shadowMap: 4096,
    shadows: true,
    softShadows: true,
    terrainSegments: 384,
    treeCount: 4800,
    grassCount: 62000,
    rockCount: 1200,
    houseDetail: 2,
    ashCount: 6500,
    emberCount: 2400,
    dustCount: 2400,
    windCount: 1400,
    leafCount: 1100,
    rainCount: 14000,
    smokeCount: 420,
    fireParticles: 440,
    sparkCount: 620,
    birdCount: 60,
    cloudCount: 68,
    torchLights: 18,
    envResolution: 512,
    post: { bloom: true, ssao: true, dof: false, godrays: true, grain: true, ca: true, mblur: false, aa: 'smaa' },
  },
};

export function detectTier() {
  const mobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
  if (mobile) return 'low';

  const mem   = navigator.deviceMemory || navigator.hardwareConcurrency || 4;
  const cores = navigator.hardwareConcurrency || 4;

  // Renderer string is the single best signal available to the web.
  let gpu = '';
  try {
    const c  = document.createElement('canvas');
    const gl = c.getContext('webgl2') || c.getContext('webgl');
    const ext = gl && gl.getExtension('WEBGL_debug_renderer_info');
    if (ext) gpu = (gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) || '').toLowerCase();
  } catch { /* privacy-restricted; fall through to core count */ }

  const strong = /rtx|radeon rx (6|7|9)|apple m[1-9] (pro|max|ultra)|arc a7/.test(gpu);
  const weak   = /intel.*(hd|uhd) graphics|mali|adreno|powervr/.test(gpu);

  if (strong && cores >= 8) return 'high';
  if (weak || cores <= 4 || mem <= 4) return 'low';
  return cores >= 8 ? 'high' : 'medium';
}

export class Settings {
  constructor(tier = detectTier()) {
    this.tier = tier;
    Object.assign(this, structuredClone(TIERS[tier]));
    this.pixelRatio = Math.min(this.pixelRatio, window.devicePixelRatio || 1);
  }
  apply(tier) {
    this.tier = tier;
    Object.assign(this, structuredClone(TIERS[tier]));
    this.pixelRatio = Math.min(this.pixelRatio, window.devicePixelRatio || 1);
    return this;
  }
}
