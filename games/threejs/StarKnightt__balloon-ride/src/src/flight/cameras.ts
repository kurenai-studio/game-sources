/**
 * Cameras.
 *  - chase (default): behind and above the balloon, orbiting the envelope's centre. Mouse / touch
 *    drag orbits (smoothed), the wheel zooms a little.
 *  - basket (V): the eye at the basket rim, looking out and down; the rim, the uprights and the
 *    flying wires frame the view, the burner hangs overhead. Drag looks around. Looking steeply down
 *    the eye leans out over the rim.
 *  - free: a fixed camera set by scripts (__game.setCamera), until a view is chosen again.
 */
import * as THREE from "three";
import { BALLOON } from "./balloon";

export type View = "chase" | "basket" | "free";

const DEG = Math.PI / 180;
const clamp = (x: number, a: number, b: number) => Math.min(b, Math.max(a, x));

export class Cameras {
  view: View = "chase";
  /** Chase orbit: yaw (rad, 0 = camera on +z of the balloon), pitch (rad above level), distance (m). */
  readonly chase = { yaw: 0, pitch: 14 * DEG, dist: 52 };
  /** Basket look: yaw, pitch (negative = down). */
  readonly look = { yaw: 0, pitch: -24 * DEG };
  private readonly cur = { yaw: 0, pitch: 14 * DEG, dist: 52, lyaw: 0, lpitch: -24 * DEG };
  private drag: { id: number; x: number; y: number } | null = null;
  /** Normal camera near plane; the basket view needs a closer one for the rim. */
  readonly baseNear: number;
  readonly baseFov: number;

  constructor(private readonly camera: THREE.PerspectiveCamera, el: HTMLElement) {
    this.baseNear = camera.near;
    this.baseFov = camera.fov;
    el.style.touchAction = "none";
    el.addEventListener("pointerdown", (e) => {
      if ((e.target as HTMLElement).dataset?.btn) return;
      this.drag = { id: e.pointerId, x: e.clientX, y: e.clientY };
      el.setPointerCapture(e.pointerId);
    });
    el.addEventListener("pointermove", (e) => {
      if (!this.drag || e.pointerId !== this.drag.id) return;
      const dx = e.clientX - this.drag.x, dy = e.clientY - this.drag.y;
      this.drag.x = e.clientX;
      this.drag.y = e.clientY;
      const k = e.pointerType === "touch" ? 1.4 : 1;
      if (this.view === "basket") {
        this.look.yaw -= dx * 0.0045 * k;
        this.look.pitch = clamp(this.look.pitch - dy * 0.0035 * k, -89 * DEG, 60 * DEG);
      } else {
        this.chase.yaw -= dx * 0.005 * k;
        this.chase.pitch = clamp(this.chase.pitch + dy * 0.004 * k, -15 * DEG, 75 * DEG);
      }
    });
    const end = (e: PointerEvent) => {
      if (this.drag?.id === e.pointerId) this.drag = null;
    };
    el.addEventListener("pointerup", end);
    el.addEventListener("pointercancel", end);
    el.addEventListener(
      "wheel",
      (e) => {
        e.preventDefault();
        this.chase.dist = clamp(this.chase.dist * Math.exp(e.deltaY * 0.0008), 30, 95);
      },
      { passive: false },
    );
  }

  toggle(): void {
    this.setView(this.view === "basket" ? "chase" : "basket");
  }

  setView(v: View): void {
    this.view = v;
  }

  /** Jump the smoothed state to the targets (captures). */
  snap(): void {
    Object.assign(this.cur, { yaw: this.chase.yaw, pitch: this.chase.pitch, dist: this.chase.dist, lyaw: this.look.yaw, lpitch: this.look.pitch });
  }

  /**
   * Place the camera for this frame. `basket` is the basket floor's world matrix (sway included),
   * `ground` the terrain height under a point. dt is real seconds.
   */
  update(dt: number, basketPos: THREE.Vector3, basket: THREE.Matrix4, ground: (x: number, z: number) => number, basketYaw = 0): void {
    const cam = this.camera;
    const k = 1 - Math.exp(-dt * 6);
    const c = this.cur;
    c.yaw += (this.chase.yaw - c.yaw) * k;
    c.pitch += (this.chase.pitch - c.pitch) * k;
    c.dist += (this.chase.dist - c.dist) * k;
    c.lyaw += (this.look.yaw - c.lyaw) * (1 - Math.exp(-dt * 12));
    c.lpitch += (this.look.pitch - c.lpitch) * (1 - Math.exp(-dt * 12));
    if (this.view === "free") return;

    let near = this.baseNear, fov = this.baseFov;
    if (this.view === "chase") {
      const tx = basketPos.x, ty = basketPos.y + BALLOON.centreY - 2, tz = basketPos.z;
      const cp = Math.cos(c.pitch);
      let x = tx + Math.sin(c.yaw) * cp * c.dist, y = ty + Math.sin(c.pitch) * c.dist, z = tz + Math.cos(c.yaw) * cp * c.dist;
      y = Math.max(y, Math.max(ground(x, z), 0) + 2.5);
      cam.position.set(x, y, z);
      cam.lookAt(tx, ty, tz);
    } else {
      // Eye at the rim on the side we look toward; leaning out over it as the look turns down.
      // The eye stands at the middle of the side the look faces (never behind a corner upright), and
      // leans out over the rim as the look turns down.
      const down = clamp((-c.lpitch - 40 * DEG) / (45 * DEG), 0, 1);
      // Straight down the eye sits just past the rim: the padded rim and the basket's inside stay in
      // the bottom of the frame (further out, the outer wall alone filled it like a roof).
      // Looking out, the eye stands well inside: both corner uprights of that side frame the view.
      const lean = 0.12 + 0.62 * down;
      // In the basket's own frame (it turns slowly with the balloon).
      const ly = c.lyaw - basketYaw;
      const lx = -Math.sin(ly), lz = -Math.cos(ly);
      const side = Math.abs(lx) > Math.abs(lz) ? [Math.sign(lx), 0] : [0, Math.sign(lz)];
      // Toward one corner of that side, so its upright and flying wires stand at the frame edge.
      const along = 0.3 * down;
      const eye = new THREE.Vector3(side[0] * lean + side[1] * along, 1.52 + 0.22 * down, side[1] * lean - side[0] * along);
      eye.applyMatrix4(basket);
      cam.position.copy(eye);
      const cp = Math.cos(c.lpitch);
      const dir = new THREE.Vector3(-Math.sin(c.lyaw) * cp, Math.sin(c.lpitch), -Math.cos(c.lyaw) * cp);
      cam.up.set(0, 1, 0);
      cam.lookAt(eye.add(dir));
      near = 0.06;
      fov = 72;
    }
    if (cam.near !== near || cam.fov !== fov) {
      cam.near = near;
      cam.fov = fov;
      cam.updateProjectionMatrix();
    }
  }

  /** Point the chase camera so it looks from behind the balloon toward heading `dir` (x, z). */
  behind(dirX: number, dirZ: number): void {
    this.chase.yaw = Math.atan2(-dirX, -dirZ);
  }
}
