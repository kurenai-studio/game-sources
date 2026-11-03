/**
 * The ride: the player's balloon (flight model, flame, glow, sway), the other balloons, the cloud
 * layers, the wind fluff and the cameras, updated once per frame from main.ts.
 */
import * as THREE from "three";
import { G } from "../render/materials";
import { BalloonActor, loadBalloon } from "./balloon";
import { Flight, PHYS } from "./physics";
import { OtherBalloons } from "./others";
import { Cameras } from "./cameras";
import { WindFx } from "./windfx";
import { Clouds } from "../world/cloudlayers";
import { windAt } from "./wind";
import { LAND } from "../render/landMaterials";
import { Cinematic } from "./cinematic";
import { Pilot } from "./pilot";

export class Ride {
  readonly group = new THREE.Group();
  readonly flight: Flight;
  readonly player: BalloonActor;
  readonly others: OtherBalloons;
  readonly clouds: Clouds;
  readonly fx = new WindFx();
  readonly cams: Cameras;
  /** The pilot in the player's basket (Phase 7). */
  readonly pilot: Pilot;
  /** The running cinematic (C), or null. */
  cine: Cinematic | null = null;
  /** Cinematic time (s) for this frame, set by main before update(). */
  cineT = 0;
  private cineScript: Cinematic | null = null;
  /** Force the burner on (captures) regardless of input. */
  forceBurner: boolean | null = null;
  private readonly tmp = new THREE.Vector3();
  private readonly w = new THREE.Vector2();
  private snapNext = true;

  private constructor(tpl: THREE.Group, pilot: Pilot, camera: THREE.PerspectiveCamera, el: HTMLElement, private readonly ground: (x: number, z: number) => number, seed: number) {
    this.flight = new Flight(ground);
    this.player = new BalloonActor(tpl, 0, 0);
    this.pilot = pilot;
    this.player.model.add(pilot.root);
    this.group.add(this.player.root);
    windAt(PHYS.start.x, PHYS.start.y, PHYS.start.z, 0, this.w);
    this.others = new OtherBalloons(tpl, PHYS.start, this.w.clone().normalize(), ground);
    this.group.add(this.others.group);
    this.clouds = new Clouds(seed);
    this.group.add(this.clouds.group);
    this.group.add(this.fx.mesh);
    this.cams = new Cameras(camera, el);
    this.flight.place(PHYS.start.x, PHYS.start.y, PHYS.start.z, 0);
    // Start looking along the drift, slightly off to the side so the village shows past the balloon.
    windAt(PHYS.start.x, PHYS.start.y, PHYS.start.z, 0, this.w);
    this.cams.behind(this.w.x, this.w.y);
    this.cams.chase.yaw += 0.35;
    this.cams.snap();
    this.place();
  }

  static async create(camera: THREE.PerspectiveCamera, el: HTMLElement, ground: (x: number, z: number) => number, seed: number): Promise<Ride> {
    const [tpl, pilot] = await Promise.all([loadBalloon(), Pilot.load()]);
    return new Ride(tpl, pilot, camera, el, ground, seed);
  }

  private place(): void {
    this.player.root.position.copy(this.flight.pos);
    this.player.setSway(this.flight.sway.x, this.flight.sway.y, this.flight.yaw);
    this.player.root.updateMatrixWorld(true);
  }

  /** Horizontal heading (x, z) the current view looks along. */
  viewHeading(camera: THREE.Camera, out = new THREE.Vector2()): THREE.Vector2 {
    const v = this.cams.view;
    const yaw = v === "chase" ? this.cams.chase.yaw : this.cams.look.yaw;
    if (v === "free") {
      camera.getWorldDirection(this.tmp);
      return out.set(this.tmp.x, this.tmp.z).normalize();
    }
    return out.set(-Math.sin(yaw), -Math.cos(yaw));
  }

  /** Lay the other balloons out again in a fan ahead of the current view. */
  resetOthers(camera: THREE.Camera, around = this.flight.pos): void {
    this.others.reset(around, this.viewHeading(camera));
  }

  /** Start the cinematic: the balloon jumps to the script's start and the camera follows the path. */
  startCinematic(): Cinematic {
    this.cine = this.cineScript ??= new Cinematic(this.ground);
    this.cams.setView("free");
    this.flight.place(this.cine.start.x, this.cine.start.y, this.cine.start.z, 0);
    this.flight.yaw = 0.4;
    this.others.reset(this.cine.start, this.cine.heading());
    this.snap();
    return this.cine;
  }

  /** Leave the cinematic: flying on from wherever the balloon is, chase camera behind it. */
  stopCinematic(): void {
    if (!this.cine) return;
    const h = this.cine.heading();
    this.cine = null;
    const p = this.flight.pos;
    this.flight.place(p.x, p.y, p.z, 0);
    this.cams.setView("chase");
    this.cams.behind(h.x, h.y);
    this.cams.chase.yaw += 0.35;
    this.snap();
  }

  /** Snap the cameras and whiteout next frame (after a teleport). */
  snap(): void {
    this.snapNext = true;
  }

  /**
   * dt = game seconds (0 while paused), realDt = wall seconds (cameras, flame easing).
   * `burner` / `vent` are the player's inputs.
   */
  update(t: number, dt: number, realDt: number, burner: boolean, vent: boolean, camera: THREE.PerspectiveCamera): void {
    const f = this.flight;
    const cine = this.cine;
    const snap = this.snapNext;
    this.snapNext = false;
    if (cine) {
      // Scripted: the balloon's place, the burner and the flame are functions of the cinematic time.
      const s = this.cineT;
      f.burner = cine.burning(s);
      f.vent = false;
      cine.balloonAt(s, f.pos);
      cine.balloonAt(s + 0.1, this.tmp);
      f.vel.subVectors(this.tmp, f.pos).multiplyScalar(10);
      f.sway.set(Math.sin(s * 0.9) * 0.008, Math.cos(s * 0.7) * 0.008);
      this.place();
      this.player.flame.setLevel(cine.flame(s));
    } else {
      f.burner = this.forceBurner ?? burner;
      f.vent = vent && !f.burner;
      f.step(dt, t);
      this.place();
      this.player.flame.update(f.burner, realDt, snap);
    }
    // The burner's light: a flickering warm glow at the nozzles while it burns.
    const fl = this.player.flame.level;
    const flick = 0.85 + 0.15 * Math.sin(t * 31) * Math.sin(t * 17.3 + 1.0);
    this.player.burnerWorld(this.tmp);
    G.uGlow.value.set(this.tmp.x, this.tmp.y, this.tmp.z, fl * 6.0 * flick);
    // The pilot: her arm follows the burner (the flame stays on the input), she looks over the edge
    // now and then, and in the basket view only her hand on the lever is drawn.
    const basket = this.cams.view === "basket";
    this.pilot.setBasketView(basket);
    this.pilot.update(dt, f.burner, basket && this.cams.look.pitch < -0.75);
    this.others.update(f.pos, t, dt, realDt);
    if (snap) this.cams.snap();
    this.cams.update(snap ? 1 : realDt, f.pos, this.player.model.matrixWorld, this.ground, f.yaw);
    if (cine) cine.pose(this.cineT, camera);
    camera.updateMatrixWorld();
    this.clouds.update(t, camera, realDt, snap);
    this.fx.update(camera.position, t, dt);
    // Cloud shadows on the land round where the camera looks (they fade out at dusk).
    camera.getWorldDirection(this.tmp);
    const h = Math.max(camera.position.y, 1);
    const reach = this.tmp.y < -0.05 ? Math.min(h / -this.tmp.y, 1500) : 800;
    this.tmp.multiplyScalar(reach).add(camera.position);
    this.clouds.shadows(this.tmp, camera.position, G.uCloudLight.value, LAND.uCloudSh.value, LAND.uCloudShDir.value);
    LAND.uCloudShK.value = (1 - Math.min(1, G.uNight.value * 2.5)) * Math.min(1, Math.max(0, (G.uSunDir.value.y + 0.02) * 8));
  }
}
