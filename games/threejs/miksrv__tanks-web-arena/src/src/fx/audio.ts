import { EngineSound, type NoiseKind } from './engineSound'

/** Where a sound comes from on the map; `null` is the listener's own tank (centred, full volume). */
export type SoundAt = { x: number; z: number } | null

const PAN_WIDTH = 0.8 // a sound straight to the side is not fully in one ear
const PAN_NEAR = 12 // m: closer sounds are pulled toward the centre (they come from all around the hull)
const AIR_FAR = 0.08 // air absorption: lowpass at the edge of a sound's reach, as a fraction of the near cutoff
const SILENT = 0.0001 // floor for exponential envelopes (they cannot reach zero)

// Inharmonic partials of a struck steel plate: armour clangs, breech, debris
const PLATE = [1, 2.32, 4.25, 6.63]

/** A one-shot's entry point: gain-adjusted volume `v` and how far toward the edge of its reach it is (0…1). */
interface Voice {
	node: AudioNode
	v: number
	far: number
}

// Procedural sound: diesel engine and tracks, layered gunfire, armour hits, ricochets, explosions. No assets.
// One-shots are built from noise layers (crack, blast, rumble) and sine partials (sub thump, metal ring),
// fade and darken with distance, are panned by their bearing from the camera and feed a shared outdoor reverb.
export class Audio {
	private ctx: AudioContext | null = null
	private buffers: Record<NoiseKind, AudioBuffer> | null = null
	private master: GainNode | null = null
	private mix: GainNode | null = null
	private reverb: ConvolverNode | null = null
	private engineSound: EngineSound | null = null
	/** The looping rain hiss and the level it should be at (kept even before the context exists). */
	private rainGain: GainNode | null = null
	private rainLevel = 0
	muted = false
	/** Simulation paused: the context is suspended and stays so until `setPaused(false)`. */
	private paused = false
	private readonly ear = { x: 0, z: 0, yaw: 0 }

	constructor() {
		const start = () => {
			this.ensure()
			window.removeEventListener('keydown', start)
			window.removeEventListener('mousedown', start)
		}
		window.addEventListener('keydown', start)
		window.addEventListener('mousedown', start)
		// Browsers suspend the context while the tab is hidden; bring it back when the player returns
		document.addEventListener('visibilitychange', () => {
			if (!document.hidden && !this.paused && this.ctx?.state === 'suspended')
				this.ctx.resume().catch(() => undefined)
		})
	}

	private ensure() {
		if (this.ctx) {
			if (this.ctx.state === 'suspended' && !this.paused) this.ctx.resume().catch(() => undefined)
			return
		}
		const ctx = (this.ctx = new AudioContext())
		this.buffers = { white: this.makeNoise(ctx, 'white'), brown: this.makeNoise(ctx, 'brown') }
		// mix → compressor (several booms at once must not clip) → master (mute) → speakers
		this.master = ctx.createGain()
		this.master.gain.value = this.muted ? 0 : 1
		this.master.connect(ctx.destination)
		const comp = ctx.createDynamicsCompressor()
		comp.threshold.value = -14
		comp.knee.value = 10
		comp.ratio.value = 4
		comp.attack.value = 0.003
		comp.release.value = 0.25
		comp.connect(this.master)
		this.mix = ctx.createGain()
		this.mix.gain.value = 0.8
		this.mix.connect(comp)
		this.reverb = ctx.createConvolver()
		this.reverb.buffer = this.makeImpulse(ctx, 2.6)
		const wet = ctx.createGain()
		wet.gain.value = 0.55
		this.reverb.connect(wet).connect(this.mix)
		this.engineSound = new EngineSound(ctx, this.mix, this.buffers)
		this.startRain(ctx, this.mix, this.buffers.white)
	}

	/** Rain on the hull and the field around: band-limited noise, always running, faded in by `rain()`. */
	private startRain(ctx: AudioContext, out: AudioNode, white: AudioBuffer) {
		const src = ctx.createBufferSource()
		src.buffer = white
		src.loop = true
		const hp = ctx.createBiquadFilter()
		hp.type = 'highpass'
		hp.frequency.value = 900
		const lp = ctx.createBiquadFilter()
		lp.type = 'lowpass'
		lp.frequency.value = 5200
		this.rainGain = ctx.createGain()
		this.rainGain.gain.value = this.rainLevel
		src.connect(hp).connect(lp).connect(this.rainGain).connect(out)
		src.start()
	}

	/** Rain hiss on (0…1 level) or off for this map. */
	rain(level: number) {
		this.rainLevel = level
		if (this.ctx && this.rainGain) this.rainGain.gain.setTargetAtTime(level, this.ctx.currentTime, 0.5)
	}

	/** Two seconds of looping noise: white for cracks and hiss, brown (integrated white) for blasts and rumble. */
	private makeNoise(ctx: AudioContext, kind: NoiseKind): AudioBuffer {
		const len = ctx.sampleRate * 2
		const buf = ctx.createBuffer(1, len, ctx.sampleRate)
		const d = buf.getChannelData(0)
		let last = 0
		for (let i = 0; i < len; i++) {
			const w = Math.random() * 2 - 1
			if (kind === 'white') d[i] = w
			else {
				last = (last + 0.02 * w) / 1.02
				d[i] = last * 3.5
			}
		}
		return buf
	}

	/** Open-field reverb: a short pre-delay, then decaying stereo noise that darkens as it fades. */
	private makeImpulse(ctx: AudioContext, seconds: number): AudioBuffer {
		const rate = ctx.sampleRate
		const len = Math.floor(rate * seconds)
		const pre = Math.floor(rate * 0.025)
		const buf = ctx.createBuffer(2, len, rate)
		for (let ch = 0; ch < 2; ch++) {
			const d = buf.getChannelData(ch)
			let lp = 0
			for (let i = pre; i < len; i++) {
				const t = (i - pre) / rate
				const k = 0.6 * Math.exp(-t * 1.5) + 0.03 // one-pole lowpass coefficient: the tail gets duller
				lp += k * (Math.random() * 2 - 1 - lp)
				d[i] = lp * Math.exp(-t * 2.4)
			}
		}
		return buf
	}

	/** The node a sound connects to: through a stereo panner when off-centre. */
	private panned(ctx: AudioContext, out: AudioNode, pan: number): AudioNode {
		if (Math.abs(pan) < 0.01) return out
		const p = ctx.createStereoPanner()
		p.pan.value = pan
		p.connect(out)
		return p
	}

	/**
	 * Entry chain for a world sound at `at` heard up to `reach` metres: air absorption (distant sounds lose
	 * their crack), panning, and a reverb send that grows with distance. `null` when it is too far to hear.
	 */
	private voice(at: SoundAt, reach: number): Voice | null {
		if (!this.ctx || !this.mix || !this.reverb) return null
		const ctx = this.ctx
		const [v, pan, d] = this.place(at, reach)
		if (v <= 0.01) return null
		const far = Math.min(1, d / reach)
		const air = ctx.createBiquadFilter()
		air.type = 'lowpass'
		air.frequency.value = 16000 * Math.pow(AIR_FAR, Math.sqrt(far))
		air.connect(this.panned(ctx, this.mix, pan))
		const send = ctx.createGain()
		send.gain.value = 0.15 + 0.6 * far
		air.connect(send).connect(this.reverb)
		return { node: air, v, far }
	}

	/** Filtered noise with a fast attack and exponential decay; the filter can sweep to `freqEnd`. */
	private noise(
		out: AudioNode,
		kind: NoiseKind,
		delay: number,
		gain: number,
		dur: number,
		type: BiquadFilterType,
		freq: number,
		freqEnd = freq,
		q = 0.7,
		attack = 0.002,
	) {
		if (!this.ctx || !this.buffers || gain <= 0) return
		const t = this.ctx.currentTime + delay
		const src = this.ctx.createBufferSource()
		src.buffer = this.buffers[kind]
		src.loop = true
		src.playbackRate.value = 0.9 + Math.random() * 0.2
		const f = this.ctx.createBiquadFilter()
		f.type = type
		f.Q.value = q
		f.frequency.setValueAtTime(freq, t)
		if (freqEnd !== freq) f.frequency.exponentialRampToValueAtTime(freqEnd, t + dur)
		const g = this.ctx.createGain()
		g.gain.setValueAtTime(SILENT, t)
		g.gain.linearRampToValueAtTime(gain, t + attack)
		g.gain.exponentialRampToValueAtTime(SILENT, t + dur)
		src.connect(f).connect(g).connect(out)
		src.start(t, Math.random() * 1.5)
		src.stop(t + dur + 0.05)
	}

	/** One oscillator partial; `slide` is the pitch ratio reached at the end. */
	private partial(
		out: AudioNode,
		delay: number,
		freq: number,
		gain: number,
		dur: number,
		slide = 1,
		type: OscillatorType = 'sine',
		attack = 0.002,
	) {
		if (!this.ctx || gain <= 0) return
		const t = this.ctx.currentTime + delay
		const o = this.ctx.createOscillator()
		o.type = type
		o.frequency.setValueAtTime(freq, t)
		if (slide !== 1) o.frequency.exponentialRampToValueAtTime(Math.max(15, freq * slide), t + dur)
		const g = this.ctx.createGain()
		g.gain.setValueAtTime(SILENT, t)
		g.gain.linearRampToValueAtTime(gain, t + attack)
		g.gain.exponentialRampToValueAtTime(SILENT, t + dur)
		o.connect(g).connect(out)
		o.start(t)
		o.stop(t + dur + 0.05)
	}

	/** A struck steel plate: inharmonic partials, the higher ones dying first. */
	private ring(out: AudioNode, delay: number, base: number, gain: number, dur: number) {
		PLATE.forEach((r, i) => {
			const f = base * r * (0.98 + Math.random() * 0.04)
			this.partial(out, delay, f, gain / (1 + i * 0.8), dur / (1 + i * 0.7))
		})
	}

	/** The listener: the followed tank's position and the camera heading (forward = (sin yaw, cos yaw)). */
	listen(x: number, z: number, yaw: number) {
		this.ear.x = x
		this.ear.z = z
		this.ear.yaw = yaw
	}

	/** Volume (1 at the listener, 0 at `reach` metres), stereo pan (−1 left … 1 right) and distance of `at`. */
	private place(at: SoundAt, reach: number): [number, number, number] {
		if (!at) return [1, 0, 0]
		const dx = at.x - this.ear.x
		const dz = at.z - this.ear.z
		const d = Math.hypot(dx, dz)
		if (d < 1e-3) return [1, 0, 0]
		// Screen right is (−cos yaw, sin yaw)
		const side = (-dx * Math.cos(this.ear.yaw) + dz * Math.sin(this.ear.yaw)) / d
		const v = Math.max(0, 1 - d / reach)
		return [v * v * 0.6 + v * 0.4, side * PAN_WIDTH * Math.min(1, d / PAN_NEAR), d]
	}

	/** Cannon: supersonic crack, muzzle blast, sub-bass thump and a rolling echo; bigger guns are lower and longer. */
	shot(caliber: number, at: SoundAt) {
		const s = this.voice(at, 1000)
		if (!s) return
		const k = Math.min(1.6, Math.max(0.5, caliber / 85))
		const v = s.v * Math.min(1.25, 0.55 + 0.45 * k)
		const near = 1 - s.far
		this.noise(s.node, 'white', 0, 0.55 * v * near, 0.07, 'highpass', 1800, 1800, 0.5, 0.001)
		this.noise(s.node, 'brown', 0, 1.1 * v, 0.35 + 0.35 * k, 'lowpass', 2400 / k, 110, 0.6, 0.002)
		this.partial(s.node, 0, 95 / Math.sqrt(k), 0.9 * v, 0.25 + 0.2 * k, 0.35)
		this.noise(s.node, 'brown', 0.12, 0.35 * v, 1.0 + 0.6 * k, 'lowpass', 380, 90, 0.5, 0.15)
		if (!at) {
			// Inside the turret: recoil and the breech kicking back
			this.ring(s.node, 0.04, 170 / Math.sqrt(k), 0.07, 0.35)
			this.noise(s.node, 'white', 0.05, 0.12, 0.05, 'bandpass', 2600, 2600, 2)
		}
	}

	/** Rocket leaving the rails: a sharp ignition and a roaring hiss that tears away. */
	rocket(at: SoundAt) {
		const s = this.voice(at, 800)
		if (!s) return
		const v = s.v
		this.noise(s.node, 'white', 0, 0.35 * v * (1 - s.far), 0.05, 'highpass', 2000, 2000, 0.5, 0.001)
		this.noise(s.node, 'white', 0, 0.45 * v, 1.0, 'bandpass', 2600, 600, 1.1, 0.03)
		this.noise(s.node, 'brown', 0, 0.6 * v, 0.9, 'lowpass', 500, 120, 0.6, 0.02)
	}

	hit(at: SoundAt, penetrated: boolean, ricochet: boolean) {
		const s = this.voice(at, 600)
		if (!s) return
		const v = s.v
		if (ricochet) {
			// A glancing ping and the shell whirring off
			this.noise(s.node, 'white', 0, 0.3 * v, 0.04, 'bandpass', 3500, 3500, 1.5, 0.001)
			this.ring(s.node, 0, 760, 0.16 * v, 0.4)
			this.noise(s.node, 'white', 0.02, 0.25 * v, 0.45, 'bandpass', 3800, 900, 7, 0.03)
			return
		}
		if (penetrated) {
			// Dull, heavy crunch of a shell going through
			this.noise(s.node, 'brown', 0, 1.0 * v, 0.45, 'lowpass', 1400, 140, 0.8, 0.002)
			this.partial(s.node, 0, 80, 0.7 * v, 0.3, 0.45)
			this.noise(s.node, 'white', 0, 0.35 * v, 0.22, 'bandpass', 1300, 500, 0.8, 0.002)
			this.ring(s.node, 0.01, 130, 0.22 * v, 0.5)
			return
		}
		// Bounced off the armour: a hard clang that rings on
		this.noise(s.node, 'white', 0, 0.45 * v, 0.05, 'bandpass', 2800, 2800, 1, 0.001)
		this.noise(s.node, 'brown', 0, 0.6 * v, 0.18, 'lowpass', 900, 200, 0.7, 0.002)
		this.ring(s.node, 0, 240, 0.32 * v, 0.8)
	}

	/** A shell striking the ground: a thud, and for big HE a blast with dirt raining down. */
	impact(at: SoundAt, big: boolean) {
		const s = this.voice(at, big ? 900 : 500)
		if (!s) return
		const v = s.v
		if (!big) {
			this.noise(s.node, 'brown', 0, 0.5 * v, 0.3, 'lowpass', 800, 150, 0.7, 0.002)
			this.noise(s.node, 'white', 0, 0.15 * v, 0.06, 'bandpass', 1800, 1800, 1, 0.001)
			return
		}
		this.noise(s.node, 'white', 0, 0.4 * v * (1 - s.far), 0.08, 'highpass', 1200, 1200, 0.5, 0.001)
		this.noise(s.node, 'brown', 0, 1.1 * v, 1.0, 'lowpass', 1600, 90, 0.6, 0.002)
		this.partial(s.node, 0, 65, 0.8 * v, 0.6, 0.4)
		this.noise(s.node, 'white', 0.1, 0.1 * v, 0.7, 'highpass', 1500, 3000, 0.5, 0.15)
	}

	/** A tank brewing up: blast, the ammunition going a beat later, scattering debris. */
	explosion(at: SoundAt) {
		const s = this.voice(at, 1400)
		if (!s) return
		const v = s.v
		this.noise(s.node, 'white', 0, 0.5 * v * (1 - s.far), 0.12, 'highpass', 1000, 1000, 0.5, 0.001)
		this.noise(s.node, 'brown', 0, 1.3 * v, 2.2, 'lowpass', 1800, 70, 0.6, 0.003)
		this.partial(s.node, 0, 60, 1.0 * v, 1.4, 0.35)
		this.noise(s.node, 'brown', 0.2, 0.8 * v, 1.6, 'lowpass', 900, 60, 0.6, 0.01)
		this.partial(s.node, 0.2, 48, 0.6 * v, 1.0, 0.4)
		this.ring(s.node, 0.35, 160, 0.12 * v, 0.9)
		for (let i = 0; i < 6; i++) {
			const d = 0.3 + Math.random() * 1.2
			const f = 1500 + Math.random() * 2000
			this.noise(s.node, 'white', d, 0.12 * v * Math.random(), 0.04, 'bandpass', f, f, 2)
		}
	}

	/** The gun is loaded again: the breech block slams shut. */
	reloaded() {
		const out = this.mix
		if (!out) return
		this.noise(out, 'white', 0, 0.2, 0.03, 'bandpass', 3200, 3200, 2, 0.001)
		this.noise(out, 'brown', 0.03, 0.45, 0.1, 'lowpass', 700, 200, 0.8, 0.001)
		this.ring(out, 0.03, 420, 0.06, 0.22)
	}
	/** The reticle has converged: a soft, high double tick. */
	aimed() {
		const out = this.mix
		if (!out) return
		this.partial(out, 0, 1480, 0.035, 0.05)
		this.partial(out, 0.06, 1980, 0.03, 0.07)
	}
	/** A dry mechanical tick: ammo switch, gun not ready. */
	click() {
		const out = this.mix
		if (!out) return
		this.noise(out, 'white', 0, 0.16, 0.025, 'bandpass', 2400, 2400, 3, 0.001)
		this.noise(out, 'brown', 0, 0.2, 0.04, 'lowpass', 500, 500, 0.7, 0.001)
	}
	/** "Sixth sense": the enemy has just spotted the player. A low, soft bell. */
	spotted() {
		const out = this.mix
		if (!out) return
		this.partial(out, 0, 392, 0.1, 0.9, 1, 'sine', 0.01)
		this.partial(out, 0, 392 * 2.01, 0.035, 0.5, 1, 'sine', 0.01)
		this.partial(out, 0.12, 587, 0.07, 0.8, 1, 'sine', 0.01)
	}
	/** The player's tank is on fire: two pulses of a muffled buzzer. */
	alarm() {
		if (!this.ctx || !this.mix) return
		const lp = this.ctx.createBiquadFilter()
		lp.type = 'lowpass'
		lp.frequency.value = 900
		lp.connect(this.mix)
		for (const d of [0, 0.2]) {
			this.partial(lp, d, 220, 0.12, 0.15, 1, 'square', 0.01)
			this.partial(lp, d, 277, 0.08, 0.15, 1, 'square', 0.01)
		}
	}

	/** Per-frame engine note. */
	engine(throttle: number, speed: number, maxSpeed: number, alive: boolean, _dt: number) {
		if (this.ctx && this.engineSound)
			this.engineSound.update(this.ctx.currentTime, throttle, speed, maxSpeed, alive)
	}
	/** Pause: everything falls silent (engine included) and resumes where it stopped. */
	setPaused(on: boolean) {
		if (this.paused === on) return
		this.paused = on
		if (!this.ctx) return
		const r = on ? this.ctx.suspend() : this.ctx.resume()
		r.catch(() => undefined)
	}
	toggleMute(): boolean {
		this.muted = !this.muted
		if (this.master) this.master.gain.value = this.muted ? 0 : 1
		return this.muted
	}
}
