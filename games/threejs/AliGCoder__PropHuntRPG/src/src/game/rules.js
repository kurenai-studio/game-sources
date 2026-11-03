/**
 * All balance numbers and formulas in one place. Pure functions only, so they
 * are trivially unit-testable (see tests/rules.test.js).
 */
import { PROP_TYPES } from '../world/PropCatalog.js';
import { SKILLS, MAX_LEVEL } from '../skills/skills.js';

export const BALANCE = Object.freeze( {
	hiderBaseHp: 100,
	hunterBaseHp: 100,
	toolBaseDamage: 25,
	toolReach: 2.6,
	swingCooldown: 0.55,
	wrongPropPenalty: 6,
	familyBonus: 0.25,
	disguiseCooldown: 2.5,
	disguiseRange: 7,
	forageRange: 4.5,
	forageInterval: 1.4,
	nodeRespawnSeconds: 45,
	maxDecoys: 2,
	xp: {
		forage: 8,
		elimination: 60,
		survive: 120,
		eliminatedParticipation: 25,
		agilitySurvive: 40,
		agilityPerMetre: 0.25,
		agilityCap: 60,
		win: 30
	}
} );

/** Linear perk from 0 at level 1 to `cap` at MAX_LEVEL. */
const pct = ( level, cap ) => cap * Math.min( 1, Math.max( 0, ( level - 1 ) / ( MAX_LEVEL - 1 ) ) );

/** Can a player with these levels disguise as this prop type? */
export function canDisguiseAs( typeId, levels ) {

	const def = PROP_TYPES[ typeId ];
	if ( ! def || def.disguisable === false ) return false;
	if ( def.skill === 'general' ) return true;
	return ( levels?.[ def.skill ] ?? 1 ) >= def.level;

}

/** Hider max HP when disguised as `typeId`. */
export function hiderMaxHp( typeId, levels ) {

	const def = PROP_TYPES[ typeId ];
	const skillLevel = def && def.skill !== 'general' ? levels?.[ def.skill ] ?? 1 : 1;
	return Math.round( BALANCE.hiderBaseHp * ( 1 + pct( skillLevel, 0.4 ) ) );

}

/** Damage a hunter with `trade` deals to a hider disguised as `targetType`. */
export function toolDamage( trade, levels, targetType ) {

	const def = PROP_TYPES[ targetType ];
	let dmg = BALANCE.toolBaseDamage * ( 1 + pct( levels?.[ trade ] ?? 1, 0.3 ) );
	if ( def && def.skill === trade ) dmg *= 1 + BALANCE.familyBonus;
	return Math.round( dmg );

}

/** Ability cooldown after the trade-level reduction. */
export function abilityCooldown( baseSeconds, trade, levels ) {

	return baseSeconds * ( 1 - pct( levels?.[ trade ] ?? 1, 0.4 ) );

}

/** Movement speed multiplier from Agility. */
export function agilitySpeed( levels ) {

	return 1 + pct( levels?.agility ?? 1, 0.15 );

}

/** Is a hunter's tool the right one to gather this node? */
export function toolGathers( trade, typeId ) {

	const node = PROP_TYPES[ typeId ]?.node;
	return !! node && node.skill === trade;

}

/** Is a hider allowed to forage this node while disguised as `disguiseType`? */
export function canForage( disguiseType, nodeType ) {

	const d = PROP_TYPES[ disguiseType ], n = PROP_TYPES[ nodeType ];
	return !! ( d && n?.node && d.skill === n.node.skill );

}

/** Number of hunters for a lobby size. */
export function hunterCount( players ) {

	return Math.max( 1, Math.round( players / 4 ) );

}

export function toolForTrade( trade ) {

	return SKILLS[ trade ]?.tool ?? 'axe';

}
