import * as THREE from 'three';
let cached;

// Tileable five-octave density baked once. Two filtered reads replace dozens
// of simplex evaluations per cloud pixel and also accelerate sky IBL updates.
export function cloudNoise() {
  if (cached) return cached;
  const size = 128;
  const data = new Uint8Array(size * size);
  const hash = (x, y, p) => {
    let h = Math.imul((x % p + p) % p, 374761393) ^ Math.imul((y % p + p) % p, 668265263);
    h = Math.imul(h ^ (h >>> 13), 1274126177);
    return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
  };
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    let sum = 0, weight = 0.5, norm = 0;
    for (let o = 0; o < 5; o++) {
      const p = 4 * (1 << o), u = x / size * p, v = y / size * p;
      const ix = Math.floor(u), iy = Math.floor(v);
      let fx = u - ix, fy = v - iy;
      fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy);
      const a = hash(ix, iy, p), b = hash(ix + 1, iy, p);
      const c = hash(ix, iy + 1, p), d = hash(ix + 1, iy + 1, p);
      sum += ((a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy) * weight;
      norm += weight; weight *= 0.5;
    }
    data[y * size + x] = THREE.MathUtils.clamp((sum / norm - 0.5) * 1.65 + 0.5, 0, 1) * 255;
  }
  cached = new THREE.DataTexture(data, size, size, THREE.RedFormat);
  cached.wrapS = cached.wrapT = THREE.RepeatWrapping;
  cached.minFilter = THREE.LinearMipmapLinearFilter;
  cached.magFilter = THREE.LinearFilter;
  cached.generateMipmaps = true;
  cached.needsUpdate = true;
  return cached;
}
