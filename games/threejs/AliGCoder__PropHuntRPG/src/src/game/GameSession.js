import * as THREE from 'three/webgpu';
import { CONFIG } from '../config.js';
import { MapLayout } from '../world/MapLayout.js';
import { PROP_TYPES } from '../world/PropCatalog.js';
import { buildScene } from '../render/SceneBuilder.js';
import { PlayerView } from '../entities/PlayerView.js';
import { LocalController } from '../entities/LocalController.js';
import { CameraRig } from '../entities/CameraRig.js';
import { EV, PHASES } from '../net/protocol.js';
import { BALANCE, canDisguiseAs, canForage, toolGathers, agilitySpeed } from './rules.js';
import { SKILLS } from '../skills/skills.js';
import { Hud } from '../ui/Hud.js';
import { LobbyPanel } from '../ui/LobbyPanel.js';

const _raycaster = new THREE.Raycaster();
const REVEAL_COLOR = 0xff4d4d;
const TEAMMATE_COLOR = 0x6fd3ff;

/**
 * Client-side game: owns the 3D scene for a match, the local player,
 * remote player views and the HUD, and translates input into intents sent
 * through the ClientSession. Knows nothing about transports.
 */
export class GameSession {

	constructor( { net, renderer, input, store, sfx, ui, onLeave, openSkills } ) {

		this.net = net;
		this.client = net.client;
		this.renderer = renderer;
		this.input = input;
		this.store = store;
		this.sfx = sfx;
		this.ui = ui;
		this.onLeave = onLeave;
		this.openSkills = openSkills;

		this.views = new Map();
		this.revealed = new Map();      // player id -> until (ms)
		this.posTimer = 0;
		this.forageTimer = 0;
		this.spectateIndex = 0;
		this.aim = null;
		this.disposers = [];
		this.ready = false;

	}

	async start() {

		const client = this.client;
		if ( ! client.connected ) await new Promise( ( resolve ) => client.once( 'welcome', resolve ) );

		// Host already generated the layout – reuse it instead of regenerating
		this.layout = this.net.server?.layout ?? new MapLayout( client.seed );
		const built = buildScene( this.renderer, this.layout );
		Object.assign( this, built );

		this.controller = new LocalController( this.layout, this.input );
		this.cameraRig = new CameraRig( this.camera, this.layout );
		const me = client.me;
		if ( me ) this.controller.teleport( me.pos, me.yaw );

		for ( const index of client.depleted ) this.world.setDepleted( index, true );
		for ( const d of client.decoys.values() ) this.world.addDecoy( d );

		this.hud = new Hud();
		this.lobby = new LobbyPanel( {
			client, code: this.net.code, mode: this.net.mode,
			onLeave: () => this.onLeave(),
			onTrade: ( t ) => {

				this.store.preferredTrade = t;
				client.setTrade( t );
				this.sfx.click();

			}
		} );
		this.ui.append( this.hud.el, this.lobby.el );

		this.#bindEvents();
		this.ready = true;

	}

	// ── events from the host ────────────────────────────────────────────────

	#bindEvents() {

		const c = this.client;
		const on = ( name, fn ) => this.disposers.push( c.on( 'ev:' + name, fn ) );
		const nameOf = ( id ) => c.players.get( id )?.name ?? 'Someone';
		const posOf = ( id ) => c.players.get( id )?.pos ?? [ 0, 0, 0 ];

		this.disposers.push( c.on( 'error', ( msg ) => this.hud.toast( msg ) ) );
		this.disposers.push( c.on( 'disconnected', () => {

			this.hud.toast( 'Disconnected from host' );
			setTimeout( () => this.onLeave(), 1500 );

		} ) );

		on( EV.PHASE, ( ev ) => {

			if ( ev.phase === PHASES.PREP ) {

				this.world.resetDepleted();
				this.world.clearDecoys();
				this.revealed.clear();
				this.controller.rotationLocked = false;
				const me = c.me;
				if ( me?.team === 'hunter' ) this.hud.banner( `Round ${ev.round}: You are a HUNTER`, `Your tool: ${SKILLS[ me.trade ].toolName}. Wait for the hiders…` );
				else this.hud.banner( `Round ${ev.round}: You are a HIDER`, 'Aim at a prop and press E to disguise' );
				this.input.requestLock();

			} else if ( ev.phase === PHASES.HUNT ) {

				this.hud.banner( 'The hunt begins!', c.me?.team === 'hunter' ? 'Find the props that aren\'t props' : 'Stay still… or forage for XP' );

			}

		} );

		on( EV.TELEPORT, ( ev ) => {

			if ( ev.id === c.you ) this.controller.teleport( ev.pos, ev.yaw );
			else this.views.get( ev.id )?.snap();

		} );

		on( EV.SWING, ( ev ) => {

			if ( ev.id !== c.you ) this.views.get( ev.id )?.swing();
			this.sfx.swing( posOf( ev.id ) );

		} );

		on( EV.DAMAGE, ( ev ) => {

			const p = posOf( ev.id );
			const at = [ p[ 0 ], p[ 1 ] + 1, p[ 2 ] ];
			this.effects.burst( at, 'hit', ev.self ? 6 : 14 );
			this.sfx.hit( at );
			this.hud.floatText( this.camera, at, `-${ev.amount}`, ev.self ? '#ffb4b4' : '#ffe08a' );
			if ( ev.id === c.you ) {

				this.hud.hurt();
				this.sfx.hurt();
				if ( ev.self ) this.hud.toast( 'Wrong prop! You lost HP' );

			}

		} );

		on( EV.ELIMINATED, ( ev ) => {

			const p = posOf( ev.id );
			this.effects.burst( [ p[ 0 ], p[ 1 ] + 0.8, p[ 2 ] ], 'elim', 40, 5 );
			this.sfx.eliminated( p );
			this.hud.feedItem( ev.by ? `🎯 <b>${esc( nameOf( ev.by ) )}</b> found <b>${esc( nameOf( ev.id ) )}</b>` : `💥 <b>${esc( nameOf( ev.id ) )}</b> wore themselves out` );
			if ( ev.id === c.you ) this.hud.banner( 'You were eliminated', 'Spectating — press N to switch players' );
			if ( ev.by === c.you ) this.store.recordStat( 'eliminations' );

		} );

		on( EV.GATHER, ( ev ) => {

			const prop = this.layout.props[ ev.index ];
			const at = [ prop.x, prop.y + 1, prop.z ];
			this.effects.burst( at, ev.skill, 10 );
			this.sfx.chop( at, ev.skill );
			if ( ev.depleted ) this.world.setDepleted( ev.index, true );

		} );

		on( EV.NODE_RESPAWN, ( ev ) => this.world.setDepleted( ev.index, false ) );

		on( EV.FORAGE_FX, ( ev ) => {

			this.effects.burst( ev.pos, ev.skill, 12, 2.2 );
			this.sfx.forage( ev.pos );

		} );

		on( EV.REVEAL, ( ev ) => {

			const until = performance.now() + ev.duration * 1000;
			for ( const id of ev.ids ) this.revealed.set( id, until );
			this.hud.toast( ev.ids.length ? `Revealed ${ev.ids.length} hider${ev.ids.length > 1 ? 's' : ''}!` : 'Nothing detected' );

		} );

		on( EV.ABILITY, ( ev ) => {

			const colors = { timber_sense: 0x7bc96f, seismic_pulse: 0xc9a36f, take_root: 0x7bc96f, slippery: 0x6fd3ff, decoy: 0xc9a36f };
			if ( ev.radius ) this.effects.ring( ev.pos, ev.radius, colors[ ev.ability ] ?? 0xffffff, 0.9 );
			else this.effects.burst( [ ev.pos[ 0 ], ev.pos[ 1 ] + 0.5, ev.pos[ 2 ] ], 'taunt', 8, 2 );
			this.sfx.ability( ev.pos );

		} );

		on( EV.HARPOON, ( ev ) => {

			this.effects.line( ev.from, ev.to, 0xd0f4ff, 0.6 );
			this.effects.burst( ev.to, ev.hitId ? 'hit' : 'fishing', 10 );

		} );

		on( EV.DECOY, ( ev ) => this.world.addDecoy( ev.decoy ) );
		on( EV.DECOY_REMOVED, ( ev ) => this.world.removeDecoy( ev.id ) );

		on( EV.DISGUISED, ( ev ) => {

			const p = posOf( ev.id );
			this.effects.burst( [ p[ 0 ], p[ 1 ] + 0.6, p[ 2 ] ], 'taunt', 16, 2.5 );
			if ( ev.id === c.you ) this.hud.toast( `You are now a ${PROP_TYPES[ ev.type ].name}` );

		} );

		on( EV.TAUNT, ( ev ) => {

			this.sfx.taunt( ev.pos );
			this.hud.floatText( this.camera, [ ev.pos[ 0 ], ev.pos[ 1 ] + 2, ev.pos[ 2 ] ], '♪ ♫', '#ff9ae6' );
			this.effects.burst( [ ev.pos[ 0 ], ev.pos[ 1 ] + 1.2, ev.pos[ 2 ] ], 'taunt', 10, 2 );

		} );

		on( EV.XP, ( ev ) => {

			this.store.addXp( ev.skill, ev.amount, ev.reason );

		} );

		on( EV.COOLDOWN, ( ev ) => this.hud.setCooldown( ev.seconds ) );
		on( EV.TOAST, ( ev ) => this.hud.toast( ev.text ) );
		on( EV.JOINED, ( ev ) => ev.id !== c.you && this.hud.feedItem( `➕ <b>${esc( ev.name )}</b> joined` ) );
		on( EV.LEFT, ( ev ) => this.hud.feedItem( `➖ <b>${esc( ev.name )}</b> left` ) );

		on( EV.ROUND_END, ( ev ) => {

			this.store.recordStat( 'rounds' );
			const mine = ev.summary.find( ( s ) => s.id === c.you );
			if ( mine?.won ) this.store.recordStat( 'wins' );
			if ( mine?.team === 'hider' && mine.alive ) this.store.recordStat( 'survivals' );
			this.input.exitLock();
			this.hud.showResults( { ...ev, you: c.you } );

		} );

		// Persisted progression → UI + tell the host our new levels
		this.disposers.push( this.store.on( 'xp', ( e ) => {

			this.hud.xpPopup( e.skill, e.amount, e.reason );
			this.sfx.xp();

		} ) );
		this.disposers.push( this.store.on( 'levelup', ( e ) => {

			this.hud.levelUp( e.skill, e.level );
			this.sfx.levelUp();
			this.client.updateLevels( this.store.levels );

		} ) );

	}

	// ── per-frame ───────────────────────────────────────────────────────────

	update( dt ) {

		if ( ! this.ready ) return;
		const c = this.client;
		c.update( dt );
		const me = c.me;
		const phase = c.phase;

		this.lobby.el.style.display = phase === PHASES.LOBBY ? '' : 'none';
		if ( phase === PHASES.LOBBY ) this.lobby.update();

		if ( this.input.wasPressed( 'skills' ) ) this.openSkills();

		this.#syncViews( me );

		const alive = !! me?.alive;
		const playing = alive && ( phase === PHASES.LOBBY || !! me.team );

		// Mouse look always works when locked
		this.cameraRig.applyMouse( this.input.consumeMouse() );

		if ( playing ) this.#updateLocal( dt, me, phase );
		else this.#updateSpectator( dt );

		// Remote views
		for ( const view of this.views.values() ) view.update( dt );

		// Outlines: teammates for hiders, revealed targets for hunters
		this.#updateOutlines( me );

		this.world.update( this.controller.position );
		this.effects.update( dt );
		this.sfx.setListener( this.camera.position );
		this.hud.update( dt, { client: c, me, revealCount: this.revealed.size, pointerLocked: this.input.isLocked } );

	}

	#syncViews( me ) {

		const c = this.client;
		for ( const p of c.players.values() ) {

			let view = this.views.get( p.id );
			if ( ! view ) {

				view = new PlayerView( p, this.factory, p.id === c.you );
				this.views.set( p.id, view );
				this.scene.add( view.root );

			}

			view.apply( p );
			if ( p.id !== c.you ) view.setTarget( p.pos, p.yaw );

		}

		for ( const [ id, view ] of this.views ) {

			if ( ! c.players.has( id ) ) {

				this.scene.remove( view.root );
				this.views.delete( id );

			}

		}

		// The local hider's own prop shouldn't block their aim rays
		const mine = this.views.get( c.you );
		if ( mine ) mine.root.visible = !! me?.alive;

	}

	#updateLocal( dt, me, phase ) {

		const c = this.client;
		const ctrl = this.controller;
		const view = this.views.get( c.you );
		const frozen = ( me.team === 'hunter' && phase === PHASES.PREP ) || me.rooted;

		const def = me.disguise ? PROP_TYPES[ me.disguise ] : null;
		ctrl.radius = def ? Math.max( 0.3, def.radius * 0.8 ) : CONFIG.player.radius;

		if ( this.input.wasPressed( 'lockRotation' ) && me.disguise ) {

			ctrl.rotationLocked = ! ctrl.rotationLocked;
			this.hud.toast( ctrl.rotationLocked ? 'Rotation locked' : 'Rotation unlocked' );

		}

		ctrl.update( dt, {
			cameraYaw: this.cameraRig.forwardYaw,
			canMove: this.input.isLocked && ! frozen,
			speedMultiplier: agilitySpeed( me.levels ) * ( me.fast ? 1.8 : 1 ),
			faceCamera: me.team === 'hunter' || !! me.disguise
		} );

		if ( view ) {

			view.root.position.copy( ctrl.position );
			view.root.rotation.y = ctrl.yaw;

		}

		// Camera: further back for big props
		const focusHeight = def ? Math.max( 0.8, def.height * 0.9 ) : CONFIG.camera.height;
		const extra = def ? Math.max( 0, def.height - 1.5 ) * 0.9 : 0;
		this.cameraRig.update( dt, ctrl.position, focusHeight, extra );

		// Network position
		this.posTimer += dt;
		if ( this.posTimer >= 1 / CONFIG.net.positionHz ) {

			this.posTimer = 0;
			c.sendPosition( ctrl.position, ctrl.yaw );

		}

		this.#handleActions( dt, me, phase );

	}

	#handleActions( dt, me, phase ) {

		const c = this.client;
		const input = this.input;
		const locked = input.isLocked;
		const aim = this.#aim( me );
		this.aim = aim;

		let prompt = '', promptLocked = false;

		if ( me.team === 'hider' && ( phase === PHASES.PREP || phase === PHASES.HUNT ) ) {

			if ( aim?.kind === 'prop' && ! aim.depleted ) {

				const def = PROP_TYPES[ aim.type ];
				if ( def.disguisable !== false && aim.distance <= BALANCE.disguiseRange ) {

					if ( canDisguiseAs( aim.type, me.levels ) ) prompt = me.disguise === aim.type ? '' : `E — Become ${def.name}`;
					else {

						prompt = `🔒 ${def.name} — ${SKILLS[ def.skill ].name} ${def.level} required`;
						promptLocked = true;

					}

					if ( locked && input.wasPressed( 'disguise' ) ) {

						if ( canDisguiseAs( aim.type, me.levels ) ) c.disguise( aim.type, aim.id );
						else this.hud.toast( prompt );

					}

				}

			}

			// Foraging
			if ( phase === PHASES.HUNT && me.disguise ) {

				const node = this.#nearestForageNode( me );
				if ( node && ! prompt ) prompt = `Hold F — Forage ${PROP_TYPES[ node.type ].name} (makes noise!)`;
				this.forageTimer -= dt;
				if ( node && locked && input.isDown( 'gather' ) && this.forageTimer <= 0 ) {

					this.forageTimer = BALANCE.forageInterval + 0.05;
					c.forage( node.index );

				}

			}

			if ( locked && input.wasPressed( 'taunt' ) ) c.taunt();

		}

		if ( me.team === 'hunter' && phase === PHASES.HUNT ) {

			if ( aim?.kind === 'prop' && aim.distance <= BALANCE.toolReach + 0.5 && toolGathers( me.trade, aim.type ) && ! aim.depleted ) {

				prompt = `Click — Gather ${PROP_TYPES[ aim.type ].name} (no penalty)`;

			}

			if ( locked && input.primaryPressed ) {

				this.views.get( c.you )?.swing();
				const reach = BALANCE.toolReach + ( aim?.radius ?? 0 );
				if ( aim && aim.kind !== 'terrain' && aim.distance <= reach && ! aim.depleted ) c.hit( aim.kind, aim.id );
				else c.hit( 'miss', null );

			}

		}

		if ( locked && input.wasPressed( 'ability' ) && phase === PHASES.HUNT ) {

			const ray = this.cameraRig.getAimRay( _raycaster );
			const o = ray.origin.clone().addScaledVector( ray.direction, this.cameraRig.currentDistance );
			c.useAbility( [ o.x, o.y, o.z ], [ ray.direction.x, ray.direction.y, ray.direction.z ] );

		}

		this.hud.setPrompt( prompt, promptLocked );

	}

	/** What the crosshair is pointing at, with distance from the player's body. */
	#aim( me ) {

		const ray = this.cameraRig.getAimRay( _raycaster );
		_raycaster.far = 60;
		const targets = this.world.raycastTargets.slice();
		for ( const [ id, view ] of this.views ) if ( id !== this.client.you ) targets.push( ...view.hitMeshes );

		const hits = _raycaster.intersectObjects( targets, false );
		const skip = this.cameraRig.currentDistance * 0.6;
		for ( const hit of hits ) {

			if ( hit.distance < skip ) continue;
			let info = hit.object.userData.hit;
			let o = hit.object;
			while ( ! info && o.parent ) {

				o = o.parent;
				info = o.userData.hit;

			}

			if ( ! info ) continue;
			if ( info.kind === 'player' ) {

				const p = this.client.players.get( info.id );
				if ( ! p?.alive ) continue;

			}

			const px = this.controller.position.x, pz = this.controller.position.z;
			const distance = Math.hypot( hit.point.x - px, hit.point.z - pz );
			const radius = info.kind === 'prop' ? 0.5 : 0.6;
			return { ...info, distance, radius, point: hit.point };

		}

		return null;

	}

	#nearestForageNode( me ) {

		const pos = this.controller.position;
		let best = null, bestD = Infinity;
		for ( const prop of this.layout.nearby( pos.x, pos.z, BALANCE.forageRange ) ) {

			if ( this.client.depleted.has( prop.index ) ) continue;
			if ( ! canForage( me.disguise, prop.type ) ) continue;
			const d = Math.hypot( prop.x - pos.x, prop.z - pos.z );
			if ( d < bestD ) {

				bestD = d;
				best = prop;

			}

		}

		return best;

	}

	#updateSpectator( dt ) {

		const alive = [ ...this.client.players.values() ].filter( ( p ) => p.alive && p.team );
		if ( this.input.wasPressed( 'nextSpectate' ) || this.input.primaryPressed ) this.spectateIndex ++;
		const target = alive.length ? alive[ this.spectateIndex % alive.length ] : null;
		const focus = target ? this.views.get( target.id )?.root.position : this.controller.position;
		this.cameraRig.update( dt, focus ?? this.controller.position, 1.5, 3 );
		this.hud.setPrompt( target ? `Spectating ${target.name}  ·  N to switch` : '' );

	}

	#updateOutlines( me ) {

		const now = performance.now();
		const objects = [];
		let color = REVEAL_COLOR;

		if ( me?.team === 'hider' && me.alive ) {

			color = TEAMMATE_COLOR;
			for ( const p of this.client.players.values() ) {

				if ( p.id !== this.client.you && p.team === 'hider' && p.alive ) {

					const v = this.views.get( p.id );
					if ( v ) objects.push( v.root );

				}

			}

		} else {

			for ( const [ id, until ] of this.revealed ) {

				if ( until < now ) {

					this.revealed.delete( id );
					continue;

				}

				const v = this.views.get( id );
				if ( v ) objects.push( v.root );

			}

		}

		this.renderer.setOutlined( objects, color );

	}

	render() {

		if ( this.ready ) this.renderer.render();

	}

	dispose() {

		for ( const off of this.disposers ) off();
		this.disposers.length = 0;
		this.hud?.el.remove();
		this.lobby?.el.remove();
		this.renderer.setOutlined( [] );
		this.net.dispose();

	}

}

function esc( s ) {

	return String( s ).replace( /[&<>"']/g, ( ch ) => ( { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&#39;' }[ ch ] ) );

}
