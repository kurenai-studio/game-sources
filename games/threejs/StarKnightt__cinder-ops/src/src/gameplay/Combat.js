import * as THREE from 'three';
import { WEAPONS, falloffMult } from '../core/Constants.js';
import { eventBus, Events } from '../core/EventBus.js';
import { gameState } from '../core/GameState.js';
import { currentSpread } from './Gunplay.js';
import { perf } from '../core/Perf.js';

const _right = new THREE.Vector3();
const _up = new THREE.Vector3();

export class Combat {
  constructor(camera, squad, vfx, extract) {
    this.camera = camera;
    this.squad = squad;
    this.vfx = vfx;
    this.extract = extract || new THREE.Vector3(0, 0, 86);
    this._dir = new THREE.Vector3();
    this._aim = new THREE.Vector3();
    this._origin = new THREE.Vector3();
    this._muzzle = new THREE.Vector3();
    this._hit = new THREE.Vector3();
    this._tracerDir = new THREE.Vector3();
    this._vfxAt = new THREE.Vector3();
    this._shots = 0;        // for the pistol's every-2nd-shot tracer
    this._acc = new Map();
    eventBus.on(Events.WEAPON_FIRE, (d) => this._fire(d));
    eventBus.on(Events.PLAYER_HIT, (d) => this._playerHit(d));
    this.player = null;
    eventBus.on(Events.ENEMY_DIE, () => this._checkWin());
  }

  _fire(d) {
    perf.mark('combat');
    const cfg = WEAPONS[d?.id || gameState.activeWeapon] || WEAPONS.rifle;
    this.camera.updateMatrixWorld();
    this.camera.getWorldDirection(this._aim);
    this._origin.copy(this.camera.position);
    // Camera-local basis: spread and the muzzle fallback must live in the
    // view plane. Adding world-XYZ noise sent pellets (and any beam that
    // followed them) up the world Y axis whenever the player wasn't
    // looking down world −Z.
    _right.setFromMatrixColumn(this.camera.matrixWorld, 0);
    _up.setFromMatrixColumn(this.camera.matrixWorld, 1);
    if (d?.muzzle && Number.isFinite(d.muzzle.x)) {
      this._muzzle.copy(d.muzzle);
    } else {
      this._muzzle.copy(this._origin).addScaledVector(_right, 0.05).addScaledVector(_up, -0.04);
    }

    const st = gameState.player;
    const spread = currentSpread(cfg, st.bloom, {
      ads: d?.ads || st.ads,
      scoped: d?.ads || st.scoped,
      adsEase: d?.ads ? 1 : st.adsEase,
      speed: st.speed,
      grounded: st.grounded,
      crouching: st.crouching,
    });

    this._shots++;
    gameState.game.shotsFired += 1;
    this.squad.prepHits();
    // One tracer per trigger pull, ALWAYS along the unspread camera ray
    // (crosshair). Pellets may cone; the beam must not. Muzzle world pos
    // → camera-ray impact (or far point). Never the gun-mesh axis — viewmodel
    // kick/sway would yank the streak off the reticle.
    const centerHit = this.squad.rayHit(this._origin, this._aim, cfg.range);
    const centerDist = centerHit.enemy
      ? centerHit.dist
      : (centerHit.wallT < cfg.range ? centerHit.wallT : cfg.range);
    this._hit.copy(this._origin).addScaledVector(this._aim, Math.max(0.5, centerDist));
    this._tracerToHit(cfg);

    // Per-enemy accumulation so an 8-pellet blast lands as ONE hit event
    // (one thud, one hitmarker) instead of eight.
    const acc = this._acc;
    acc.clear();
    for (let p = 0; p < cfg.pellets; p++) {
      this._dir.copy(this._aim);
      if (spread > 0) {
        this._dir.addScaledVector(_right, (Math.random() - 0.5) * spread);
        this._dir.addScaledVector(_up, (Math.random() - 0.5) * spread);
        this._dir.normalize();
      }
      const hit = this.squad.rayHit(this._origin, this._dir, cfg.range);
      if (hit.enemy) {
        const dmg = cfg.damage
          * falloffMult(cfg.falloff, hit.dist)
          * (hit.headshot ? cfg.headMult : 1);
        if (dmg > 0) {
          const a = acc.get(hit.enemy) || { dmg: 0, headshot: false, dist: hit.dist };
          a.dmg += dmg;
          a.headshot = a.headshot || hit.headshot;
          acc.set(hit.enemy, a);
        }
        this._vfxAt.copy(this._origin).addScaledVector(this._dir, hit.dist);
        this.vfx?.impact(this._vfxAt, true);
      } else if (hit.wallT < cfg.range && p <= 2) {
        // Miss dust at the clip point. Capped per trigger pull for the
        // shotgun: ≤3 dust puffs, ≤4 sparks.
        this._vfxAt.copy(this._origin).addScaledVector(this._dir, hit.wallT);
        this.vfx?.dust(this._vfxAt, p < 2);
      }
    }
    if (acc.size) gameState.game.shotsHit += 1;
    for (const [enemy, a] of acc) {
      enemy.hit(a.dmg, a.headshot);
      if (a.headshot) gameState.game.headshots += 1;
    }
    this.squad._hitsFresh = false;
    perf.done('combat');
  }

  /** Beam from muzzle WORLD pos to the already-computed camera-ray impact. */
  _tracerToHit(cfg) {
    if (cfg.tracer === 'none') return;
    if (cfg.tracer === 'faint2nd' && (this._shots & 1)) return;
    this._tracerDir.copy(this._hit).sub(this._muzzle);
    const len = this._tracerDir.length();
    if (len < 0.2) return;
    this._tracerDir.multiplyScalar(1 / len);
    this.vfx?.tracer(this._muzzle, this._tracerDir, cfg.tracer, len);
  }

  _playerHit(d) {
    if (!gameState.player.alive) return;
    if (!gameState.game.isPlaying || gameState.game.grace > 0) return;
    const hp0 = gameState.player.health;
    const ar0 = gameState.player.armor;
    let dmg = d.dmg;
    if (gameState.player.armor > 0) {
      const soak = Math.min(gameState.player.armor, dmg * 0.55);
      gameState.player.armor -= soak;
      dmg -= soak;
    }
    gameState.player.health -= dmg;
    gameState.game.damageTaken += Math.max(0,
      (hp0 - Math.max(0, gameState.player.health)) + (ar0 - gameState.player.armor));
    if (gameState.player.health <= 0) {
      gameState.player.health = 0;
      gameState.player.alive = false;
      gameState.game.over = true;
      gameState.game.isPlaying = false;
      eventBus.emit(Events.PLAYER_DIE);
      eventBus.emit(Events.GAME_OVER);
    }
  }

  _checkWin() {
    if (gameState.game.remaining <= 0 && !gameState.game.won) {
      gameState.game.extractOpen = true;
      eventBus.emit(Events.EXTRACT_READY);
    }
  }

  tryExtract(playerPos) {
    if (!gameState.game.extractOpen || gameState.game.won) return;
    if (playerPos.distanceTo(this.extract) < 4.5) {
      gameState.game.won = true;
      gameState.game.isPlaying = false;
      eventBus.emit(Events.GAME_WIN);
    }
  }
}
