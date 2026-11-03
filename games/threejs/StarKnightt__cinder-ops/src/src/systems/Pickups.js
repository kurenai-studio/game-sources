import * as THREE from 'three';
import {
  PICKUP_PROMPT_RANGE, PICKUP_TAKE_RANGE, CHEST_REFILL, PLAYER_CONFIG,
} from '../core/Constants.js';
import { gameState } from '../core/GameState.js';
import { eventBus, Events } from '../core/EventBus.js';
import { makeBeaconGlowMat, makeBeaconShaftMat } from './beaconShader.js';

/* Supply chests (c35). Same plaza / Suq crate spots as the old heavy
 * pickups. Walk-over at 1.2 m; E within 4 m. Beacons stay — dusty green
 * for HP, steel blue for armor. Chests refill after CHEST_REFILL seconds. */
const HP_GLOW = 0x7aaf6a;
const AR_GLOW = 0x6a8caf;
const PROMPT_R2 = PICKUP_PROMPT_RANGE * PICKUP_PROMPT_RANGE;

export class PickupSystem {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'pickups';
    scene.add(this.group);
    this._meshes = new Map();
    this._shaftHp = makeBeaconShaftMat(HP_GLOW);
    this._glowHp = makeBeaconGlowMat(HP_GLOW);
    this._shaftAr = makeBeaconShaftMat(AR_GLOW);
    this._glowAr = makeBeaconGlowMat(AR_GLOW);
    this._use = false;
    this._onKey = (e) => { if (e.code === 'KeyE' && !e.repeat) this._use = true; };
    addEventListener('keydown', this._onKey);
    this._steel = new THREE.MeshStandardMaterial({
      color: 0x6a7078, roughness: 0.48, metalness: 0.78, envMapIntensity: 0.55,
    });
    this._crate = new THREE.MeshStandardMaterial({
      color: 0x6e5430, roughness: 0.88, metalness: 0.02, envMapIntensity: 0.18,
    });
    this._band = new THREE.MeshStandardMaterial({
      color: 0x3a3428, roughness: 0.7, metalness: 0.15, envMapIntensity: 0.2,
    });
    this._cross = new THREE.MeshStandardMaterial({
      color: 0xc8d4b8, roughness: 0.55, metalness: 0.08, envMapIntensity: 0.28,
    });
    this._plate = new THREE.MeshStandardMaterial({
      color: 0x5a6a7a, roughness: 0.42, metalness: 0.62, envMapIntensity: 0.45,
    });
    this._crateGeo = new THREE.BoxGeometry(0.64, 0.50, 0.64);
    this._bandGeo = new THREE.BoxGeometry(0.66, 0.038, 0.66);
    this._glowGeo = new THREE.CircleGeometry(0.70, 32);
    this._glowGeo.rotateX(-Math.PI / 2);
    this._columnGeo = new THREE.PlaneGeometry(0.88, 4.4, 1, 1);
    this.sync();
  }

  _glowDisc(kind) {
    const m = new THREE.Mesh(this._glowGeo, kind === 'armor' ? this._glowAr : this._glowHp);
    m.castShadow = false;
    m.receiveShadow = false;
    m.raycast = () => {};
    return m;
  }

  _beacon(kind) {
    const g = new THREE.Group();
    const col = new THREE.Mesh(this._columnGeo, kind === 'armor' ? this._shaftAr : this._shaftHp);
    col.position.y = 2.4;
    col.castShadow = false;
    col.receiveShadow = false;
    col.raycast = () => {};
    g.add(col);
    g.userData.shaft = col;
    const light = new THREE.PointLight(kind === 'armor' ? AR_GLOW : HP_GLOW, 1.6, 9, 2);
    light.position.y = 2.6;
    light.castShadow = false;
    g.add(light);
    return g;
  }

  _crateStack() {
    const g = new THREE.Group();
    const box = new THREE.Mesh(this._crateGeo, this._crate);
    box.position.y = 0.26;
    box.castShadow = false;
    box.receiveShadow = true;
    g.add(box);
    const b0 = new THREE.Mesh(this._bandGeo, this._band);
    b0.position.y = 0.12;
    b0.castShadow = false;
    g.add(b0);
    const b1 = new THREE.Mesh(this._bandGeo, this._band);
    b1.position.y = 0.40;
    b1.castShadow = false;
    g.add(b1);
    return g;
  }

  _emblem(kind) {
    const g = new THREE.Group();
    if (kind === 'armor') {
      const plate = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.34, 0.06), this._plate);
      plate.position.set(0, 0.18, 0);
      plate.rotation.x = -0.18;
      plate.castShadow = false;
      g.add(plate);
      const rim = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.08, 0.07), this._steel);
      rim.position.set(0, 0.04, 0.01);
      rim.castShadow = false;
      g.add(rim);
    } else {
      const v = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.28, 0.06), this._cross);
      v.position.y = 0.16;
      v.castShadow = false;
      g.add(v);
      const h = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.08, 0.06), this._cross);
      h.position.y = 0.16;
      h.castShadow = false;
      g.add(h);
    }
    return g;
  }

  _prop(p) {
    const kind = p.id === 'armor' ? 'armor' : 'health';
    const g = new THREE.Group();
    g.add(this._crateStack());
    const glow = this._glowDisc(kind);
    glow.position.y = 0.515;
    g.add(glow);
    const beacon = this._beacon(kind);
    g.add(beacon);
    g.userData.shaft = beacon.userData.shaft;
    const emblem = this._emblem(kind);
    emblem.position.set(0, 0.52, 0);
    g.add(emblem);
    g.userData.weapon = emblem;
    g.userData.baseY = 0.52;
    return g;
  }

  /** Reconcile prop meshes with gameState.pickups (reset/restart safe). */
  sync() {
    const live = new Set(gameState.pickups);
    for (const [entry, m] of this._meshes) {
      if (!live.has(entry)) {
        this.group.remove(m);
        this._meshes.delete(entry);
      }
    }
    for (const p of gameState.pickups) {
      let m = this._meshes.get(p);
      if (!m) {
        m = this._prop(p);
        m.position.set(p.x, p.y, p.z);
        this.group.add(m);
        this._meshes.set(p, m);
      }
      this._applyTaken(m, p.taken);
    }
  }

  /* Hide meshes when taken, but keep the beacon PointLight in the graph
   * at intensity 0. Toggling a light out of the scene recompiles every
   * MeshStandard program (5s hitch on first chest take). */
  _applyTaken(m, taken) {
    m.visible = true;
    m.traverse((o) => {
      if (o.isLight) {
        o.intensity = taken ? 0 : 1.6;
        o.visible = true;
      } else if (o.isMesh) {
        o.visible = !taken;
      }
    });
  }

  update(dt, time, playerPos) {
    for (const p of gameState.pickups) {
      if (p.taken && p.refill > 0) {
        p.refill -= dt;
        if (p.refill <= 0) {
          p.taken = false;
          p.refill = 0;
          p.grace = 0.45; // visible pop-in before walk-over re-takes
        }
      }
    }
    this.sync();
    const pulse = 0.55 + 0.45 * Math.sin(time * Math.PI);
    const gainS = 0.28 + pulse * 0.34;
    const gainG = 0.12 + pulse * 0.04;
    this._shaftHp.uniforms.uGain.value = gainS;
    this._shaftAr.uniforms.uGain.value = gainS;
    this._glowHp.uniforms.uGain.value = gainG;
    this._glowAr.uniforms.uGain.value = gainG;
    for (const [, m] of this._meshes) {
      const w = m.userData.weapon;
      if (w && m.visible) {
        w.position.y = m.userData.baseY + 0.014 * Math.sin(time * 1.8);
      }
      const shaft = m.userData.shaft;
      if (shaft) {
        const dx = playerPos.x - m.position.x;
        const dz = playerPos.z - m.position.z;
        shaft.rotation.y = Math.atan2(dx, dz);
      }
    }
    let nearest = null;
    let nearestD2 = PROMPT_R2;
    for (const p of gameState.pickups) {
      if (p.taken) continue;
      if (p.grace > 0) p.grace -= dt;
      const dx = playerPos.x - p.x;
      const dz = playerPos.z - p.z;
      const d2 = dx * dx + dz * dz;
      if (d2 < nearestD2) {
        nearest = p;
        nearestD2 = d2;
      }
    }
    gameState.nearbyPickup = nearest
      ? { id: nearest.id, name: nearest.name || nearest.id }
      : null;
    if (!gameState.player.alive) {
      this._use = false;
      return;
    }
    const takeR = this._use ? PICKUP_PROMPT_RANGE : PICKUP_TAKE_RANGE;
    this._use = false;
    if (nearest && !(nearest.grace > 0) && nearestD2 <= takeR * takeR) this._take(nearest);
  }

  _take(p) {
    const st = gameState.player;
    const hpRoom = Math.max(0, PLAYER_CONFIG.HEALTH - st.health);
    const arRoom = Math.max(0, PLAYER_CONFIG.ARMOR - st.armor);
    const hpGain = Math.min(p.hp || 0, hpRoom);
    const arGain = Math.min(p.armor || 0, arRoom);
    st.health = Math.min(PLAYER_CONFIG.HEALTH, st.health + (p.hp || 0));
    st.armor = Math.min(PLAYER_CONFIG.ARMOR, st.armor + (p.armor || 0));
    p.taken = true;
    p.refill = CHEST_REFILL;
    eventBus.emit(Events.PICKUP, { id: p.id, kind: 'supply', hp: hpGain, armor: arGain });
  }
}
