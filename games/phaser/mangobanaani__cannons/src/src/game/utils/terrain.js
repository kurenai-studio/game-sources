export function generateHeightmap(width, minY, maxY, roughness = 0.6) {
  const heights = new Array(width);
  heights[0] = minY + Math.random() * (maxY - minY);
  heights[width - 1] = minY + Math.random() * (maxY - minY);

  function subdivide(left, right, displacement) {
    if (right - left <= 1) return;
    const mid = Math.floor((left + right) / 2);
    heights[mid] = (heights[left] + heights[right]) / 2
      + (Math.random() - 0.5) * displacement;
    heights[mid] = Math.max(minY, Math.min(maxY, heights[mid]));
    subdivide(left, mid, displacement * roughness);
    subdivide(mid, right, displacement * roughness);
  }

  subdivide(0, width - 1, (maxY - minY) * 0.5);
  return heights;
}

export function carveCrater(heightmap, centerX, radius, depth, maxY) {
  const startX = Math.max(0, Math.floor(centerX - radius));
  const endX = Math.min(heightmap.length - 1, Math.ceil(centerX + radius));

  for (let x = startX; x <= endX; x++) {
    const dist = Math.abs(x - centerX);
    if (dist < radius) {
      const factor = Math.cos((dist / radius) * Math.PI / 2);
      heightmap[x] = Math.min(heightmap[x] + depth * factor, maxY);
    }
  }
}
