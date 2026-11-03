import { PHASES, C2S } from '../net/protocol.js';
import { PROP_TYPES } from '../world/PropCatalog.js';
import { BALANCE, canDisguiseAs, canForage, agilitySpeed } from './rules.js';
import { CONFIG } from '../config.js';

export const BOT_NAMES = [ 'Bramble', 'Cobble', 'Marlin', 'Fern', 'Flint', 'Pike', 'Thistle', 'Shale', 'Kelp', 'Rowan', 'Slate', 'Minnow', 'Hazel', 'Garnet', 'Perch' ];

/**
 * Host-side AI. Bots never touch state directly – they issue the same intents
 * a networked client would (`server.intent(id, msg)`), so they exercise the
 * exact code paths real players use. Great for solo testing.
 */
export class BotBrain {

	constructor( id, server, rng ) {

		this.id = id;
		this.server = server;
		this.rng = rng;
		this.reset();

	}

	reset() {

		this.goal = null;          // { x, z }
		this.target = null;        // { kind, id, x, z }
		this.state = 'idle';
		this.stateTime = 0;
		this.thinkIn = 0;
		this.fleeFrom = null;
		this.disguised = false;

	}

	get me() {

		return this.server.players.get( this.id );

	}

	onRoundStart() {

		this.reset();
		this.thinkIn = this.rng.range( 0.3, 1.5 );

	}

	onDamaged( by ) {

		const me = this.me;
		if ( ! me || me.team !== 'hider' || ! by ) return;
		this.fleeFrom = { x: by.pos[ 0 ], z: by.pos[ 2 ] };
		this.state = 'flee';
		this.stateTime = this.rng.range( 1.8, 3.2 );
		if ( this.rng.chance( 0.5 ) ) this.server.intent( this.id, { t: C2S.ABILITY } );

	}

	update( dt ) {

		const me = this.me;
		const phase = this.server.phase;
		if ( ! me || ! me.alive || ! me.team ) return;
		if ( phase !== PHASES.PREP && phase !== PHASES.HUNT ) return;

		this.thinkIn -= dt;
		this.stateTime -= dt;
		if ( me.team === 'hider' ) this.#hider( dt, me, phase );
		else this.#hunter( dt, me, phase );

	}

	// ── hider ───────────────────────────────────────────────────────────────

	#hider( dt, me, phase ) {

		const layout = this.server.layout;

		if ( this.state === 'flee' ) {

			if ( this.stateTime <= 0 || ! this.fleeFrom ) {

				this.state = 'hidden';
				this.fleeFrom = null;
				return;

			}

			const ax = me.pos[ 0 ] - this.fleeFrom.x, az = me.pos[ 2 ] - this.fleeFrom.z;
			const len = Math.hypot( ax, az ) || 1;
			this.#moveToward( me, me.pos[ 0 ] + ax / len * 5, me.pos[ 2 ] + az / len * 5, dt, 1.4 );
			return;

		}

		if ( ! this.disguised ) {

			if ( ! this.target && this.thinkIn <= 0 ) {

				// Choose a nearby prop we're allowed to become
				const near = layout.nearby( me.pos[ 0 ], me.pos[ 2 ], 30 )
					.filter( ( p ) => canDisguiseAs( p.type, me.levels ) && layout.heightfield.isLand( p.x, p.z ) );
				const pick = near.length ? this.rng.pick( near ) : null;
				if ( pick ) this.target = { kind: 'prop', id: pick.index, x: pick.x, z: pick.z, type: pick.type };
				this.thinkIn = 1;

			}

			if ( this.target ) {

				const d = Math.hypot( this.target.x - me.pos[ 0 ], this.target.z - me.pos[ 2 ] );
				if ( d > 3.5 ) this.#moveToward( me, this.target.x, this.target.z, dt, 1 );
				else {

					this.server.intent( this.id, { t: C2S.DISGUISE, type: this.target.type, index: this.target.id } );
					this.disguised = me.disguise === this.target.type;
					if ( this.disguised ) {

						// Settle a few metres away – ideally next to look-alikes
						const a = this.rng() * Math.PI * 2;
						const r = this.rng.range( 2.5, 6 );
						this.goal = { x: this.target.x + Math.cos( a ) * r, z: this.target.z + Math.sin( a ) * r };
						this.state = 'settling';

					} else {

						this.target = null;

					}

				}

			}

			return;

		}

		if ( this.state === 'settling' && this.goal ) {

			if ( this.#moveToward( me, this.goal.x, this.goal.z, dt, 0.8 ) < 0.4 ) {

				this.state = 'hidden';
				this.goal = null;

			}

			return;

		}

		// Hidden: occasionally forage (creating tells) or taunt
		if ( phase === PHASES.HUNT && this.thinkIn <= 0 ) {

			this.thinkIn = this.rng.range( 1.5, 3 );
			if ( this.rng.chance( 0.25 ) ) {

				const node = layout.nearby( me.pos[ 0 ], me.pos[ 2 ], BALANCE.forageRange )
					.find( ( p ) => canForage( me.disguise, p.type ) );
				if ( node ) this.server.intent( this.id, { t: C2S.FORAGE, index: node.index } );

			}

			if ( this.rng.chance( 0.04 ) ) this.server.intent( this.id, { t: C2S.TAUNT } );

		}

	}

	// ── hunter ──────────────────────────────────────────────────────────────

	#hunter( dt, me, phase ) {

		if ( phase !== PHASES.HUNT ) return;
		const server = this.server;

		if ( this.thinkIn <= 0 || ! this.target ) {

			this.thinkIn = this.rng.range( 1.2, 2.4 );
			this.target = this.#chooseHunterTarget( me );

		}

		if ( ! this.target ) {

			// Wander
			if ( ! this.goal || Math.hypot( this.goal.x - me.pos[ 0 ], this.goal.z - me.pos[ 2 ] ) < 1 ) {

				this.goal = server.layout.randomLandPoint( this.rng, 5, CONFIG.world.islandRadius - 10 );

			}

			this.#moveToward( me, this.goal.x, this.goal.z, dt, 1 );
			return;

		}

		// Track moving hiders
		if ( this.target.kind === 'player' ) {

			const h = server.players.get( this.target.id );
			if ( ! h || ! h.alive ) {

				this.target = null;
				return;

			}

			this.target.x = h.pos[ 0 ];
			this.target.z = h.pos[ 2 ];

		}

		const d = this.#moveToward( me, this.target.x, this.target.z, dt, 1.2, BALANCE.toolReach - 0.6 );
		if ( ! this.target ) return; // path blocked (water) – re-plan next think
		if ( d <= BALANCE.toolReach ) {

			server.intent( this.id, { t: C2S.HIT, kind: this.target.kind, id: this.target.id } );
			if ( this.target.kind !== 'player' && this.rng.chance( 0.6 ) ) this.target = null;

		}

		if ( this.rng.chance( dt * 0.05 ) ) server.intent( this.id, { t: C2S.ABILITY } );

	}

	#chooseHunterTarget( me ) {

		const server = this.server;
		const x = me.pos[ 0 ], z = me.pos[ 2 ];
		const lowHp = me.hp < 35;

		// Spot hiders: easier when close or when they recently moved/foraged
		for ( const h of server.players.values() ) {

			if ( h.team !== 'hider' || ! h.alive ) continue;
			const d = Math.hypot( h.pos[ 0 ] - x, h.pos[ 2 ] - z );
			if ( d > 16 ) continue;
			const undisguised = ! h.disguise;
			const p = undisguised ? 0.9 : 0.35 * ( 1 - d / 16 ) + ( server.time - h.lastPosTime < 1 ? 0.05 : 0 );
			if ( this.rng.chance( p ) ) return { kind: 'player', id: h.id, x: h.pos[ 0 ], z: h.pos[ 2 ] };

		}

		if ( lowHp ) return null;

		// Otherwise poke a random disguisable prop (or gather a node we can)
		const near = server.layout.nearby( x, z, 12 ).filter( ( p ) => PROP_TYPES[ p.type ].disguisable !== false );
		if ( ! near.length || this.rng.chance( 0.35 ) ) return null;
		const prop = this.rng.pick( near );
		return { kind: 'prop', id: prop.index, x: prop.x, z: prop.z };

	}

	// ── movement ────────────────────────────────────────────────────────────

	/** Step toward (tx, tz); returns remaining distance. */
	#moveToward( me, tx, tz, dt, speedFactor = 1, stopAt = 0.2 ) {

		const dx = tx - me.pos[ 0 ], dz = tz - me.pos[ 2 ];
		const d = Math.hypot( dx, dz );
		if ( d <= stopAt ) return d;

		const speed = CONFIG.player.walkSpeed * 0.85 * speedFactor * agilitySpeed( me.levels );
		const step = Math.min( d - stopAt, speed * dt );
		const nx = me.pos[ 0 ] + dx / d * step;
		const nz = me.pos[ 2 ] + dz / d * step;
		const layout = this.server.layout;
		if ( ! layout.heightfield.isLand( nx, nz ) ) {

			this.goal = null;
			this.target = null;
			return 0;

		}

		this.server.intent( this.id, {
			t: C2S.POS,
			p: [ nx, layout.groundAt( nx, nz ), nz ],
			yaw: Math.atan2( dx, dz )
		} );
		return d - step;

	}

}
