/**
 * CATACLYSM — every system in the realm, conducted at once.
 *
 * A one-off directed sequence (~46 s) that plays through the CinematicDirector
 * and then hands back to the main reel. Nothing here is new technique; it is
 * pure choreography over systems that already exist — weather, lightning,
 * the eruption, the dragon, wildfire — which is the whole argument for having
 * built them as independent systems on a bus in the first place.
 *
 * Beat sheet
 *   The Sky Breaks        storm rolls in, lightning walks across the valley, roar
 *   Ashmaw Wakes          eruption; the column fills with volcanic lightning
 *   Wrath of the Wyrm     chase cam; the dragon strafes the ash-forest
 *   Emberhold Burns       from the square: a second run, strikes all around
 *   Ash and Ruin          crane out over a burning, scarred land; final roar
 */
import * as THREE from 'three';
import { gsap } from 'gsap';
import { bus, EV } from '../core/EventBus.js';
import { WORLD, height, canPlant } from '../world/Heightfield.js';

const V = (x, y, z) => new THREE.Vector3(x, y, z);

/** Nearest plantable point to (x, z), spiralling out. */
function findForest(x, z) {
  for (let r = 0; r < 400; r += 12) {
    for (let a = 0; a < Math.PI * 2; a += 0.5) {
      const px = x + Math.cos(a) * r, pz = z + Math.sin(a) * r;
      if (canPlant(px, pz)) return V(px, height(px, pz), pz);
    }
  }
  return V(x, height(x, z), z);
}

export class Cataclysm {
  constructor(app) {
    this.app = app;
    this.active = false;
    const vil = WORLD.village, cas = WORLD.castle;
    this.forest = findForest((vil.x + cas.x) * 0.5, (vil.z + cas.z) * 0.5 + 60);
    this.forest2 = findForest(vil.x + 40, vil.z + 230);
  }

  trigger() {
    if (this.active) return;
    const app = this.app;
    this.active = true;
    bus.emit(EV.CATACLYSM, { stage: 'start' });

    // Take the camera, whatever mode it was in.
    app.setCameraMode('cinematic');
    app.ui?._syncChip('#camChips', 'cam', 'cinematic');
    app.director.playSequence(this._shots(), () => {
      this.active = false;
      bus.emit(EV.CATACLYSM, { stage: 'end' });
    });
  }

  /** A burst of `n` cloud-to-ground strikes around a point, spread over `over` s. */
  _barrage(n, around, spread, over) {
    for (let i = 0; i < n; i++) {
      gsap.delayedCall(Math.random() * over, () => this.app.lightning.stormStrike(around, spread));
    }
  }

  _shots() {
    const app = this.app;
    const a = () => app.dragon.animator;
    const vol = WORLD.volcano, vil = WORLD.village;
    const plaza = app.village.plaza;
    const F = this.forest, F2 = this.forest2;
    const gy = (x, z, o) => height(x, z) + o;

    return [
      {
        name: 'The Sky Breaks',
        dur: 7, fov: 44,
        from: V(vil.x + 210, gy(vil.x + 210, vil.z + 260, 30), vil.z + 260),
        to:   V(vil.x + 160, gy(vil.x + 160, vil.z + 200, 22), vil.z + 200),
        look: V(vol.x, vol.height * 0.6, vol.z),
        lookTo: V(vil.x - 100, 200, vil.z - 300),
        ease: 'power1.inOut',
        onEnter: () => {
          app.setWeather('storm');
          app.ui?._syncChip('#wxChips', 'wx', 'storm');
          a().circle({ center: V(vil.x, 0, vil.z), radius: 380, altitude: 260, speed: 60 });
        },
        beats: [
          { at: 0.8, run: () => this._barrage(3, V(vil.x, 0, vil.z), 420, 1.5) },
          { at: 3.0, run: () => a().roar() },
          { at: 4.2, run: () => this._barrage(5, V(vil.x - 150, 0, vil.z - 150), 520, 2.5) },
        ],
      },
      {
        name: 'Ashmaw Wakes',
        dur: 11, fov: 40,
        from: V(vol.x + 820, 260, vol.z + 900),
        to:   V(vol.x + 660, 230, vol.z + 720),
        look: V(vol.x, vol.height * 0.75, vol.z),
        lookTo: V(vol.x, vol.height * 1.15, vol.z),
        ease: 'none',
        beats: [
          { at: 0.9, run: () => app.eruption.trigger() },
        ],
      },
      {
        name: 'Wrath of the Wyrm',
        dur: 10, fov: 54,
        track: 'dragonChase',
        ease: 'none',
        onEnter: () => a().attack(F, { duration: 4.2 }),
        beats: [
          { at: 7.5, run: () => this._barrage(2, F, 200, 1.2) },
        ],
      },
      {
        name: 'Emberhold Burns',
        dur: 10, fov: 50,
        from: V(vil.x + 50, gy(vil.x + 50, vil.z + 60, 5), vil.z + 60),
        to:   V(vil.x + 24, gy(vil.x + 24, vil.z + 30, 8), vil.z + 30),
        look: V(vil.x - 40, 150, vil.z - 120),
        lookTo: V(F2.x, F2.y + 20, F2.z),
        ease: 'power1.inOut',
        onEnter: () => a().attack(F2, { duration: 3.6 }),
        beats: [
          { at: 1.5, run: () => this._barrage(4, V(vil.x, 0, vil.z), 300, 3) },
          { at: 6.5, run: () => this._barrage(3, F2, 160, 2) },
        ],
      },
      {
        name: 'Ash and Ruin',
        dur: 10, fov: 46,
        from: V(vil.x - 60, 140, vil.z + 260),
        to:   V(vil.x - 260, 420, vil.z + 560),
        look: V(F.x, F.y, F.z),
        lookTo: V(vol.x * 0.5 + vil.x * 0.5, 120, vol.z * 0.5 + vil.z * 0.5),
        ease: 'power2.inOut',
        onEnter: () => a().circle({ center: V(F.x, 0, F.z), radius: 300, altitude: 240, speed: 52 }),
        beats: [
          { at: 2.5, run: () => a().roar() },
          { at: 5.0, run: () => this._barrage(3, V(F.x, 0, F.z), 500, 3) },
        ],
      },
    ];
  }
}
