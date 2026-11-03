import type { FloorKind, FurnitureKind, PropDef } from './types';

const FURNITURE = new Set<string>([
  'bed', 'sofa', 'armchair', 'table', 'lowtable', 'desk', 'kitchen', 'bath', 'wc', 'wardrobe', 'shelf',
  'tv', 'plant', 'bench', 'crates', 'pallet', 'drums', 'cabinet', 'bins', 'counter', 'pool',
] satisfies FurnitureKind[]);
const FLOOR = new Set<string>(['rug', 'clutter'] satisfies FloorKind[]);

/** Furniture: drawn over furniture tiles in the map, which hold the collision. */
export function isFurniture(p: PropDef): boolean {
  return FURNITURE.has(p.kind);
}

/** Rugs and clutter: drawn on open floor, block nothing. */
export function isFloorDressing(p: PropDef): boolean {
  return FLOOR.has(p.kind);
}

/** Width and height of a prop in tiles, as drawn. */
export function propSize(p: PropDef): { w: number; h: number } {
  if (p.w !== undefined && p.h !== undefined) return { w: p.w, h: p.h };
  if (isFurniture(p) || isFloorDressing(p)) return { w: p.w ?? 1, h: p.h ?? 1 };
  const long = p.kind === 'van' ? 4.4 : p.kind === 'truck' ? 9 : 4;
  const wide = p.kind === 'truck' ? 3 : 2;
  return p.vertical ? { w: wide, h: long } : { w: long, h: wide };
}

/**
 * Tall props (racking, lorries, containers, vans) block sight and bullets as well as movement.
 * Cars and furniture are low enough to see and shoot over.
 */
export function isTall(p: PropDef): boolean {
  return p.kind !== 'car' && !isFurniture(p) && !isFloorDressing(p);
}

/**
 * The tiles a prop stands on. Props are solid: nobody walks through a parked van, a car or a
 * container (cars and containers also sit on furniture tiles in the map). Rugs and clutter stand
 * on nothing.
 */
export function propTiles(p: PropDef): { tx: number; ty: number }[] {
  if (isFloorDressing(p)) return [];
  const { w, h } = propSize(p);
  const tiles: { tx: number; ty: number }[] = [];
  for (let ty = Math.floor(p.ty); ty < Math.ceil(p.ty + h); ty++) {
    for (let tx = Math.floor(p.tx); tx < Math.ceil(p.tx + w); tx++) tiles.push({ tx, ty });
  }
  return tiles;
}
