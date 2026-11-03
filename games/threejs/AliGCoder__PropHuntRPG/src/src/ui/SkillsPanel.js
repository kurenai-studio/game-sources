import { h } from './dom.js';
import { SKILLS, SKILL_IDS, levelProgress, xpForLevel, MAX_LEVEL } from '../skills/skills.js';
import { PROP_TYPES, DISGUISE_IDS } from '../world/PropCatalog.js';
import { ABILITIES } from '../game/abilities.js';
import { canDisguiseAs } from '../game/rules.js';

/** Modal showing skill levels, perks, abilities and the disguise wardrobe. */
export function createSkillsPanel( store, onClose ) {

	const levels = store.levels;
	const xp = store.xp;

	const cards = SKILL_IDS.map( ( id ) => {

		const s = SKILLS[ id ];
		const lvl = levels[ id ];
		const next = lvl >= MAX_LEVEL ? 'Max level' : `${( xpForLevel( lvl + 1 ) - xp[ id ] ).toLocaleString()} XP to level ${lvl + 1}`;
		const hunterA = ABILITIES.hunter[ id ], hiderA = ABILITIES.hider[ id ];
		return h( 'div.skill-card',
			h( 'div.top', h( 'span.icon', s.icon ), h( 'b', s.name ), h( 'span.lvl', { style: { color: s.color } }, lvl ) ),
			h( 'div.xp-bar', h( 'div', { style: { width: `${levelProgress( xp[ id ] ) * 100}%`, background: s.color } } ) ),
			h( 'div.muted', { style: { fontSize: '12px', marginTop: '6px' } }, `${xp[ id ].toLocaleString()} XP · ${next}` ),
			hunterA ? h( 'div', { style: { fontSize: '12px', marginTop: '8px', lineHeight: 1.5 } },
				h( 'div', '🎯 ', h( 'b', hunterA.name ), ' — ', hunterA.description ),
				h( 'div', '🫥 ', h( 'b', hiderA.name ), ' — ', hiderA.description )
			) : h( 'div', { style: { fontSize: '12px', marginTop: '8px' } }, 'Faster movement (up to +15%). Earned by staying alive on the move.' )
		);

	} );

	const groups = [ 'general', 'woodcutting', 'mining', 'fishing' ].map( ( skill ) => {

		const items = DISGUISE_IDS.filter( ( id ) => PROP_TYPES[ id ].skill === skill )
			.sort( ( a, b ) => PROP_TYPES[ a ].level - PROP_TYPES[ b ].level )
			.map( ( id ) => {

				const def = PROP_TYPES[ id ];
				const ok = canDisguiseAs( id, levels );
				return h( 'div.wardrobe-item' + ( ok ? '' : '.locked' ),
					h( 'div', ( ok ? '' : '🔒 ' ) + def.name, def.node ? ' ⭐' : '' ),
					h( 'div.req', skill === 'general' ? 'Everyone' : `${SKILLS[ skill ].name} ${def.level}` )
				);

			} );

		return h( 'div', { style: { marginTop: '14px' } },
			h( 'div.label', { style: { marginBottom: '8px' } }, skill === 'general' ? 'General' : SKILLS[ skill ].icon + ' ' + SKILLS[ skill ].name ),
			h( 'div.wardrobe', items )
		);

	} );

	const el = h( 'div.overlay', { onclick: ( e ) => e.target === el && onClose() },
		h( 'div.panel.modal',
			h( 'div.row', h( 'h2.grow', `${store.name}'s Skills` ), h( 'button.btn.small', { onclick: onClose }, 'Close' ) ),
			h( 'div.muted', `Rounds ${store.stats.rounds} · Wins ${store.stats.wins} · Hiders found ${store.stats.eliminations} · Survived ${store.stats.survivals}` ),
			h( 'div.skill-grid', cards ),
			h( 'h3', { style: { margin: '6px 0 0' } }, 'Disguise wardrobe' ),
			h( 'div.muted', { style: { fontSize: '13px' } }, '⭐ = resource node: hunters with the matching tool can gather it with no penalty, and hiders disguised in that family can forage next to it.' ),
			groups
		)
	);

	return el;

}
