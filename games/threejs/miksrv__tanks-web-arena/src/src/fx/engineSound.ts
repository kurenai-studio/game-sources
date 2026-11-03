export type NoiseKind = 'white' | 'brown'

// Diesel drone (detuned saws and a sub, overdriven, chugging at the firing rate), a low mechanical rumble
// and track clatter pulsed by the link rate. Runs for the whole session; `update` steers it every frame.
export class EngineSound {
	private readonly oscs: { o: OscillatorNode; ratio: number }[]
	private readonly chug: OscillatorNode
	private readonly filter: BiquadFilterNode
	private readonly gain: GainNode
	private readonly rumble: GainNode
	private readonly clank: OscillatorNode
	private readonly tracks: GainNode

	constructor(ctx: AudioContext, out: AudioNode, noise: Record<NoiseKind, AudioBuffer>) {
		const shaper = ctx.createWaveShaper()
		const curve = new Float32Array(1024)
		for (let i = 0; i < curve.length; i++) curve[i] = Math.tanh(2.5 * ((i / (curve.length - 1)) * 2 - 1))
		shaper.curve = curve
		this.filter = ctx.createBiquadFilter()
		this.filter.type = 'lowpass'
		this.filter.frequency.value = 200
		this.filter.Q.value = 0.9
		// The chug: amplitude modulation of the drone
		const am = ctx.createGain()
		am.gain.value = 0.65
		this.chug = ctx.createOscillator()
		this.chug.frequency.value = 12
		const depth = ctx.createGain()
		depth.gain.value = 0.35
		this.chug.connect(depth).connect(am.gain)
		this.gain = ctx.createGain()
		this.gain.gain.value = 0
		shaper.connect(this.filter).connect(am).connect(this.gain).connect(out)
		this.oscs = (
			[
				['sawtooth', 1],
				['sawtooth', 1.007],
				['square', 0.5],
			] as const
		).map(([type, ratio]) => {
			const o = ctx.createOscillator()
			o.type = type
			o.frequency.value = 35 * ratio
			const g = ctx.createGain()
			g.gain.value = type === 'square' ? 0.5 : 0.35
			o.connect(g).connect(shaper)
			return { o, ratio }
		})
		const rumbleSrc = loop(ctx, noise.brown)
		const rumbleLp = ctx.createBiquadFilter()
		rumbleLp.type = 'lowpass'
		rumbleLp.frequency.value = 160
		this.rumble = ctx.createGain()
		this.rumble.gain.value = 0
		rumbleSrc.connect(rumbleLp).connect(this.rumble).connect(out)
		const trackSrc = loop(ctx, noise.white)
		const trackBp = ctx.createBiquadFilter()
		trackBp.type = 'bandpass'
		trackBp.frequency.value = 700
		trackBp.Q.value = 1.2
		const trackAm = ctx.createGain()
		trackAm.gain.value = 0.5
		this.clank = ctx.createOscillator()
		this.clank.type = 'square'
		this.clank.frequency.value = 4
		const clankDepth = ctx.createGain()
		clankDepth.gain.value = 0.45
		this.clank.connect(clankDepth).connect(trackAm.gain)
		this.tracks = ctx.createGain()
		this.tracks.gain.value = 0
		trackSrc.connect(trackBp).connect(trackAm).connect(this.tracks).connect(out)
		for (const { o } of this.oscs) o.start()
		this.chug.start()
		this.clank.start()
		rumbleSrc.start()
		trackSrc.start()
	}

	/** Targets are handed to the audio thread as exponential approaches (no zipper noise). */
	update(t: number, throttle: number, speed: number, maxSpeed: number, alive: boolean) {
		const move = Math.min(1, Math.abs(speed) / maxSpeed)
		const load = alive ? 0.2 + 0.8 * Math.min(1, Math.abs(throttle) * 0.6 + move * 0.6) : 0
		const tau = 0.3
		const rpm = 30 + 42 * load
		for (const { o, ratio } of this.oscs) o.frequency.setTargetAtTime(rpm * ratio, t, tau)
		this.chug.frequency.setTargetAtTime(rpm / 3, t, tau)
		this.filter.frequency.setTargetAtTime(160 + 700 * load, t, tau)
		this.gain.gain.setTargetAtTime(alive ? 0.05 + 0.07 * load : 0, t, tau)
		this.rumble.gain.setTargetAtTime(alive ? 0.04 + 0.08 * load : 0, t, tau)
		this.clank.frequency.setTargetAtTime(2 + 14 * move, t, 0.1)
		this.tracks.gain.setTargetAtTime(alive ? 0.06 * move : 0, t, 0.15)
	}
}

function loop(ctx: AudioContext, buffer: AudioBuffer): AudioBufferSourceNode {
	const src = ctx.createBufferSource()
	src.buffer = buffer
	src.loop = true
	return src
}
