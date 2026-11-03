import { h, clear } from './dom.js';
import { SKILLS, TRADES } from '../skills/skills.js';
import { ABILITIES } from '../game/abilities.js';

/**
 * In-world lobby sidebar: lobby code, players, trade selection and host
 * controls. Re-renders from the ClientSession on every snapshot.
 */
export class LobbyPanel {

	constructor( { client, code, mode, onLeave, onTrade } ) {

		this.client = client;
		this.code = code;
		this.mode = mode;
		this.onLeave = onLeave;
		this.onTrade = onTrade;
		this.el = h( 'div.panel.lobby' );
		this.lastKey = '';

	}

	update() {

		const c = this.client;
		const me = c.me;
		const players = [ ...c.players.values() ];
		const key = JSON.stringify( [ players.map( ( p ) => [ p.id, p.name, p.trade, p.ready, p.levels ] ), c.isHost ] );
		if ( key === this.lastKey ) return;
		this.lastKey = key;
		clear( this.el );

		const trade = me?.trade ?? TRADES[ 0 ];
		const levels = me?.levels ?? {};

		this.el.append(
			h( 'div.row',
				h( 'div.grow',
					h( 'div.label', this.mode === 'solo' ? 'Single player' : 'Lobby code' ),
					this.mode === 'solo' ? h( 'div', { style: { fontSize: '22px', fontWeight: 800 } }, 'Practice vs bots' ) : h( 'div.lobby-code', this.code )
				),
				this.mode !== 'solo' ? h( 'button.btn.small', { onclick: () => navigator.clipboard?.writeText( this.code ) }, 'Copy' ) : null
			),

			h( 'div.col',
				h( 'div.label', `Players (${players.length}/16)` ),
				h( 'div.player-list', players.map( ( p ) => h( 'div.player-row',
					h( 'span', SKILLS[ p.trade ]?.icon ?? '' ),
					h( 'b', p.name, p.id === c.hostId ? ' 👑' : '', p.id === c.you ? ' (you)' : '' ),
					! p.isBot && p.id !== c.hostId ? h( 'span', { style: { color: p.ready ? 'var(--good)' : 'var(--muted)', fontSize: '12px' } }, p.ready ? 'ready' : 'not ready' ) : null,
					h( 'span.levels', `🪓${p.levels?.woodcutting ?? 1} ⛏️${p.levels?.mining ?? 1} 🎣${p.levels?.fishing ?? 1}` )
				) ) )
			),

			h( 'div.col',
				h( 'div.label', 'Your trade this round' ),
				h( 'div.trade-grid', TRADES.map( ( t ) => h( 'div.trade-card' + ( t === trade ? '.selected' : '' ), { onclick: () => this.onTrade( t ) },
					h( 'div.icon', SKILLS[ t ].icon ),
					h( 'div.name', SKILLS[ t ].name ),
					h( 'div.lvl', `Level ${levels[ t ] ?? 1}` )
				) ) ),
				h( 'div.trade-info',
					h( 'div', '🎯 Hunter: ', h( 'b', SKILLS[ trade ].toolName ), ' + ', h( 'b', ABILITIES.hunter[ trade ].name ), ' — ', ABILITIES.hunter[ trade ].description ),
					h( 'div', { style: { marginTop: '6px' } }, '🫥 Hider: ', h( 'b', ABILITIES.hider[ trade ].name ), ' — ', ABILITIES.hider[ trade ].description )
				)
			),

			h( 'div.col', { style: { marginTop: 'auto' } },
				c.isHost ? h( 'div.row',
					h( 'button.btn.small.grow', { onclick: () => c.addBot() }, '+ Add bot' ),
					h( 'button.btn.small.grow', { onclick: () => c.removeBot() }, '− Remove bot' )
				) : null,
				c.isHost
					? h( 'button.btn.primary', { onclick: () => c.startGame(), disabled: players.length < 2 }, players.length < 2 ? 'Add a bot or wait for players' : 'Start round' )
					: h( 'button.btn.primary', { onclick: () => c.toggleReady() }, me?.ready ? 'Ready ✓' : 'Ready up' ),
				h( 'button.btn.small', { onclick: () => this.onLeave() }, 'Leave' )
			)
		);

	}

}
