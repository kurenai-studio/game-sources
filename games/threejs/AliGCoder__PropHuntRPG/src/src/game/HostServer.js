import { CONFIG } from '../config.js';
import { createRng } from '../core/random.js';
import { MapLayout } from '../world/MapLayout.js';
import { PROP_TYPES } from '../world/PropCatalog.js';
import { C2S, S2C, EV, PHASES } from '../net/protocol.js';
import { clampLevels, bestTrade, TRADES } from '../skills/skills.js';
import {
	BALANCE, canDisguiseAs, hiderMaxHp, toolDamage, abilityCooldown,
	agilitySpeed, toolGathers, canForage, hunterCount
} from './rules.js';
import { getAbility } from './abilities.js';
import { BotBrain, BOT_NAMES } from './Bots.js';

/**
 * The authoritative game simulation. Runs only on the lobby host (or locally
 * in single player). Transport-agnostic: clients are just `send` callbacks,
 * and incoming messages arrive through `onMessage(id, msg)`.
 *
 * Contains no rendering code and no three.js imports.
 */
export class HostServer {

	constructor( { seed, hostId } ) {

		this.seed = seed;
		this.hostId = hostId;
		this.layout = new MapLayout( seed );
		this.rng = createRng( seed ^ 0xabcdef );

		this.clients = new Map();     // id -> send(msg)
		this.players = new Map();     // id -> player state
		this.bots = new Map();        // id -> BotBrain

		this.phase = PHASES.LOBBY;
		this.round = 0;
		this.phaseTime = 0;
		this.time = 0;

		this.depleted = new Map();    // prop index -> respawn time
		this.nodeHits = new Map();    // prop index -> hits taken
		this.decoys = new Map();      // decoy id -> decoy
		this.nextDecoyId = 1;
		this.nextBotId = 1;
		this.snapshotAccumulator = 0;

	}

	// ── connection management ───────────────────────────────────────────────

	addClient( id, send ) {

		this.clients.set( id, send );

	}

	removeClient( id ) {

		this.clients.delete( id );
		const p = this.players.get( id );
		if ( ! p ) return;
		this.players.delete( id );
		this.#broadcastEvent( EV.LEFT, { id, name: p.name } );
		if ( this.phase !== PHASES.LOBBY ) this.#checkWin();

	}

	// ── message routing ─────────────────────────────────────────────────────

	onMessage( id, msg ) {

		if ( ! msg || typeof msg.t !== 'string' ) return;
		if ( msg.t === C2S.HELLO ) return this.#onHello( id, msg );

		const p = this.players.get( id );
		if ( ! p ) return;

		switch ( msg.t ) {

			case C2S.PROFILE: return this.#onProfile( p, msg );
			case C2S.TRADE: return this.#onTrade( p, msg );
			case C2S.READY: p.ready = ! p.ready; return;
			case C2S.START: return id === this.hostId && this.startRound();
			case C2S.ADD_BOT: return id === this.hostId && this.addBot();
			case C2S.REMOVE_BOT: return id === this.hostId && this.removeBot();
			case C2S.POS: return this.#onPos( p, msg );
			case C2S.DISGUISE: return this.#onDisguise( p, msg );
			case C2S.HIT: return this.#onHit( p, msg );
			case C2S.FORAGE: return this.#onForage( p, msg );
			case C2S.ABILITY: return this.#onAbility( p, msg );
			case C2S.TAUNT: return this.#onTaunt( p );

		}

	}

	#onHello( id, msg ) {

		const profile = msg.profile ?? {};
		const levels = clampLevels( profile.levels );
		const player = this.#createPlayer( id, profile.name, levels, profile.trade, false );
		this.players.set( id, player );

		this.#send( id, {
			t: S2C.WELCOME,
			you: id,
			hostId: this.hostId,
			seed: this.seed,
			state: this.#fullState()
		} );
		this.#broadcastEvent( EV.JOINED, { id, name: player.name } );

	}

	#createPlayer( id, name, levels, trade, isBot ) {

		const spawn = this.layout.hunterSpawn;
		return {
			id,
			name: String( name || 'Player' ).replace( /[<>]/g, '' ).slice( 0, 16 ),
			isBot,
			levels,
			trade: TRADES.includes( trade ) ? trade : bestTrade( levels ),
			team: null,
			alive: this.phase === PHASES.LOBBY,
			ready: isBot,
			hp: BALANCE.hiderBaseHp,
			maxHp: BALANCE.hiderBaseHp,
			pos: [ spawn.x + this.rng.range( - 3, 3 ), this.layout.groundAt( spawn.x, spawn.z ), spawn.z + this.rng.range( - 3, 3 ) ],
			yaw: 0,
			disguise: null,
			kills: 0,
			hunterRounds: 0,
			// host-only bookkeeping
			lastPosTime: this.time,
			distance: 0,
			swingReadyAt: 0,
			abilityReadyAt: 0,
			disguiseReadyAt: 0,
			forageReadyAt: 0,
			tauntReadyAt: 0,
			rootedUntil: 0,
			speedUntil: 0,
			lastDamagedAt: - 99
		};

	}

	#onProfile( p, msg ) {

		const ratio = p.hp / p.maxHp;
		p.levels = clampLevels( msg.levels );
		if ( p.team === 'hider' && p.disguise ) {

			p.maxHp = hiderMaxHp( p.disguise, p.levels );
			p.hp = Math.max( 1, Math.round( p.maxHp * ratio ) );

		}

	}

	#onTrade( p, msg ) {

		if ( this.phase === PHASES.HUNT ) return;
		if ( TRADES.includes( msg.trade ) ) p.trade = msg.trade;

	}

	// ── bots ────────────────────────────────────────────────────────────────

	addBot() {

		if ( this.players.size >= 16 ) return;
		const id = 'bot-' + this.nextBotId ++;
		const lv = () => this.rng.int( 1, 35 );
		const levels = clampLevels( { woodcutting: lv(), mining: lv(), fishing: lv(), agility: lv() } );
		const name = '🤖 ' + BOT_NAMES[ ( this.nextBotId - 2 ) % BOT_NAMES.length ];
		const bot = this.#createPlayer( id, name, levels, this.rng.pick( TRADES ), true );
		this.players.set( id, bot );
		this.bots.set( id, new BotBrain( id, this, createRng( this.seed + this.nextBotId * 977 ) ) );
		this.#broadcastEvent( EV.JOINED, { id, name: bot.name } );

	}

	removeBot() {

		const ids = [ ...this.bots.keys() ];
		const id = ids[ ids.length - 1 ];
		if ( ! id ) return;
		this.bots.delete( id );
		this.removeClient( id );

	}

	// ── round flow ──────────────────────────────────────────────────────────

	startRound() {

		if ( this.players.size < CONFIG.round.minPlayers ) {

			this.#send( this.hostId, { t: S2C.ERROR, message: `Need at least ${CONFIG.round.minPlayers} players (add a bot!)` } );
			return;

		}

		this.round ++;
		this.decoys.clear();
		this.depleted.clear();
		this.nodeHits.clear();

		// Team assignment: whoever has hunted least hunts next
		const list = [ ...this.players.values() ].sort( ( a, b ) => a.hunterRounds - b.hunterRounds || this.rng() - 0.5 );
		const hunters = hunterCount( list.length );
		list.forEach( ( p, i ) => {

			p.team = i < hunters ? 'hunter' : 'hider';
			if ( p.team === 'hunter' ) p.hunterRounds ++;
			p.alive = true;
			p.disguise = null;
			p.hp = p.maxHp = p.team === 'hunter' ? BALANCE.hunterBaseHp : BALANCE.hiderBaseHp;
			p.kills = 0;
			p.distance = 0;
			p.abilityReadyAt = p.disguiseReadyAt = p.forageReadyAt = p.rootedUntil = p.speedUntil = 0;

			const spot = p.team === 'hunter'
				? { x: this.layout.hunterSpawn.x + this.rng.range( - 2.5, 2.5 ), z: this.layout.hunterSpawn.z + this.rng.range( - 2.5, 2.5 ) }
				: this.layout.randomLandPoint( this.rng, 12, 32 );
			this.#teleport( p, spot.x, spot.z, this.rng.range( 0, Math.PI * 2 ) );

		} );

		this.#setPhase( PHASES.PREP, CONFIG.round.prepSeconds );
		for ( const bot of this.bots.values() ) bot.onRoundStart();

	}

	#setPhase( phase, seconds ) {

		this.phase = phase;
		this.phaseTime = seconds;
		this.#broadcastEvent( EV.PHASE, { phase, round: this.round, timeLeft: seconds } );
		this.#broadcastSnapshot();

	}

	#endRound( winner ) {

		if ( this.phase !== PHASES.HUNT && this.phase !== PHASES.PREP ) return;
		const X = BALANCE.xp;
		const summary = [];

		for ( const p of this.players.values() ) {

			if ( ! p.team ) continue;
			const won = p.team === winner;
			if ( p.team === 'hider' ) {

				if ( p.alive ) {

					this.#xp( p, p.trade, X.survive, 'Survived the round' );
					this.#xp( p, 'agility', X.agilitySurvive + Math.min( X.agilityCap, p.distance * X.agilityPerMetre ), 'Stayed alive on the move' );

				} else {

					this.#xp( p, p.trade, X.eliminatedParticipation, 'Participation' );

				}

			}

			if ( won ) this.#xp( p, p.trade, X.win, 'Team victory' );
			summary.push( { id: p.id, name: p.name, team: p.team, alive: p.alive, kills: p.kills, won } );

		}

		this.#broadcastEvent( EV.ROUND_END, { winner, summary } );
		this.#setPhase( PHASES.RESULTS, CONFIG.round.resultsSeconds );

	}

	#checkWin() {

		if ( this.phase !== PHASES.HUNT ) return;
		let hiders = 0, hunters = 0;
		for ( const p of this.players.values() ) {

			if ( ! p.alive ) continue;
			if ( p.team === 'hider' ) hiders ++;
			if ( p.team === 'hunter' ) hunters ++;

		}

		if ( hiders === 0 ) this.#endRound( 'hunter' );
		else if ( hunters === 0 ) this.#endRound( 'hider' );

	}

	// ── simulation tick ─────────────────────────────────────────────────────

	tick( dt ) {

		this.time += dt;

		if ( this.phase !== PHASES.LOBBY ) {

			this.phaseTime -= dt;
			if ( this.phaseTime <= 0 ) {

				if ( this.phase === PHASES.PREP ) this.#setPhase( PHASES.HUNT, CONFIG.round.huntSeconds );
				else if ( this.phase === PHASES.HUNT ) this.#endRound( 'hider' );
				else if ( this.phase === PHASES.RESULTS ) {

					if ( this.players.size >= CONFIG.round.minPlayers ) this.startRound();
					else {

						for ( const p of this.players.values() ) {

							p.team = null;
							p.alive = true;
							p.disguise = null;

						}

						this.#setPhase( PHASES.LOBBY, 0 );

					}

				}

			}

		}

		// Resource node respawns
		for ( const [ index, at ] of this.depleted ) {

			if ( this.time >= at ) {

				this.depleted.delete( index );
				this.nodeHits.delete( index );
				this.#broadcastEvent( EV.NODE_RESPAWN, { index } );

			}

		}

		for ( const bot of this.bots.values() ) bot.update( dt );

		this.snapshotAccumulator += dt;
		if ( this.snapshotAccumulator >= 1 / CONFIG.net.snapshotHz ) {

			this.snapshotAccumulator = 0;
			this.#broadcastSnapshot();

		}

	}

	// ── intents ─────────────────────────────────────────────────────────────

	#onPos( p, msg ) {

		const now = this.time;
		const dt = Math.max( 0.016, now - p.lastPosTime );
		p.lastPosTime = now;
		if ( ! Array.isArray( msg.p ) || msg.p.length !== 3 || ! msg.p.every( Number.isFinite ) ) return;

		const frozen = ( p.team === 'hunter' && this.phase === PHASES.PREP ) || now < p.rootedUntil;
		if ( p.alive && frozen ) return;

		const dx = msg.p[ 0 ] - p.pos[ 0 ], dz = msg.p[ 2 ] - p.pos[ 2 ];
		const dist = Math.hypot( dx, dz );
		const speedMul = agilitySpeed( p.levels ) * ( now < p.speedUntil ? 2 : 1 );
		const maxDist = CONFIG.player.walkSpeed * CONFIG.player.sprintMultiplier * speedMul * dt * 1.6 + 1.5;

		if ( p.alive && dist > maxDist ) {

			// Reject teleports / speed hacks: snap the client back
			this.#send( p.id, { t: S2C.EVENT, e: EV.TELEPORT, id: p.id, pos: p.pos, yaw: p.yaw } );
			return;

		}

		if ( p.alive && p.team === 'hider' && this.phase === PHASES.HUNT ) p.distance += dist;
		p.pos = msg.p;
		p.yaw = Number.isFinite( msg.yaw ) ? msg.yaw : p.yaw;

	}

	#onDisguise( p, msg ) {

		if ( ! p.alive || p.team !== 'hider' ) return;
		if ( this.phase !== PHASES.PREP && this.phase !== PHASES.HUNT ) return;
		if ( this.time < p.disguiseReadyAt ) return;
		if ( ! canDisguiseAs( msg.type, p.levels ) ) {

			return this.#toast( p, `Requires ${PROP_TYPES[ msg.type ]?.skill} level ${PROP_TYPES[ msg.type ]?.level}` );

		}

		// Must actually be looking at a real prop (or decoy) of that type nearby
		const source = msg.index >= 0 ? this.layout.props[ msg.index ] : null;
		if ( ! source || source.type !== msg.type ) return;
		if ( this.#dist( p.pos, [ source.x, source.y, source.z ] ) > BALANCE.disguiseRange + source.radius ) return;

		const ratio = p.disguise ? p.hp / p.maxHp : 1;
		p.disguise = msg.type;
		p.maxHp = hiderMaxHp( msg.type, p.levels );
		p.hp = Math.max( 1, Math.round( p.maxHp * ratio ) );
		p.disguiseReadyAt = this.time + BALANCE.disguiseCooldown;
		this.#broadcastEvent( EV.DISGUISED, { id: p.id, type: msg.type } );

	}

	#onHit( hunter, msg ) {

		if ( ! hunter.alive || hunter.team !== 'hunter' || this.phase !== PHASES.HUNT ) return;
		if ( this.time < hunter.swingReadyAt ) return;
		hunter.swingReadyAt = this.time + BALANCE.swingCooldown;
		this.#broadcastEvent( EV.SWING, { id: hunter.id } );

		const reach = BALANCE.toolReach + 1.2; // generous for latency

		if ( msg.kind === 'player' ) {

			const target = this.players.get( msg.id );
			if ( ! target || ! target.alive || target.team !== 'hider' ) return;
			const r = target.disguise ? PROP_TYPES[ target.disguise ].radius : CONFIG.player.radius;
			if ( this.#dist( hunter.pos, target.pos ) > reach + r ) return;
			const dmg = toolDamage( hunter.trade, hunter.levels, target.disguise );
			this.#damage( target, dmg, hunter );

		} else if ( msg.kind === 'prop' ) {

			const prop = this.layout.props[ msg.id ];
			if ( ! prop ) return;
			if ( this.#dist( hunter.pos, [ prop.x, prop.y, prop.z ] ) > reach + prop.radius ) return;

			if ( toolGathers( hunter.trade, prop.type ) && ! this.depleted.has( prop.index ) ) {

				this.#gather( hunter, prop );

			} else {

				this.#damage( hunter, BALANCE.wrongPropPenalty, null );

			}

		} else if ( msg.kind === 'decoy' ) {

			const decoy = this.decoys.get( msg.id );
			if ( ! decoy ) return;
			if ( this.#dist( hunter.pos, decoy.pos ) > reach + PROP_TYPES[ decoy.type ].radius ) return;
			this.decoys.delete( decoy.id );
			this.#broadcastEvent( EV.DECOY_REMOVED, { id: decoy.id } );
			this.#damage( hunter, BALANCE.wrongPropPenalty, null );

		}

	}

	#gather( hunter, prop ) {

		const node = PROP_TYPES[ prop.type ].node;
		const hits = ( this.nodeHits.get( prop.index ) ?? 0 ) + 1;
		this.nodeHits.set( prop.index, hits );
		const depleted = hits >= node.hits;
		if ( depleted ) this.depleted.set( prop.index, this.time + BALANCE.nodeRespawnSeconds );
		this.#xp( hunter, node.skill, node.xp, `Gathered ${PROP_TYPES[ prop.type ].name}` );
		this.#broadcastEvent( EV.GATHER, { index: prop.index, by: hunter.id, skill: node.skill, depleted } );

	}

	#onForage( p, msg ) {

		if ( ! p.alive || p.team !== 'hider' || this.phase !== PHASES.HUNT || ! p.disguise ) return;
		if ( this.time < p.forageReadyAt ) return;
		const prop = this.layout.props[ msg.index ];
		if ( ! prop || this.depleted.has( prop.index ) ) return;
		if ( ! canForage( p.disguise, prop.type ) ) return;
		if ( this.#dist( p.pos, [ prop.x, prop.y, prop.z ] ) > BALANCE.forageRange + prop.radius ) return;

		p.forageReadyAt = this.time + BALANCE.forageInterval;
		const skill = PROP_TYPES[ prop.type ].node.skill;
		this.#xp( p, skill, BALANCE.xp.forage, 'Foraging' );
		// The tell: every forage tick emits visible particles for everyone
		this.#broadcastEvent( EV.FORAGE_FX, { pos: [ p.pos[ 0 ], p.pos[ 1 ] + 1, p.pos[ 2 ] ], skill } );

	}

	#onAbility( p, msg ) {

		if ( ! p.alive || this.phase !== PHASES.HUNT || this.time < p.abilityReadyAt ) return;
		const ability = getAbility( p.team, p.trade );
		if ( ! ability ) return;
		const fx = ability.effect;
		const base = { id: p.id, ability: ability.id, pos: p.pos };

		switch ( fx.type ) {

			case 'reveal': {

				const ids = [];
				for ( const h of this.players.values() ) {

					if ( h.team !== 'hider' || ! h.alive ) continue;
					if ( fx.family && PROP_TYPES[ h.disguise ]?.skill !== fx.family ) continue;
					if ( this.#dist( p.pos, h.pos ) <= fx.radius ) ids.push( h.id );

				}

				this.#send( p.id, { t: S2C.EVENT, e: EV.REVEAL, ids, duration: fx.duration } );
				this.#broadcastEvent( EV.ABILITY, { ...base, radius: fx.radius } );
				break;

			}

			case 'harpoon': {

				const origin = sanitizeVec( msg.origin ) ?? [ p.pos[ 0 ], p.pos[ 1 ] + 1.4, p.pos[ 2 ] ];
				const dir = normalize( sanitizeVec( msg.dir ) ?? [ Math.sin( p.yaw ), 0, Math.cos( p.yaw ) ] );
				// Clamp origin to near the player to stop "shooting from elsewhere"
				if ( this.#dist( origin, p.pos ) > 6 ) return;
				let best = null, bestT = fx.range;
				for ( const h of this.players.values() ) {

					if ( h.team !== 'hider' || ! h.alive ) continue;
					const def = PROP_TYPES[ h.disguise ];
					const r = ( def?.radius ?? 0.4 ) + 0.3;
					const c = [ h.pos[ 0 ], h.pos[ 1 ] + ( def?.height ?? 1.6 ) * 0.5, h.pos[ 2 ] ];
					const t = raySphere( origin, dir, c, r );
					if ( t !== null && t < bestT ) {

						best = h;
						bestT = t;

					}

				}

				const to = [ origin[ 0 ] + dir[ 0 ] * bestT, origin[ 1 ] + dir[ 1 ] * bestT, origin[ 2 ] + dir[ 2 ] * bestT ];
				this.#broadcastEvent( EV.HARPOON, { from: origin, to, hitId: best?.id ?? null } );
				if ( best ) {

					this.#send( p.id, { t: S2C.EVENT, e: EV.REVEAL, ids: [ best.id ], duration: fx.duration } );
					this.#damage( best, fx.damage, p );

				}

				break;

			}

			case 'root':
				p.rootedUntil = this.time + fx.duration;
				this.#broadcastEvent( EV.ABILITY, { ...base, duration: fx.duration } );
				break;

			case 'speed':
				p.speedUntil = this.time + fx.duration;
				this.#broadcastEvent( EV.ABILITY, { ...base, duration: fx.duration } );
				break;

			case 'decoy': {

				if ( ! p.disguise ) return this.#toast( p, 'Disguise first to drop a decoy' );
				const mine = [ ...this.decoys.values() ].filter( ( d ) => d.owner === p.id );
				if ( mine.length >= BALANCE.maxDecoys ) {

					this.decoys.delete( mine[ 0 ].id );
					this.#broadcastEvent( EV.DECOY_REMOVED, { id: mine[ 0 ].id } );

				}

				const decoy = { id: this.nextDecoyId ++, owner: p.id, type: p.disguise, pos: [ ...p.pos ], yaw: p.yaw };
				this.decoys.set( decoy.id, decoy );
				this.#broadcastEvent( EV.DECOY, { decoy } );
				this.#broadcastEvent( EV.ABILITY, base );
				break;

			}

		}

		const cd = abilityCooldown( ability.cooldown, p.trade, p.levels );
		p.abilityReadyAt = this.time + cd;
		this.#send( p.id, { t: S2C.EVENT, e: EV.COOLDOWN, seconds: cd } );

	}

	#onTaunt( p ) {

		if ( ! p.alive || p.team !== 'hider' || this.phase !== PHASES.HUNT ) return;
		if ( this.time < p.tauntReadyAt ) return;
		p.tauntReadyAt = this.time + 6;
		this.#xp( p, 'agility', 6, 'Taunt' );
		this.#broadcastEvent( EV.TAUNT, { id: p.id, pos: p.pos } );

	}

	// ── combat helpers ──────────────────────────────────────────────────────

	#damage( target, amount, by ) {

		if ( ! target.alive ) return;
		if ( this.time < target.rootedUntil ) amount *= 0.5;
		target.hp = Math.max( 0, target.hp - Math.round( amount ) );
		target.lastDamagedAt = this.time;
		this.#broadcastEvent( EV.DAMAGE, { id: target.id, hp: target.hp, amount: Math.round( amount ), by: by?.id ?? null, self: ! by } );
		this.bots.get( target.id )?.onDamaged( by );
		if ( target.hp <= 0 ) this.#eliminate( target, by );

	}

	#eliminate( target, by ) {

		target.alive = false;
		if ( by ) {

			by.kills ++;
			this.#xp( by, by.trade, BALANCE.xp.elimination, `Found ${target.name}` );

		}

		this.#broadcastEvent( EV.ELIMINATED, { id: target.id, by: by?.id ?? null } );
		this.#checkWin();

	}

	#xp( p, skill, amount, reason ) {

		if ( p.isBot ) return;
		this.#send( p.id, { t: S2C.EVENT, e: EV.XP, skill, amount: Math.round( amount ), reason } );

	}

	#toast( p, text ) {

		this.#send( p.id, { t: S2C.EVENT, e: EV.TOAST, text } );

	}

	#teleport( p, x, z, yaw ) {

		p.pos = [ x, this.layout.groundAt( x, z ), z ];
		p.yaw = yaw;
		p.lastPosTime = this.time;
		this.#broadcastEvent( EV.TELEPORT, { id: p.id, pos: p.pos, yaw } );

	}

	#dist( a, b ) {

		return Math.hypot( a[ 0 ] - b[ 0 ], a[ 2 ] - b[ 2 ] );

	}

	// ── state serialisation ─────────────────────────────────────────────────

	publicPlayer( p ) {

		return {
			id: p.id, name: p.name, isBot: p.isBot, team: p.team, trade: p.trade,
			alive: p.alive, ready: p.ready, hp: p.hp, maxHp: p.maxHp,
			pos: p.pos, yaw: p.yaw, disguise: p.disguise, levels: p.levels, kills: p.kills,
			rooted: this.time < p.rootedUntil, fast: this.time < p.speedUntil
		};

	}

	#fullState() {

		return {
			phase: this.phase,
			round: this.round,
			timeLeft: this.phaseTime,
			players: [ ...this.players.values() ].map( ( p ) => this.publicPlayer( p ) ),
			depleted: [ ...this.depleted.keys() ],
			decoys: [ ...this.decoys.values() ]
		};

	}

	#broadcastSnapshot() {

		this.#broadcast( {
			t: S2C.SNAPSHOT,
			phase: this.phase,
			round: this.round,
			timeLeft: Math.max( 0, this.phaseTime ),
			players: [ ...this.players.values() ].map( ( p ) => this.publicPlayer( p ) )
		} );

	}

	#broadcastEvent( e, payload ) {

		this.#broadcast( { t: S2C.EVENT, e, ...payload } );

	}

	#broadcast( msg ) {

		for ( const send of this.clients.values() ) send( msg );

	}

	#send( id, msg ) {

		this.clients.get( id )?.( msg );

	}

	/** Used by bots: route an intent exactly like a network message. */
	intent( id, msg ) {

		this.onMessage( id, msg );

	}

}

// ── small vector helpers ────────────────────────────────────────────────────

function sanitizeVec( v ) {

	return Array.isArray( v ) && v.length === 3 && v.every( Number.isFinite ) ? v : null;

}

function normalize( v ) {

	const l = Math.hypot( v[ 0 ], v[ 1 ], v[ 2 ] ) || 1;
	return [ v[ 0 ] / l, v[ 1 ] / l, v[ 2 ] / l ];

}

function raySphere( o, d, c, r ) {

	const ox = o[ 0 ] - c[ 0 ], oy = o[ 1 ] - c[ 1 ], oz = o[ 2 ] - c[ 2 ];
	const b = ox * d[ 0 ] + oy * d[ 1 ] + oz * d[ 2 ];
	const cc = ox * ox + oy * oy + oz * oz - r * r;
	const disc = b * b - cc;
	if ( disc < 0 ) return null;
	const t = - b - Math.sqrt( disc );
	return t >= 0 ? t : null;

}
