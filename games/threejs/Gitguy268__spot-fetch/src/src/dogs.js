// Eén configuratie per hond. Een nieuw ras toevoegen is hier een regel bijzetten.
// modelUrl: pad naar een geriggd GLB-model met clips idle, walk, run en sit; zonder modelUrl
// wordt de hond in code opgebouwd (dogModel.js).

export const SPOT = {
  naam: 'Spot',
  ras: 'Labrador retriever',
  vacht: 0x0d0d10,
  glans: 0x70747e,
  haar: 0.012, // haarlengte in m
  halsband: 0xc81d1d,
  schaal: 1,
  modelUrl: null,
};

// De hond die af en toe over het pad voorbijkomt.
export const PASSANT = {
  naam: 'Bo',
  ras: 'Golden retriever',
  vacht: 0xc08a3e,
  glans: 0xffe2a8,
  haar: 0.03,
  halsband: 0x1f4fa8,
  schaal: 0.95,
  modelUrl: null,
};

export const DOGS = [SPOT];
