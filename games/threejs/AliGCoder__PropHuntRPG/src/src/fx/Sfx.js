/**
 * Tiny procedural sound effects with WebAudio – no audio assets needed.
 * Positional falloff is approximated by distance to the listener.
 */
export class Sfx {

	constructor() {

		this.ctx = null;
		this.volume = 0.35;
		this.listener = { x: 0, y: 0, z: 0 };

	}

	#ensure() {

		if ( ! this.ctx ) {

			const AC = globalThis.AudioContext || globalThis.webkitAudioContext;
			if ( ! AC ) return null;
			this.ctx = new AC();

		}

		if ( this.ctx.state === 'suspended' ) this.ctx.resume();
		return this.ctx;

	}

	setListener( pos ) {

		this.listener.x = pos.x;
		this.listener.y = pos.y;
		this.listener.z = pos.z;

	}

	#gainFor( pos ) {

		if ( ! pos ) return this.volume;
		const d = Math.hypot( pos[ 0 ] - this.listener.x, pos[ 1 ] - this.listener.y, pos[ 2 ] - this.listener.z );
		return this.volume * Math.max( 0, 1 - d / 45 );

	}

	#tone( { freq = 440, endFreq = freq, type = 'sine', duration = 0.15, gain = 1, pos = null, delay = 0 } ) {

		const ctx = this.#ensure();
		if ( ! ctx ) return;
		const g = this.#gainFor( pos ) * gain;
		if ( g <= 0.001 ) return;
		const t0 = ctx.currentTime + delay;
		const osc = ctx.createOscillator();
		const amp = ctx.createGain();
		osc.type = type;
		osc.frequency.setValueAtTime( freq, t0 );
		osc.frequency.exponentialRampToValueAtTime( Math.max( 20, endFreq ), t0 + duration );
		amp.gain.setValueAtTime( g, t0 );
		amp.gain.exponentialRampToValueAtTime( 0.0001, t0 + duration );
		osc.connect( amp ).connect( ctx.destination );
		osc.start( t0 );
		osc.stop( t0 + duration + 0.02 );

	}

	#noise( { duration = 0.1, gain = 1, pos = null, filter = 1200 } ) {

		const ctx = this.#ensure();
		if ( ! ctx ) return;
		const g = this.#gainFor( pos ) * gain;
		if ( g <= 0.001 ) return;
		const buffer = ctx.createBuffer( 1, Math.ceil( ctx.sampleRate * duration ), ctx.sampleRate );
		const data = buffer.getChannelData( 0 );
		for ( let i = 0; i < data.length; i ++ ) data[ i ] = ( Math.random() * 2 - 1 ) * ( 1 - i / data.length );
		const src = ctx.createBufferSource();
		src.buffer = buffer;
		const bp = ctx.createBiquadFilter();
		bp.type = 'bandpass';
		bp.frequency.value = filter;
		const amp = ctx.createGain();
		amp.gain.value = g;
		src.connect( bp ).connect( amp ).connect( ctx.destination );
		src.start();

	}

	swing( pos ) {

		this.#noise( { duration: 0.12, gain: 0.5, pos, filter: 2500 } );

	}

	chop( pos, skill ) {

		const f = { woodcutting: 380, mining: 1400, fishing: 600 }[ skill ] ?? 500;
		this.#noise( { duration: 0.08, gain: 1, pos, filter: f } );
		this.#tone( { freq: f * 0.6, endFreq: f * 0.3, type: 'triangle', duration: 0.1, gain: 0.5, pos } );

	}

	hit( pos ) {

		this.#tone( { freq: 220, endFreq: 90, type: 'square', duration: 0.15, gain: 0.5, pos } );

	}

	hurt() {

		this.#tone( { freq: 300, endFreq: 120, type: 'sawtooth', duration: 0.2, gain: 0.4 } );

	}

	eliminated( pos ) {

		[ 520, 390, 260 ].forEach( ( f, i ) => this.#tone( { freq: f, type: 'triangle', duration: 0.18, gain: 0.6, pos, delay: i * 0.09 } ) );

	}

	taunt( pos ) {

		[ 660, 880, 740, 990 ].forEach( ( f, i ) => this.#tone( { freq: f, type: 'square', duration: 0.1, gain: 0.35, pos, delay: i * 0.08 } ) );

	}

	forage( pos ) {

		this.#tone( { freq: 900, endFreq: 1300, type: 'sine', duration: 0.12, gain: 0.45, pos } );

	}

	ability( pos ) {

		this.#tone( { freq: 200, endFreq: 800, type: 'sine', duration: 0.4, gain: 0.5, pos } );

	}

	levelUp() {

		[ 523, 659, 784, 1047 ].forEach( ( f, i ) => this.#tone( { freq: f, type: 'triangle', duration: 0.25, gain: 0.5, delay: i * 0.1 } ) );

	}

	xp() {

		this.#tone( { freq: 1200, endFreq: 1600, type: 'sine', duration: 0.08, gain: 0.25 } );

	}

	click() {

		this.#tone( { freq: 700, type: 'triangle', duration: 0.05, gain: 0.3 } );

	}

}
