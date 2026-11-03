import { CONFIG } from '../config.js';
import { HostServer } from '../game/HostServer.js';
import { ClientSession } from './ClientSession.js';

/**
 * Session factories. Each returns `{ client, server?, code?, dispose() }`.
 *
 *  - createLocalGame : single player – host + client in memory, no network.
 *  - hostOnlineGame  : you host a P2P lobby; others join with the code.
 *  - joinOnlineGame  : connect to someone else's lobby code.
 *
 * Signalling uses the public PeerJS broker by default; WebRTC data channels
 * then carry all game traffic directly between browsers.
 */

const CODE_CHARS = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

export function generateLobbyCode( length = CONFIG.net.codeLength ) {

	let s = '';
	const bytes = crypto.getRandomValues( new Uint8Array( length ) );
	for ( const b of bytes ) s += CODE_CHARS[ b % CODE_CHARS.length ];
	return s;

}

function randomSeed() {

	return crypto.getRandomValues( new Uint32Array( 1 ) )[ 0 ];

}

/** Runs the host simulation on a fixed timer (keeps going if the tab blurs). */
class HostRunner {

	constructor( server, hz = 30 ) {

		this.server = server;
		let last = performance.now();
		this.interval = setInterval( () => {

			const now = performance.now();
			const dt = Math.min( 0.25, ( now - last ) / 1000 );
			last = now;
			server.tick( dt );

		}, 1000 / hz );

	}

	dispose() {

		clearInterval( this.interval );

	}

}

/** Connect a ClientSession to a HostServer in memory (async, like a network). */
function linkLocal( server, id, profile ) {

	const client = new ClientSession( ( msg ) => queueMicrotask( () => server.onMessage( id, msg ) ), profile );
	server.addClient( id, ( msg ) => queueMicrotask( () => client.receive( structuredClone( msg ) ) ) );
	client.hello();
	return client;

}

export function createLocalGame( profile ) {

	const hostId = 'local';
	const server = new HostServer( { seed: randomSeed(), hostId } );
	const client = linkLocal( server, hostId, profile );
	const runner = new HostRunner( server );
	return {
		mode: 'solo',
		client,
		server,
		dispose() {

			runner.dispose();

		}
	};

}

async function loadPeer() {

	const mod = await import( 'peerjs' );
	return mod.Peer ?? mod.default;

}

function peerOptions() {

	// Override with your own PeerServer / TURN in production if needed.
	return { debug: 1 };

}

export async function hostOnlineGame( profile ) {

	const Peer = await loadPeer();
	const code = generateLobbyCode();
	const peer = new Peer( CONFIG.net.peerPrefix + code, peerOptions() );

	await new Promise( ( resolve, reject ) => {

		peer.once( 'open', resolve );
		peer.once( 'error', reject );

	} );

	const hostId = 'host';
	const server = new HostServer( { seed: randomSeed(), hostId } );
	const client = linkLocal( server, hostId, profile );
	const runner = new HostRunner( server );

	peer.on( 'connection', ( conn ) => {

		const id = conn.peer;
		// Register immediately; sends are dropped until the channel is open.
		server.addClient( id, ( msg ) => conn.open && conn.send( msg ) );
		conn.on( 'data', ( msg ) => server.onMessage( id, msg ) );
		conn.on( 'close', () => server.removeClient( id ) );
		conn.on( 'error', () => server.removeClient( id ) );

	} );

	peer.on( 'disconnected', () => peer.reconnect() );

	return {
		mode: 'host',
		code,
		client,
		server,
		dispose() {

			runner.dispose();
			peer.destroy();

		}
	};

}

export async function joinOnlineGame( code, profile ) {

	const Peer = await loadPeer();
	const peer = new Peer( peerOptions() );

	await new Promise( ( resolve, reject ) => {

		peer.once( 'open', resolve );
		peer.once( 'error', reject );

	} );

	const conn = peer.connect( CONFIG.net.peerPrefix + code.trim().toUpperCase(), { reliable: true, serialization: 'json' } );
	const client = new ClientSession( ( msg ) => conn.open && conn.send( msg ), profile );

	await new Promise( ( resolve, reject ) => {

		const timer = setTimeout( () => reject( new Error( 'Lobby not found or unreachable' ) ), 12000 );
		conn.once( 'open', () => {

			clearTimeout( timer );
			resolve();

		} );
		peer.once( 'error', ( err ) => {

			clearTimeout( timer );
			reject( err );

		} );

	} );

	conn.on( 'data', ( msg ) => client.receive( msg ) );
	conn.on( 'close', () => client.disconnect() );
	client.hello();

	return {
		mode: 'client',
		code,
		client,
		dispose() {

			peer.destroy();

		}
	};

}
