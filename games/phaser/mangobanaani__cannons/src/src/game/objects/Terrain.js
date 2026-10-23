import { generateHeightmap, carveCrater } from '../utils/terrain.js';
import * as Config from '../config.js';

export default class Terrain {
  constructor(scene, terrainType = 'earth') {
    this.scene = scene;
    this.graphics = scene.add.graphics();
    this.terrainType = terrainType;
    this.typeConfig = Config.TERRAIN_TYPES[terrainType] || Config.TERRAIN_TYPES.earth;

    this.heightmap = generateHeightmap(
      Config.GAME_WIDTH,
      Config.TERRAIN_MIN_Y,
      Config.TERRAIN_MAX_Y
    );
    this.render();
  }

  getHeightAt(x) {
    const ix = Math.max(0, Math.min(Math.floor(x), this.heightmap.length - 1));
    return this.heightmap[ix];
  }

  carve(centerX, radius) {
    const adjustedDepth = Config.WEAPONS.standard.craterDepth * this.typeConfig.craterMultiplier;
    carveCrater(this.heightmap, centerX, radius, adjustedDepth, Config.GAME_HEIGHT);
    this.render();
  }

  carveWithDepth(centerX, radius, depth) {
    const adjustedDepth = depth * this.typeConfig.craterMultiplier;
    carveCrater(this.heightmap, centerX, radius, adjustedDepth, Config.GAME_HEIGHT);
    this.render();
  }

  render() {
    this.graphics.clear();

    // Earth body
    this.graphics.fillStyle(this.typeConfig.color);
    this.graphics.beginPath();
    this.graphics.moveTo(0, this.heightmap[0]);
    for (let x = 1; x < this.heightmap.length; x++) {
      this.graphics.lineTo(x, this.heightmap[x]);
    }
    this.graphics.lineTo(Config.GAME_WIDTH, Config.GAME_HEIGHT);
    this.graphics.lineTo(0, Config.GAME_HEIGHT);
    this.graphics.closePath();
    this.graphics.fillPath();

    // Grass surface
    this.graphics.lineStyle(4, this.typeConfig.grassColor);
    this.graphics.beginPath();
    this.graphics.moveTo(0, this.heightmap[0]);
    for (let x = 1; x < this.heightmap.length; x++) {
      this.graphics.lineTo(x, this.heightmap[x]);
    }
    this.graphics.strokePath();
  }

  setType(type) {
    this.terrainType = type;
    this.typeConfig = Config.TERRAIN_TYPES[type] || Config.TERRAIN_TYPES.earth;
    this.render();
  }

  regenerate() {
    this.heightmap = generateHeightmap(
      Config.GAME_WIDTH,
      Config.TERRAIN_MIN_Y,
      Config.TERRAIN_MAX_Y
    );
    this.render();
  }

  destroy() {
    this.graphics.destroy();
  }
}
