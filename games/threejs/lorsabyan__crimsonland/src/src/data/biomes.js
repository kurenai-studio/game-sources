// Terrain presets. Lighting is tuned per biome; the ground texture is generated from `tex`.
export const BIOMES = {
  dust: {
    id: 'dust', name: 'Dust Basin', blurb: 'Last light over cracked hardpan',
    sun: { color: '#ffb778', intensity: 3.1, dir: [-0.72, 0.5, 0.42] },
    hemi: { sky: '#7d90b8', ground: '#3b2a1e', intensity: 1.15 },
    env: 0.32, exposure: 0.92, bg: '#0b0806', lava: 0,
    rim: '#ffcf9e', lantern: '#ffd9ae', lanternI: 18,
    tex: { low: '#4a3423', mid: '#8f6a43', high: '#c6a06c', stone: '#8b8073', crack: 0.55, pebbles: 2600, grain: 0.1, patch: null },
    grass: { base: '#3f3a1c', tip: '#b39a4f', height: 0.55 },
    rock: { a: '#54473a', b: '#8d7a64' },
    props: { wood: ['#3a2c20', '#6f5a44'], bone: ['#6e6252', '#c9bda3'], low: ['#4a4036', '#8d7a64'], metal: '#3b2a20', stumps: true },
  },
  moss: {
    id: 'moss', name: 'Sunken Fen', blurb: 'Moonlight on rotten peat',
    sun: { color: '#9fc0ff', intensity: 2.5, dir: [0.55, 0.6, 0.5] },
    hemi: { sky: '#5f7fa4', ground: '#1c2a18', intensity: 1.05 },
    env: 0.4, exposure: 0.95, bg: '#040806', lava: 0,
    rim: '#9fdcc0', lantern: '#ffe9c0', lanternI: 34,
    tex: { low: '#17200f', mid: '#3a4a22', high: '#6f7d3c', stone: '#5c6459', crack: 0.25, pebbles: 1500, grain: 0.12, patch: { color: '#7c8f35', amount: 0.55 } },
    grass: { base: '#1f3514', tip: '#8fae4a', height: 0.8 },
    rock: { a: '#2c332b', b: '#5e6a55' },
    props: { wood: ['#1a1d14', '#3f4a28'], bone: ['#4a4c3c', '#8f9a78'], low: ['#2c332b', '#5e6a55'], metal: '#2a2a20', stumps: true },
  },
  ash: {
    id: 'ash', name: 'Cinder Flats', blurb: 'Burnt ground over a live seam',
    sun: { color: '#ff8a5c', intensity: 1.75, dir: [0.35, 0.66, -0.55] },
    hemi: { sky: '#5a4a60', ground: '#301410', intensity: 1.05 },
    env: 0.28, exposure: 1.0, bg: '#080302', lava: 0.34,
    rim: '#ff9a62', lantern: '#ffcfa0', lanternI: 36,
    tex: { low: '#0d0b0b', mid: '#2c2726', high: '#5a4f4b', stone: '#3f3936', crack: 0.7, pebbles: 2100, grain: 0.1, patch: null },
    grass: { base: '#141010', tip: '#3b2a24', height: 0.45 },
    rock: { a: '#171312', b: '#3b3330' },
    props: { wood: ['#0d0a09', '#2a2220'], bone: ['#2a2422', '#5e534c'], low: ['#100c0c', '#2e2624'], metal: '#1c1412', shards: true, ember: 0.5 },
  },
  frost: {
    id: 'frost', name: 'White Silence', blurb: 'Snow keeps a perfect record',
    sun: { color: '#cfe0ff', intensity: 1.5, dir: [-0.5, 0.62, -0.55] },
    hemi: { sky: '#a7c0e6', ground: '#6d7a92', intensity: 0.72 },
    env: 0.34, exposure: 0.8, bg: '#0a0e14', lava: 0,
    rim: '#d7ecff', lantern: '#ffe6c8', lanternI: 3.5,
    tex: { low: '#6f819e', mid: '#a4b2c8', high: '#cdd6e3', stone: '#67707e', crack: 0.12, pebbles: 700, grain: 0.05, patch: null },
    grass: { base: '#5a6470', tip: '#c8d4e2', height: 0.5 },
    rock: { a: '#3e4856', b: '#8d9cb1' },
    props: { wood: ['#2a2a30', '#bcc8d8'], bone: ['#5a6272', '#c6d0de'], low: ['#6f93c0', '#c8def2'], metal: '#2c2e36', shards: true },
  },
};

export const BIOME_LIST = Object.values(BIOMES);
