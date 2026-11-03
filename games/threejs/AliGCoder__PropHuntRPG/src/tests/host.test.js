import { test } from 'node:test';
import assert from 'node:assert/strict';
import { HostServer } from '../src/game/HostServer.js';
import { MapLayout } from '../src/world/MapLayout.js';
import { C2S, S2C, EV, PHASES } from '../src/net/protocol.js';
import { CONFIG } from '../src/config.js';

function setup() {

	const server = new HostServer( { seed: 12345, hostId: 'h' } );
	const inbox = [];
	server.addClient( 'h', ( m ) => inbox.push( m ) );
	server.onMessage( 'h', { t: C2S.HELLO, profile: { name: 'Tester', levels: { woodcutting: 30 } } } );
	return { server, inbox };

}

test( 'map generation is deterministic', () => {

	const a = new MapLayout( 777 ), b = new MapLayout( 777 );
	assert.equal( a.props.length, b.props.length );
	assert.ok( a.props.length > 150, `expected a populated map, got ${a.props.length}` );
	assert.deepEqual( a.props.slice( 0, 20 ), b.props.slice( 0, 20 ) );
	assert.ok( a.props.some( ( p ) => p.type === 'fishing_spot' ) );

} );

test( 'welcome + lobby flow', () => {

	const { server, inbox } = setup();
	const welcome = inbox.find( ( m ) => m.t === S2C.WELCOME );
	assert.ok( welcome );
	assert.equal( welcome.you, 'h' );
	assert.equal( welcome.state.players[ 0 ].levels.woodcutting, 30 );

	server.onMessage( 'h', { t: C2S.START } );
	assert.equal( server.phase, PHASES.LOBBY, 'cannot start alone' );

	server.onMessage( 'h', { t: C2S.ADD_BOT } );
	server.onMessage( 'h', { t: C2S.ADD_BOT } );
	server.onMessage( 'h', { t: C2S.START } );
	assert.equal( server.phase, PHASES.PREP );
	const teams = [ ...server.players.values() ].map( ( p ) => p.team );
	assert.equal( teams.filter( ( t ) => t === 'hunter' ).length, 1 );

} );

test( 'a full round with bots completes and awards XP', () => {

	const { server, inbox } = setup();
	for ( let i = 0; i < 4; i ++ ) server.addBot();
	server.startRound();

	const dt = 1 / 30;
	const total = CONFIG.round.prepSeconds + CONFIG.round.huntSeconds + 2;
	let ended = false;
	for ( let t = 0; t < total && ! ended; t += dt ) {

		server.tick( dt );
		ended = server.phase === PHASES.RESULTS;

	}

	assert.equal( ended, true, 'round should reach results' );
	const roundEnd = inbox.find( ( m ) => m.t === S2C.EVENT && m.e === EV.ROUND_END );
	assert.ok( roundEnd, 'roundEnd event sent' );
	assert.ok( [ 'hunter', 'hider' ].includes( roundEnd.winner ) );
	assert.ok( inbox.some( ( m ) => m.e === EV.XP ), 'human player earns XP' );

	// Bots disguised during prep
	const hiders = [ ...server.players.values() ].filter( ( p ) => p.team === 'hider' && p.isBot );
	assert.ok( hiders.some( ( p ) => p.disguise ), 'at least one bot hider disguised' );

} );

test( 'speed hacks are rejected', () => {

	const { server, inbox } = setup();
	const p = server.players.get( 'h' );
	const before = [ ...p.pos ];
	server.tick( 0.05 );
	server.onMessage( 'h', { t: C2S.POS, p: [ before[ 0 ] + 50, before[ 1 ], before[ 2 ] ], yaw: 0 } );
	assert.deepEqual( p.pos, before );
	assert.ok( inbox.some( ( m ) => m.e === EV.TELEPORT && m.id === 'h' ) );

} );

test( 'locked disguises are refused', () => {

	const { server } = setup();
	server.addBot();
	server.startRound();
	const me = server.players.get( 'h' );
	me.team = 'hider';
	me.levels.fishing = 1;
	const boat = server.layout.props.find( ( p ) => p.type === 'rowboat' );
	if ( ! boat ) return; // map variant without boats
	me.pos = [ boat.x + 1, boat.y, boat.z ];
	server.onMessage( 'h', { t: C2S.DISGUISE, type: 'rowboat', index: boat.index } );
	assert.equal( me.disguise, null );

} );
