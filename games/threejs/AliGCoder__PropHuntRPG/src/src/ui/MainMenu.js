import { h } from './dom.js';

const REPO_URL = 'https://github.com/AliGCoder/PropHuntRPG';

/**
 * Title screen. Emits callbacks only – it never touches networking itself.
 */
export class MainMenu {

	constructor( { store, quality, backend, onSolo, onHost, onJoin, onSkills, onQuality } ) {

		this.store = store;
		const name = h( 'input.input', { value: store.name, maxLength: 16, placeholder: 'Your name', oninput: ( e ) => ( store.name = e.target.value ) } );
		const code = h( 'input.input', { placeholder: 'CODE', maxLength: 8, style: { textTransform: 'uppercase', letterSpacing: '0.2em' } } );
		this.status = h( 'div.muted', { style: { minHeight: '20px', fontSize: '13px' } } );

		const qualitySelect = h( 'select.input', { onchange: ( e ) => onQuality( e.target.value ) },
			[ 'high', 'medium', 'low' ].map( ( q ) => h( 'option', { value: q, selected: q === quality }, q[ 0 ].toUpperCase() + q.slice( 1 ) ) )
		);

		this.el = h( 'div.menu',
			h( 'div.menu-side',
				h( 'h1.title', 'PROPHUNT', h( 'br' ), 'RPG', h( 'small', 'HIDE · HUNT · LEVEL UP' ) ),
				h( 'p.tagline', 'Disguise as anything you\'ve unlocked. Chop, mine and fish your way to a bigger wardrobe, sharper tools and better tricks. Your skills stay with your character between rounds.' ),

				h( 'div.col', h( 'span.label', 'Character' ), name ),

				h( 'div.col',
					h( 'button.btn.primary', { onclick: () => onSolo() }, '▶  Single Player (with bots)' ),
					h( 'button.btn', { onclick: () => onHost() }, '🌐  Host Online Lobby' ),
					h( 'div.row', code, h( 'button.btn', { onclick: () => onJoin( code.value ) }, 'Join' ) ),
					h( 'button.btn', { onclick: () => onSkills() }, '📜  Skills & Wardrobe' ),
					this.status
				),

				h( 'div.col', h( 'span.label', 'Graphics' ), h( 'div.row', qualitySelect, h( 'span.muted', { style: { fontSize: '12px', whiteSpace: 'nowrap' } }, backend ) ) ),

				h( 'div.col',
					h( 'span.label', 'Controls' ),
					h( 'div.controls-grid',
						h( 'span', h( 'kbd', 'WASD' ) ), h( 'span', 'Move   ·   ', h( 'kbd', 'Shift' ), ' sprint   ·   ', h( 'kbd', 'Space' ), ' jump' ),
						h( 'span', h( 'kbd', 'E' ) ), h( 'span', 'Disguise as the prop you aim at (hider)' ),
						h( 'span', h( 'kbd', 'Click' ) ), h( 'span', 'Swing tool / gather (hunter)' ),
						h( 'span', h( 'kbd', 'F' ) ), h( 'span', 'Hold to forage next to a resource (hider)' ),
						h( 'span', h( 'kbd', 'Q' ) ), h( 'span', 'Trade ability' ),
						h( 'span', h( 'kbd', 'R' ) ), h( 'span', 'Lock prop rotation   ·   ', h( 'kbd', 'T' ), ' taunt' ),
						h( 'span', h( 'kbd', 'Tab' ) ), h( 'span', 'Skills panel' )
					)
				),

				h( 'div.menu-footer',
					h( 'a', { href: REPO_URL, target: '_blank', rel: 'noopener' }, 'GitHub' ),
					h( 'span', 'MIT licensed' ),
					h( 'span', 'three.js WebGPU + TSL' )
				)
			)
		);

	}

	setStatus( text, isError = false ) {

		this.status.textContent = text;
		this.status.style.color = isError ? 'var(--bad)' : '';

	}

}
