import * as THREE from 'three/webgpu';
import { h, clear, formatTime } from './dom.js';
import { SKILLS } from '../skills/skills.js';
import { getAbility } from '../game/abilities.js';
import { PHASES } from '../net/protocol.js';

const _v = new THREE.Vector3();

const PHASE_LABEL = { lobby: 'Lobby', prep: 'Hiders, hide!', hunt: 'Hunt', results: 'Round over' };

/**
 * In-game heads-up display. Purely presentational: GameSession pushes state
 * in through `update()` and the various `show*` methods.
 */
export class Hud {

	constructor() {

		this.timer = h( 'span.timer', '0:00' );
		this.phaseLabel = h( 'span' );
		this.teamBadge = h( 'span.team-badge' );
		this.counts = h( 'span.counts' );
		this.prompt = h( 'div.prompt.panel' );
		this.crosshair = h( 'div.crosshair' );
		this.hpFill = h( 'div' );
		this.hpText = h( 'span.muted', { style: { fontSize: '12px' } } );
		this.vitalsTitle = h( 'b' );
		this.abilityIcon = h( 'span' );
		this.abilityName = h( 'span.ability-name' );
		this.abilityCd = h( 'div.cd' );
		this.hints = h( 'div.hints.panel' );
		this.feed = h( 'div.feed' );
		this.xpStack = h( 'div.xp-stack' );
		this.floaters = h( 'div' );
		this.vignette = h( 'div.vignette' );
		this.blindfold = h( 'div.blindfold', { style: { display: 'none' } },
			h( 'h1', 'You are blindfolded' ),
			h( 'div.muted', 'The hiders are choosing their disguises…' ),
			this.blindTimer = h( 'div.big', '30' )
		);
		this.clickToPlay = h( 'div.click-to-play.panel', { style: { display: 'none' } }, 'Click to capture the mouse' );
		this.transient = h( 'div' );

		this.vitals = h( 'div.vitals.panel',
			h( 'div.row', this.vitalsTitle, h( 'span.grow' ), this.hpText ),
			h( 'div.hp-bar', this.hpFill )
		);
		this.abilityBox = h( 'div.ability.panel', h( 'span.key', 'Q' ), this.abilityIcon, this.abilityName, this.abilityCd );

		this.top = h( 'div.hud-top', h( 'div.panel.phase-pill', this.phaseLabel, this.timer, this.teamBadge, this.counts ) );
		this.el = h( 'div.hud',
			this.vignette,
			this.top,
			this.crosshair,
			this.prompt,
			h( 'div.hud-bottom', this.vitals, this.abilityBox ),
			this.hints,
			this.feed,
			this.xpStack,
			this.floaters,
			this.transient,
			this.clickToPlay,
			this.blindfold
		);

		this.cooldownEnds = 0;
		this.hurtTimer = 0;
		this.lastHintsKey = '';

	}

	setInGameVisible( visible ) {

		for ( const el of [ this.crosshair, this.vitals, this.abilityBox, this.hints, this.prompt ] ) el.style.display = visible ? '' : 'none';

	}

	update( dt, { client, me, revealCount, pointerLocked } ) {

		const phase = client.phase;
		this.top.style.display = phase === PHASES.LOBBY ? 'none' : '';
		this.phaseLabel.textContent = PHASE_LABEL[ phase ] ?? phase;
		this.timer.textContent = phase === PHASES.LOBBY ? '--:--' : formatTime( client.timeLeft );
		this.timer.style.display = phase === PHASES.LOBBY ? 'none' : '';

		const team = me?.alive && me.team ? me.team : ( phase === PHASES.LOBBY ? null : 'spectator' );
		this.teamBadge.className = 'team-badge ' + ( team ?? '' );
		this.teamBadge.textContent = team ? ( team === 'hunter' ? 'Hunter' : team === 'hider' ? 'Hider' : 'Spectating' ) : '';
		this.teamBadge.style.display = team ? '' : 'none';

		let hiders = 0, hunters = 0;
		for ( const p of client.players.values() ) {

			if ( ! p.alive ) continue;
			if ( p.team === 'hider' ) hiders ++;
			else if ( p.team === 'hunter' ) hunters ++;

		}

		this.counts.textContent = phase === PHASES.LOBBY ? '' : `🫥 ${hiders}  ·  🎯 ${hunters}`;

		const inRound = phase !== PHASES.LOBBY;
		this.setInGameVisible( inRound && !! me?.alive && !! me.team );

		if ( me ) {

			const pct = me.maxHp ? me.hp / me.maxHp : 0;
			this.hpFill.style.width = `${Math.max( 0, pct * 100 )}%`;
			this.hpText.textContent = `${me.hp} / ${me.maxHp}`;
			this.vitalsTitle.textContent = me.team === 'hider'
				? ( me.disguise ? `Disguised${me.rooted ? ' · rooted' : ''}` : 'Not disguised!' )
				: `${SKILLS[ me.trade ]?.icon ?? ''} ${SKILLS[ me.trade ]?.toolName ?? ''}`;

			const ability = me.team ? getAbility( me.team, me.trade ) : null;
			this.abilityIcon.textContent = SKILLS[ me.trade ]?.icon ?? '';
			this.abilityName.textContent = ability?.name ?? '';
			const cd = Math.max( 0, ( this.cooldownEnds - performance.now() ) / 1000 );
			this.abilityCd.textContent = cd > 0 ? Math.ceil( cd ) : '';

			this.crosshair.className = 'crosshair' + ( me.team === 'hunter' ? '' : ' dot' );

			const hintsKey = `${me.team}|${!! me.disguise}|${revealCount}`;
			if ( hintsKey !== this.lastHintsKey ) {

				this.lastHintsKey = hintsKey;
				clear( this.hints );
				const lines = me.team === 'hunter'
					? [ [ 'Click', 'swing (wrong props hurt you!)' ], [ 'Click', 'resource nodes with your tool: free XP' ], [ 'Q', 'ability' ] ]
					: [ [ 'E', 'disguise as aimed prop' ], [ 'F', 'hold near a matching node to forage' ], [ 'R', 'lock rotation' ], [ 'Q', 'ability' ], [ 'T', 'taunt (+Agility XP)' ] ];
				for ( const [ k, text ] of lines ) this.hints.append( h( 'div', h( 'kbd', k ), ' ', text ) );

			}

		}

		const blind = phase === PHASES.PREP && me?.team === 'hunter' && me.alive;
		this.blindfold.style.display = blind ? 'flex' : 'none';
		if ( blind ) this.blindTimer.textContent = Math.ceil( client.timeLeft );

		this.clickToPlay.style.display = inRound && ! pointerLocked && ! blind ? '' : 'none';

		if ( this.hurtTimer > 0 ) {

			this.hurtTimer -= dt;
			if ( this.hurtTimer <= 0 ) this.vignette.classList.remove( 'hurt' );

		}

	}

	setPrompt( text, locked = false ) {

		if ( this.prompt.textContent !== text ) this.prompt.textContent = text;
		this.prompt.classList.toggle( 'locked', locked );

	}

	setCooldown( seconds ) {

		this.cooldownEnds = performance.now() + seconds * 1000;

	}

	hurt() {

		this.vignette.classList.add( 'hurt' );
		this.hurtTimer = 0.15;

	}

	feedItem( html ) {

		const item = h( 'div.feed-item.panel', { html } );
		this.feed.prepend( item );
		while ( this.feed.children.length > 6 ) this.feed.lastChild.remove();
		setTimeout( () => item.remove(), 6000 );

	}

	xpPopup( skill, amount, reason ) {

		const s = SKILLS[ skill ];
		const el = h( 'div.xp-pop.panel', { style: { color: s?.color } }, `+${amount} ${s?.icon ?? ''} ${s?.name ?? skill}`, reason ? h( 'span.muted', { style: { fontWeight: 400, fontSize: '12px' } }, ` · ${reason}` ) : null );
		this.xpStack.append( el );
		setTimeout( () => el.remove(), 2300 );

	}

	toast( text ) {

		const el = h( 'div.toast.panel', text );
		this.transient.append( el );
		setTimeout( () => el.remove(), 2700 );

	}

	banner( title, subtitle = '', extraClass = '' ) {

		const el = h( 'div.banner' + extraClass, h( 'h1', title ), subtitle ? h( 'p', subtitle ) : null );
		this.transient.append( el );
		setTimeout( () => el.remove(), 2900 );

	}

	levelUp( skill, level ) {

		const s = SKILLS[ skill ];
		this.banner( `${s.icon} ${s.name} ${level}!`, 'Level up — check your wardrobe (Tab)', '.levelup' );

	}

	/** Floating text anchored to a world position. */
	floatText( camera, pos, text, color = '#fff' ) {

		_v.set( pos[ 0 ], pos[ 1 ], pos[ 2 ] ).project( camera );
		if ( _v.z > 1 ) return;
		const x = ( _v.x * 0.5 + 0.5 ) * window.innerWidth;
		const y = ( - _v.y * 0.5 + 0.5 ) * window.innerHeight;
		const el = h( 'div.floater', { style: { left: x + 'px', top: y + 'px', color } }, text );
		this.floaters.append( el );
		setTimeout( () => el.remove(), 1200 );

	}

	showResults( { winner, summary, you }, onDone ) {

		const won = summary.find( ( s ) => s.id === you )?.won;
		const el = h( 'div.overlay', { style: { background: 'rgba(5,8,12,0.35)' } },
			h( 'div.panel.results',
				h( 'h2', { style: { margin: 0, fontSize: '34px', color: won ? 'var(--good)' : 'var(--bad)' } }, winner === 'hunter' ? 'Hunters win!' : 'Hiders win!' ),
				h( 'div.muted', won ? 'Victory XP awarded.' : 'XP awarded for participation.' ),
				h( 'table', summary.map( ( s ) => h( 'tr',
					h( 'td', s.team === 'hunter' ? '🎯' : '🫥' ),
					h( 'td', h( 'b', s.name ) ),
					h( 'td.muted', s.team === 'hunter' ? `${s.kills} found` : s.alive ? 'survived' : 'found' ),
					h( 'td', { style: { textAlign: 'right', color: s.won ? 'var(--good)' : 'var(--muted)' } }, s.won ? 'WIN' : '' )
				) ) ),
				h( 'div.muted', { style: { marginTop: '12px', fontSize: '13px' } }, 'Next round starting shortly… teams rotate.' )
			)
		);
		this.transient.append( el );
		setTimeout( () => {

			el.remove();
			onDone?.();

		}, 7000 );

	}

}
