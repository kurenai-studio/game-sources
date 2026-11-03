import type { Tank } from '../tank/tank'
import type { Particles } from './particles'

const jitter = (k: number) => (Math.random() - 0.5) * k

/** Per-frame particles of one tank: wreck smoke, engine fire, track dust and exhaust. */
export function emitTankFx(particles: Particles, t: Tank, dt: number) {
	if (!t.alive) {
		if (Math.random() < 2.5 * dt) {
			particles.smoke(t.pos.x + jitter(2), t.pos.y + t.view.hullTop + 0.5, t.pos.z + jitter(2), 1.5)
		}
		return
	}
	if (t.burning > 0 && Math.random() < 14 * dt) {
		particles.fire(t.pos.x - t.fx * 1.5, t.pos.y + t.view.hullTop, t.pos.z - t.fz * 1.5)
	}
	const sp = Math.abs(t.speed)
	if (sp > 2 && Math.random() < sp * 1.2 * dt) {
		const side = Math.random() < 0.5 ? 1 : -1
		const w = t.def.shape.hullW / 2
		particles.dust(
			t.pos.x - t.fx * 2 + t.fz * side * w,
			t.pos.y,
			t.pos.z - t.fz * 2 - t.fx * side * w,
			-t.fx * t.speed,
			-t.fz * t.speed,
			Math.min(1, sp / 12),
		)
	}
	if (Math.random() < (1 + Math.abs(t.throttle) * 6) * dt) {
		const back = t.def.shape.hullL * 0.5
		particles.exhaust(t.pos.x - t.fx * back, t.pos.y + t.view.hullTop - 0.3, t.pos.z - t.fz * back)
	}
}
