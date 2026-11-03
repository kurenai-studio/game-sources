/** A frame may come this early (ms) and still count as on time: rAF stamps jitter. */
const EARLY_SLACK = 2

/**
 * Frame pacing on any refresh rate. Rendering is gated by a schedule that advances by the target interval, so the
 * average rate is the target — 60 fps on 75, 90, 120, 144 Hz panels alike — instead of the panel rate divided by a
 * whole number (a fixed minimum gap gives 144 Hz / 3 = 48 fps and 75 Hz / 2 = 37.5 fps).
 */
export class FramePacer {
	private nextAt = 0

	/** Call on every rAF callback; returns true when this one should simulate and render. */
	shouldRender(now: number, targetFps: number): boolean {
		const interval = 1000 / targetFps
		if (now < this.nextAt - EARLY_SLACK) return false
		// Fell behind by more than a frame (slow frame, hidden tab): resynchronise instead of rushing to catch up
		this.nextAt = now - this.nextAt > interval ? now + interval : this.nextAt + interval
		return true
	}
}

/** Frames per second of simulated time, refreshed twice a second (the P overlay and the debug log). */
export class FpsCounter {
	value = 0
	private acc = 0
	private frames = 0

	count(dt: number) {
		this.acc += dt
		this.frames++
		if (this.acc < 0.5) return
		this.value = Math.round(this.frames / this.acc)
		this.acc = this.frames = 0
	}
}
