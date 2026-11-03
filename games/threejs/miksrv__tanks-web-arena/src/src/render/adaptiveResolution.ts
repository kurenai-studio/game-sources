import type * as THREE from 'three'

const WINDOW_FRAMES = 60
const STEP = 0.125
/** Frames this much longer than the target on average (≈ 30 % missed vsyncs at 60 Hz) lower the scale. */
const SLOW_RATIO = 1.3
/** Within 5 % of the target on average: room to raise the scale again. */
const CLEAN_RATIO = 1.05
const COOLDOWN_AFTER_DROP = 1.5
const MAX_RETRY = 90

/**
 * Dynamic resolution. Compares the average frame time of one-second windows with the frame-rate target; a slow
 * window lowers the render scale a notch, a clean one raises it again after a back-off, so the picture is as sharp
 * as the GPU allows without stutter. Averages work on any refresh rate: on a 144 Hz panel paced to 60 fps the gaps
 * alternate between two and three refreshes, which no per-frame threshold could tell from a missed vsync.
 * Still slow at the lowest scale → `onLowestScaleTooSlow` fires once (the game drops the shadow map size).
 */
export class AdaptiveResolution {
	private current: number
	private frames = 0
	private spent = 0
	private budget = 0
	private cooldown = 2
	private retry = 6
	private lowShadow = false

	constructor(
		private readonly renderer: THREE.WebGLRenderer,
		private readonly max: number,
		private readonly min: number,
		private readonly onLowestScaleTooSlow: () => void,
	) {
		this.current = max
	}

	get scale() {
		return this.current
	}

	/** Feed the raw (unscaled) time since the previous rendered frame and the frame-rate target, both per frame. */
	update(raw: number, targetFps: number) {
		this.frames++
		this.spent += raw
		this.budget += 1 / targetFps
		this.cooldown -= raw
		if (this.frames < WINDOW_FRAMES) return
		const ratio = this.spent / this.budget
		this.frames = this.spent = this.budget = 0
		if (this.cooldown > 0) return
		if (ratio > SLOW_RATIO && this.current > this.min) {
			this.setScale(Math.max(this.min, this.current - STEP))
			this.cooldown = COOLDOWN_AFTER_DROP
			this.retry = Math.min(MAX_RETRY, this.retry * 2)
		} else if (ratio > SLOW_RATIO && !this.lowShadow) {
			this.lowShadow = true
			this.cooldown = COOLDOWN_AFTER_DROP
			this.onLowestScaleTooSlow()
		} else if (ratio < CLEAN_RATIO && this.current < this.max) {
			this.setScale(Math.min(this.max, this.current + STEP))
			this.cooldown = this.retry
		}
	}

	private setScale(v: number) {
		this.current = v
		this.renderer.setPixelRatio(v)
	}
}
