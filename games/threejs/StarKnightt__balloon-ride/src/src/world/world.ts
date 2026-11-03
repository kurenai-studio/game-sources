/**
 * The countryside seen from the balloon: heightfield terrain with the painted patchwork, river and
 * lake, the village, farms, hedgerows, woods and orchards, and the small life on it.
 * `buildWorld` assembles everything once at boot; `update` runs LOD / culling and animation.
 */
import * as THREE from "three";
import { TIER } from "../core/tier";
import { LAND } from "../render/landMaterials";
import { buildHeightfield, groundHeight } from "./heightfield";
import { buildParcels, type ParcelSet } from "./parcels";
import { paintGroundMap, type PaintShape } from "./groundmap";
import { Terrain } from "./terrain";
import { GRID_HALF } from "./layout";
import { buildVillage, planVillage } from "./village";
import { VMAP, paintVillageMap } from "./villagemap";
import { buildVegetation } from "./vegetation";
import { buildLife } from "./life";

export interface World {
  group: THREE.Group;
  terrain: Terrain;
  parcels: ParcelSet;
  update(camera: THREE.PerspectiveCamera, t: number, dt: number): void;
  groundHeight(x: number, z: number): number;
  info(): Record<string, number>;
}

export async function buildWorld(seed: number, pause: () => Promise<void>, log: (s: string, ms: number) => void = () => {}): Promise<World> {
  let t0 = performance.now();
  const lap = (s: string) => {
    const t = performance.now();
    log(s, t - t0);
    t0 = t;
  };
  buildHeightfield(seed);
  lap("heightfield");
  const parcels = buildParcels(seed);
  lap("parcels");
  await pause();

  const plan = planVillage(seed);
  lap("village plan");
  const veg = await buildVegetation(parcels.parcels, parcels.edges, plan, seed, pause);
  lap("vegetation");
  const shapes: PaintShape[] = plan.shapes;
  const res = TIER.dpr <= 1 && TIER.msaa === 0 ? 2048 : 4096;
  const map = paintGroundMap(res, parcels.parcels, parcels.edges, shapes, veg.hedgeLines, plan.noRoad);
  LAND.uMapA.value = map.a;
  LAND.uMapB.value = map.b;
  LAND.uMapC.value = map.c;
  LAND.uMapHalf.value = GRID_HALF;
  lap("groundmap");
  const vmap = paintVillageMap(plan, res === 4096 ? 3072 : 1536);
  LAND.uMapV.value = vmap.color;
  LAND.uMapVM.value = vmap.mask;
  LAND.uMapVRect.value.set(VMAP.x, VMAP.z, VMAP.half);
  lap("villagemap");
  await pause();

  const group = new THREE.Group();
  group.name = "world";
  const terrain = new Terrain();
  group.add(terrain.group);
  lap("terrain");
  const village = buildVillage(plan);
  group.add(village.group);
  group.add(veg.group);
  lap("village");
  const life = buildLife(parcels.parcels, plan.chimneys, seed);
  group.add(life.group);
  lap("life");

  return {
    group,
    terrain,
    parcels,
    groundHeight,
    update(camera, t) {
      terrain.update(camera);
      veg.update(camera);
      village.update(t, camera);
      life.update(t);
    },
    info: () => ({ parcels: parcels.parcels.length, houses: plan.houses.length, ...veg.info(), ...life.info() }),
  };
}
