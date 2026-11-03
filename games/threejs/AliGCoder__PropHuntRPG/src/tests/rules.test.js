import { test } from 'node:test';
import assert from 'node:assert/strict';
import { xpForLevel, levelForXp, clampLevels, MAX_LEVEL } from '../src/skills/skills.js';
import { canDisguiseAs, hiderMaxHp, toolDamage, abilityCooldown, canForage, toolGathers, hunterCount } from '../src/game/rules.js';

test( 'xp curve round-trips', () => {

	for ( let l = 1; l <= MAX_LEVEL; l ++ ) assert.equal( levelForXp( xpForLevel( l ) ), l );
	assert.equal( levelForXp( xpForLevel( 10 ) - 1 ), 9 );
	assert.equal( levelForXp( 1e9 ), MAX_LEVEL );

} );

test( 'untrusted levels are clamped', () => {

	const l = clampLevels( { woodcutting: 999, mining: - 4, fishing: 'x' } );
	assert.deepEqual( l, { woodcutting: MAX_LEVEL, mining: 1, fishing: 1, agility: 1 } );

} );

test( 'disguise unlocks follow skill levels', () => {

	const lv1 = clampLevels( {} );
	assert.equal( canDisguiseAs( 'crate', lv1 ), true );
	assert.equal( canDisguiseAs( 'bucket', lv1 ), true );
	assert.equal( canDisguiseAs( 'oak', lv1 ), false );
	assert.equal( canDisguiseAs( 'oak', { ...lv1, woodcutting: 20 } ), true );
	assert.equal( canDisguiseAs( 'cottage', { ...lv1, woodcutting: 50 } ), false );

} );

test( 'perks are capped and modest', () => {

	const max = clampLevels( { woodcutting: 50, mining: 50, fishing: 50, agility: 50 } );
	const min = clampLevels( {} );
	assert.equal( hiderMaxHp( 'oak', max ), 140 );
	assert.equal( hiderMaxHp( 'crate', min ), 100 );
	assert.ok( toolDamage( 'woodcutting', max, 'crate' ) <= 33 );
	assert.ok( toolDamage( 'woodcutting', max, 'oak' ) > toolDamage( 'woodcutting', max, 'crate' ) );
	assert.ok( Math.abs( abilityCooldown( 20, 'mining', max ) - 12 ) < 0.6 );

} );

test( 'gathering and foraging families', () => {

	assert.equal( toolGathers( 'woodcutting', 'oak' ), true );
	assert.equal( toolGathers( 'mining', 'oak' ), false );
	assert.equal( toolGathers( 'woodcutting', 'stump' ), false );
	assert.equal( canForage( 'log_pile', 'pine' ), true );
	assert.equal( canForage( 'crate', 'pine' ), false );
	assert.equal( canForage( 'barrel', 'fishing_spot' ), true );

} );

test( 'hunter counts scale with lobby size', () => {

	assert.equal( hunterCount( 2 ), 1 );
	assert.equal( hunterCount( 8 ), 2 );
	assert.equal( hunterCount( 16 ), 4 );

} );
