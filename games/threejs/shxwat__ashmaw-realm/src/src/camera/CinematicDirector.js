/**
 * The cinematic director.
 *
 * A shot list, not a camera path. Each shot declares a duration, a lens, a
 * movement (dolly / crane / orbit / handheld push), what it's looking at, and
 * optionally a *beat* — an action fired at a moment inside the shot (the dragon
 * breathes on shot 6; the volcano erupts on shot 9). GSAP timelines interpolate
 * the abstract shot parameters and the rig turns those into camera motion.
 *
 * The sequence is composed like a trailer: establish the landscape → find the
 * ruin → find the people → reveal the monster → escalate → payoff.
 */
import * as THREE from 'three';
import { gsap } from 'gsap';
import { bus, EV } from '../core/EventBus.js';
import { WORLD, height } from '../world/Heightfield.js';
import { TAU, lerp, clamp } from '../utils/MathX.js';

const V = (x, y, z) => new THREE.Vector3(x, y, z);

export class CinematicDirector {
  constructor(rig, world) {
    this.rig = rig;
    this.w = world;
    this.playing = false;
    this.index = 0;
    this.t = 0;
    this.shot = null;
    this._tl = null;

    this.bars = document.getElementById('bars');
    this.titleEl = document.getElementById('shotTitle');
    this.nameEl = document.getElementById('shotName');

    this.shots = this._buildShots();
  }

  _buildShots() {
    const w = this.w;
    const vol = WORLD.volcano;
    const vil = WORLD.village;
    const cas = WORLD.castle;
    const tem = WORLD.temple;
    const fal = WORLD.falls;

    return [
      {
        name: 'The Grand Caldera',
        dur: 12, fov: 40,
        // Dramatic crane sweep over the caldera rim into the magmatic throat.
        from: V(120, 138, 700),
        to:   V(35, 164, 505),
        look: V(vol.x, vol.height * 0.64, vol.z),
        lookTo: V(vol.x, vol.height * 0.72, vol.z),
        ease: 'power1.inOut',
        onEnter: () => w.dragon.animator.circle({ radius: 520, altitude: 420, speed: 44 }),
      },
      {
        name: 'Rivers of Fire',
        dur: 6, fov: 40,
        // Low tracking shot along the lava channel.
        from: V(-150, 70, -60),
        to:   V(-40, 46, 130),
        look: V(-96, 24, 60),
        lookTo: V(-70, 12, 165),
        ease: 'none',
      },
      {
        name: 'Kaer Ashmaw',
        dur: 7, fov: 30,
        // Reveal the castle from behind a ridge, pushing in.
        from: V(cas.x + 340, cas.y + 120, cas.z + 330),
        to:   V(cas.x + 150, cas.y + 62, cas.z + 165),
        look: V(cas.x, cas.y + 40, cas.z),
        lookTo: V(cas.x + 10, cas.y + 58, cas.z),
        ease: 'power2.inOut',
      },
      {
        name: 'Emberhold',
        dur: 7, fov: 46,
        // Village flyover, descending.
        from: V(vil.x + 240, 165, vil.z + 250),
        to:   V(vil.x - 60, 62, vil.z - 40),
        look: V(vil.x, 40, vil.z),
        lookTo: V(vil.x - 40, 34, vil.z - 60),
        ease: 'power1.inOut',
        onEnter: () => w.dragon.animator.circle({ radius: 430, altitude: 300, speed: 52 }),
      },
      {
        name: 'The Falls',
        dur: 6, fov: 38,
        from: V(fal.x - 210, fal.top - 40, fal.z + 190),
        to:   V(fal.x - 120, WORLD.pool.y + 40, fal.z + 90),
        look: V(fal.x - 40, fal.top - 60, fal.z),
        lookTo: V(fal.x - 30, WORLD.pool.y + 20, fal.z),
        ease: 'power1.inOut',
      },
      {
        name: 'Wyrm Ascending',
        dur: 9, fov: 44,
        // Orbit the dragon: the rig tracks it live. The radius has to clear the
        // wingspan (~143 units tip to tip) or the orbit passes *through* the
        // creature and the shot is a faceful of membrane; 78 did exactly that.
        track: 'dragon',
        orbit: { radius: 210, height: 46, speed: 0.30 },
        ease: 'none',
        onEnter: () => w.dragon.animator.circle({ radius: 380, altitude: 300, speed: 56 }),
      },
      {
        name: 'Eye of Ashmaw',
        dur: 7, fov: 26,
        // Close on the head. Still tight — that's the point of the shot — but
        // outside the skull rather than inside it.
        track: 'dragonHead',
        orbit: { radius: 34, height: 6.0, speed: 0.16 },
        ease: 'none',
      },
      {
        name: 'Fire From Above',
        dur: 11, fov: 50,
        // Low angle from the village square, dragon dives and breathes.
        from: V(vil.x + 34, height(vil.x + 34, vil.z + 40) + 4, vil.z + 40),
        to:   V(vil.x + 10, height(vil.x + 10, vil.z + 16) + 6, vil.z + 16),
        look: V(vil.x - 40, 160, vil.z - 120),
        lookTo: V(vil.x - 20, 90, vil.z - 60),
        ease: 'power1.inOut',
        beats: [
          { at: 1.0, run: () => w.dragon.animator.attack(w.village.plaza) },
        ],
      },
      {
        name: 'Broken Temple',
        dur: 6, fov: 36,
        from: V(tem.x + 130, tem.y + 70, tem.z + 120),
        to:   V(tem.x + 44, tem.y + 26, tem.z + 46),
        look: V(tem.x, tem.y + 18, tem.z),
        lookTo: V(tem.x - 10, tem.y + 26, tem.z - 10),
        ease: 'power2.out',
        onEnter: () => w.dragon.animator.land(),
      },
      {
        name: 'Ashmaw Wakes',
        dur: 13, fov: 42,
        // Wide on the volcano; it erupts. Camera holds and shakes.
        from: V(vol.x + 700, 300, vol.z + 820),
        to:   V(vol.x + 620, 250, vol.z + 700),
        look: V(vol.x, vol.height * 0.7, vol.z),
        lookTo: V(vol.x, vol.height * 0.8, vol.z),
        ease: 'none',
        beats: [
          { at: 2.0, run: () => w.eruption.trigger() },
          { at: 6.0, run: () => w.dragon.animator.takeoff() },
        ],
      },
      {
        name: 'Sovereign Sky',
        dur: 10, fov: 52,
        track: 'dragonChase',
        ease: 'none',
        onEnter: () => w.dragon.animator.flyby(),
      },
    ];
  }

  start(index = 0) {
    this.playing = true;
    this.index = index % this.shots.length;
    this.bars?.classList.add('is-on');
    this._enter(this.shots[this.index]);
  }

  stop() {
    this.playing = false;
    this._tl?.kill();
    this.bars?.classList.remove('is-on');
    this.titleEl?.classList.remove('is-on');
  }

  next() {
    // A one-off sequence (the Cataclysm) hands back to the main reel when done.
    if (this._main && this.index + 1 >= this.shots.length) {
      this.shots = this._main;
      this._main = null;
      const done = this._onSequenceDone;
      this._onSequenceDone = null;
      this.index = 0;
      this._enter(this.shots[0]);
      done?.();
      return;
    }
    this.index = (this.index + 1) % this.shots.length;
    this._enter(this.shots[this.index]);
  }

  /** Play a one-off list of shots, then resume the main reel from the top. */
  playSequence(shots, onDone) {
    if (!this._main) this._main = this.shots;
    this.shots = shots;
    this._onSequenceDone = onDone;
    this.start(0);
  }

  get inSequence() { return !!this._main; }

  _enter(shot) {
    this.shot = shot;
    this.t = 0;
    this._fired = new Set();
    this._tl?.kill();

    // Shot title card.
    if (this.nameEl) this.nameEl.textContent = shot.name;
    this.titleEl?.classList.add('is-on');
    // Shots are now 6–13 s; a 3.4 s card sat on screen for over half of the
    // short ones. Scale it to the shot and cap it.
    this.titleEl?.classList.remove('is-off');
    gsap.delayedCall(Math.min(2.2, shot.dur * 0.32),
      () => this.titleEl?.classList.remove('is-on'));
    bus.emit(EV.SHOT, { name: shot.name });

    // Animate the abstract shot parameters. The rig does the smoothing, so we
    // can drive it with a hard lerp and still get silky motion.
    this.k = { p: 0 };
    this._tl = gsap.to(this.k, {
      p: 1, duration: shot.dur, ease: shot.ease ?? 'none',
      onComplete: () => { if (this.playing) this.next(); },
    });

    this.rig.fovTarget = shot.fov ?? 45;
    // Snap the rig close to the start of a cut so the ease-in doesn't drag the
    // camera across the map, but keep a little travel for a natural settle.
    if (shot.from) {
      this.rig.camera.position.lerp(shot.from, 0.92);
      this.rig.focus.lerp(shot.look ?? this.rig.focus, 0.92);
    }
    shot.onEnter?.();
  }

  update(dt) {
    if (!this.playing || !this.shot) return;
    this.t += dt;
    const s = this.shot;
    const k = this.k.p;

    for (const b of s.beats ?? []) {
      if (!this._fired.has(b) && this.t >= b.at) { this._fired.add(b); b.run(); }
    }

    const d = this.w.dragon;

    if (s.track === 'dragon' || s.track === 'dragonHead') {
      const target = s.track === 'dragonHead'
        ? d.dragon.spine[2].clone()
        : d.animator.pos.clone();
      const o = s.orbit;
      const a = this.t * o.speed + 1.2;
      const pos = target.clone().add(V(
        Math.cos(a) * o.radius,
        o.height + Math.sin(a * 0.7) * o.radius * 0.16,
        Math.sin(a) * o.radius,
      ));
      const ground = height(pos.x, pos.z) + 8;
      pos.y = Math.max(pos.y, ground);
      this.rig.setDesired(pos, target, {
        smoothing: s.track === 'dragonHead' ? 0.0009 : 0.0016,
        targetSmoothing: 0.0006,
        fov: s.fov,
      });
      return;
    }

    if (s.track === 'dragonChase') {
      // Chase framing, sized to the creature and offset to a three-quarter
      // rear so both wings read (see CameraRig._updateFollow for why).
      const p = d.animator.pos;
      const fwd = d.animator.forward;
      const right = new THREE.Vector3()
        .crossVectors(new THREE.Vector3(0, 1, 0), fwd).normalize();
      const pos = p.clone()
        .addScaledVector(fwd, -175)
        .addScaledVector(right, 62)
        .add(V(0, 40, 0));
      pos.y = Math.max(pos.y, height(pos.x, pos.z) + 20);
      this.rig.setDesired(pos, p.clone().addScaledVector(fwd, 34), {
        smoothing: 0.0022, targetSmoothing: 0.0012, fov: s.fov,
      });
      return;
    }

    // Static-path shot: interpolate the dolly and the look-at independently.
    const pos = s.from.clone().lerp(s.to, k);
    const look = (s.look ?? s.to).clone().lerp(s.lookTo ?? s.look ?? s.to, k);
    this.rig.setDesired(pos, look, {
      smoothing: 0.0006, targetSmoothing: 0.0009, fov: s.fov,
    });
  }
}
