import Phaser from 'phaser';
import { RENDER_SCALE, TILE } from '../config';
import { blocksSight, parseLevel } from '../core/grid';
import { buildWallSegments, visibilityPolygon } from '../core/visibility';
import { drawLevelArt } from '../game/LevelArt';
import { levelById } from '../levels';

/** Levels the menus drift over: the most distinctive places in the game. */
const SHOWCASE = ['hillcrest-villa', 'the-halcyon', 'atlas-yard', 'harbour-freight', 'gull-point', 'westcliff-house', 'ardley-lodge', 'kestrel-road'];
const VIGNETTE_KEY = 'ui-vignette';

/**
 * The menus' backdrop: a real level's plan drifting slowly under a dark wash, with an operator's
 * light sweeping across it, cut off by the walls the same way it is in the game.
 */
export function attractBackdrop(scene: Phaser.Scene, dim = 0.62, levelId?: string): void {
  const def = levelById(levelId ?? Phaser.Utils.Array.GetRandom(SHOWCASE));
  const level = parseLevel(def.map);
  const w = level.width * TILE, h = level.height * TILE;
  const holder = scene.add.container(0, 0).setDepth(-10);
  const art = drawLevelArt(scene, level, def.labels, [], def.props ?? [], 0, RENDER_SCALE);
  holder.add(art);

  // The sweeping light, occluded by walls.
  const segs = buildWallSegments(level.width, level.height, TILE, (x, y) => blocksSight(level.tiles[y * level.width + x]));
  const entry = def.entries[0].approach.at(-1)!;
  const prev = def.entries[0].approach.at(-2) ?? entry;
  const ox = entry.tx * TILE, oy = entry.ty * TILE;
  const base = Math.atan2(entry.ty - prev.ty, entry.tx - prev.tx);
  // The light sits above the dark wash (in its own holder, moved with the plan) so it reads.
  const light = scene.add.graphics().setBlendMode(Phaser.BlendModes.ADD);
  const lightHolder = scene.add.container(0, 0, [light]).setDepth(-8.5);
  let t = 0;
  const sweep = (_: number, dms: number) => {
    t += dms / 1000;
    const facing = base + Math.sin(t * 0.35) * 0.7;
    const poly = visibilityPolygon(ox, oy, facing, 30 * Math.PI / 180, 700, segs, 1.2 * Math.PI / 180).polygon;
    light.clear();
    light.fillStyle(0xffc070, 0.05);
    light.beginPath();
    light.moveTo(poly[0], poly[1]);
    for (let i = 2; i < poly.length; i += 2) light.lineTo(poly[i], poly[i + 1]);
    light.closePath();
    light.fillPath();
  };
  scene.events.on('update', sweep);
  scene.events.once('shutdown', () => scene.events.off('update', sweep));

  // A slow drift across the plan, centred on where the light is.
  const scale = Math.max(1280 / w, 720 / h, 1.1);
  holder.setScale(scale);
  lightHolder.setScale(scale);
  const span = { x: Math.max(0, w * scale - 1280), y: Math.max(0, h * scale - 720) };
  const fx = Phaser.Math.Clamp(ox * scale - 640, 0, span.x), fy = Phaser.Math.Clamp(oy * scale - 360, 0, span.y);
  holder.setPosition(-fx, -fy);
  lightHolder.setPosition(-fx, -fy);
  scene.tweens.add({
    targets: [holder, lightHolder], x: -Phaser.Math.Clamp(fx + 160, 0, span.x), y: -Phaser.Math.Clamp(fy + 60, 0, span.y),
    duration: 40000, ease: 'Sine.InOut', yoyo: true, repeat: -1,
  });

  scene.add.rectangle(640, 360, 1280, 720, 0x07090c, dim).setDepth(-9);
  ensureVignette(scene);
  scene.add.image(640, 360, VIGNETTE_KEY).setDisplaySize(1280, 720).setDepth(-8);
}

/** Darkens the corners: focuses the eye on the middle of the screen. */
function ensureVignette(scene: Phaser.Scene): void {
  if (scene.textures.exists(VIGNETTE_KEY)) return;
  const tex = scene.textures.createCanvas(VIGNETTE_KEY, 640, 360)!;
  const ctx = tex.getContext();
  const g = ctx.createRadialGradient(320, 180, 60, 320, 180, 380);
  g.addColorStop(0, 'rgba(7,9,12,0)');
  g.addColorStop(1, 'rgba(7,9,12,0.92)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 640, 360);
  tex.refresh();
}
