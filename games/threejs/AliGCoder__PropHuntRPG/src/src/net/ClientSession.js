import { EventEmitter } from '../core/EventEmitter.js';
import { C2S, S2C, EV, PHASES } from './protocol.js';

/**
 * Client-side mirror of the host's game state plus typed helpers for sending
 * intents. Identical whether the host is local (single player / you're the
 * host) or remote over WebRTC.
 *
 * Events emitted:
 *   'welcome'               – first full state received
 *   'snapshot'              – players / phase updated
 *   'event' (ev)            – every host event
 *   `ev:<name>` (ev)        – the same, by name
 *   'error' (message)
 *   'disconnected'
 */
export class ClientSession extends EventEmitter {

	constructor( send, profile ) {

		super();
		this.transportSend = send;
		this.profile = profile;
		this.you = null;
		this.hostId = null;
		this.seed = null;
		this.phase = PHASES.LOBBY;
		this.round = 0;
		this.timeLeft = 0;
		this.players = new Map();
		this.depleted = new Set();
		this.decoys = new Map();
		this.connected = false;

	}

	get me() {

		return this.players.get( this.you ) ?? null;

	}

	get isHost() {

		return this.you !== null && this.you === this.hostId;

	}

	hello() {

		this.#send( { t: C2S.HELLO, profile: this.profile } );

	}

	// ── inbound ─────────────────────────────────────────────────────────────

	receive( msg ) {

		switch ( msg?.t ) {

			case S2C.WELCOME:
				this.you = msg.you;
				this.hostId = msg.hostId;
				this.seed = msg.seed;
				this.connected = true;
				this.#applyState( msg.state );
				for ( const i of msg.state.depleted ?? [] ) this.depleted.add( i );
				for ( const d of msg.state.decoys ?? [] ) this.decoys.set( d.id, d );
				this.emit( 'welcome', msg );
				break;

			case S2C.SNAPSHOT:
				this.#applyState( msg );
				this.emit( 'snapshot', msg );
				break;

			case S2C.EVENT:
				this.#applyEvent( msg );
				this.emit( 'event', msg );
				this.emit( 'ev:' + msg.e, msg );
				break;

			case S2C.ERROR:
				this.emit( 'error', msg.message );
				break;

		}

	}

	#applyState( s ) {

		this.phase = s.phase;
		this.round = s.round;
		this.timeLeft = s.timeLeft;
		const seen = new Set();
		for ( const p of s.players ) {

			seen.add( p.id );
			const existing = this.players.get( p.id );
			if ( existing ) Object.assign( existing, p );
			else this.players.set( p.id, { ...p } );

		}

		for ( const id of this.players.keys() ) if ( ! seen.has( id ) ) this.players.delete( id );

	}

	#applyEvent( ev ) {

		switch ( ev.e ) {

			case EV.PHASE:
				this.phase = ev.phase;
				this.round = ev.round;
				this.timeLeft = ev.timeLeft;
				if ( ev.phase === PHASES.PREP ) {

					this.depleted.clear();
					this.decoys.clear();

				}

				break;
			case EV.GATHER: if ( ev.depleted ) this.depleted.add( ev.index ); break;
			case EV.NODE_RESPAWN: this.depleted.delete( ev.index ); break;
			case EV.DECOY: this.decoys.set( ev.decoy.id, ev.decoy ); break;
			case EV.DECOY_REMOVED: this.decoys.delete( ev.id ); break;
			case EV.DISGUISED: {

				const p = this.players.get( ev.id );
				if ( p ) p.disguise = ev.type;
				break;

			}

			case EV.DAMAGE: {

				const p = this.players.get( ev.id );
				if ( p ) p.hp = ev.hp;
				break;

			}

			case EV.ELIMINATED: {

				const p = this.players.get( ev.id );
				if ( p ) p.alive = false;
				break;

			}

			case EV.TELEPORT: {

				const p = this.players.get( ev.id );
				if ( p ) {

					p.pos = ev.pos;
					p.yaw = ev.yaw;

				}

				break;

			}

		}

	}

	/** Advance the local countdown between snapshots. */
	update( dt ) {

		if ( this.phase !== PHASES.LOBBY ) this.timeLeft = Math.max( 0, this.timeLeft - dt );

	}

	// ── outbound intents ────────────────────────────────────────────────────

	#send( msg ) {

		this.transportSend( msg );

	}

	sendPosition( pos, yaw ) {

		this.#send( { t: C2S.POS, p: [ round3( pos.x ), round3( pos.y ), round3( pos.z ) ], yaw: round3( yaw ) } );

	}

	updateLevels( levels ) {

		this.#send( { t: C2S.PROFILE, levels } );

	}

	setTrade( trade ) {

		this.#send( { t: C2S.TRADE, trade } );

	}

	toggleReady() {

		this.#send( { t: C2S.READY } );

	}

	startGame() {

		this.#send( { t: C2S.START } );

	}

	addBot() {

		this.#send( { t: C2S.ADD_BOT } );

	}

	removeBot() {

		this.#send( { t: C2S.REMOVE_BOT } );

	}

	disguise( type, index ) {

		this.#send( { t: C2S.DISGUISE, type, index } );

	}

	hit( kind, id ) {

		this.#send( { t: C2S.HIT, kind, id } );

	}

	forage( index ) {

		this.#send( { t: C2S.FORAGE, index } );

	}

	useAbility( origin, dir ) {

		this.#send( { t: C2S.ABILITY, origin, dir } );

	}

	taunt() {

		this.#send( { t: C2S.TAUNT } );

	}

	disconnect() {

		this.connected = false;
		this.emit( 'disconnected' );

	}

}

const round3 = ( v ) => Math.round( v * 1000 ) / 1000;
