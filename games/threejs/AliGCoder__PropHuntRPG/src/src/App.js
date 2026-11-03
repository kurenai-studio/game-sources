import * as THREE from 'three/webgpu';
import { Renderer } from './render/Renderer.js';
import { buildScene } from './render/SceneBuilder.js';
import { MapLayout } from './world/MapLayout.js';
import { Input } from './core/Input.js';
import { CharacterStore } from './skills/CharacterStore.js';
import { Sfx } from './fx/Sfx.js';
import { MainMenu } from './ui/MainMenu.js';
import { createSkillsPanel } from './ui/SkillsPanel.js';
import { GameSession } from './game/GameSession.js';
import { createLocalGame, hostOnlineGame, joinOnlineGame } from './net/Network.js';
import { clear } from './ui/dom.js';

const QUALITY_KEY = 'prophunt-rpg.quality';
const MENU_SEED = 20261103;

/**
 * Top-level application: owns the renderer, input, persistent character and
 * the screen flow (menu backdrop ⇄ game session).
 */
export class App {

	constructor( { viewport, ui } ) {

		this.viewport = viewport;
		this.ui = ui;
		this.store = new CharacterStore();
		this.sfx = new Sfx();
		this.timer = new THREE.Timer();
		this.session = null;
		this.backdrop = null;
		this.overlay = null;

	}

	async start() {

		const quality = localStorage.getItem( QUALITY_KEY ) || 'high';
		this.renderer = new Renderer( this.viewport, quality );
		await this.renderer.init();
		this.input = new Input( this.renderer.domElement );

		this.showMenu();
		this.renderer.renderer.setAnimationLoop( ( t ) => this.#frame( t ) );

		// Expose for debugging / automated smoke tests
		globalThis.__prophunt = this;

	}

	// ── screens ─────────────────────────────────────────────────────────────

	showMenu() {

		this.session?.dispose();
		this.session = null;
		this.input.exitLock();
		clear( this.ui );

		const layout = new MapLayout( MENU_SEED );
		this.backdrop = { ...buildScene( this.renderer, layout ), angle: 0.6, layout };

		this.menu = new MainMenu( {
			store: this.store,
			quality: this.renderer.qualityName,
			backend: this.renderer.backendName,
			onSolo: () => this.#launch( () => createLocalGame( this.store.toProfile() ), 'solo' ),
			onHost: () => this.#launch( () => hostOnlineGame( this.store.toProfile() ), 'host' ),
			onJoin: ( code ) => {

				if ( ! code?.trim() ) return this.menu.setStatus( 'Enter a lobby code first', true );
				this.#launch( () => joinOnlineGame( code, this.store.toProfile() ), 'join' );

			},
			onSkills: () => this.toggleSkills(),
			onQuality: ( q ) => {

				localStorage.setItem( QUALITY_KEY, q );
				location.reload();

			}
		} );
		this.ui.append( this.menu.el );

	}

	async #launch( factory, label ) {

		this.sfx.click();
		this.menu.setStatus( label === 'solo' ? 'Starting…' : label === 'host' ? 'Opening lobby…' : 'Connecting…' );
		let net;
		try {

			net = await factory();

		} catch ( err ) {

			console.error( err );
			this.menu.setStatus( `Could not connect: ${err?.message ?? err}`, true );
			return;

		}

		clear( this.ui );
		this.backdrop = null;
		const session = new GameSession( {
			net,
			renderer: this.renderer,
			input: this.input,
			store: this.store,
			sfx: this.sfx,
			ui: this.ui,
			onLeave: () => this.showMenu(),
			openSkills: () => this.toggleSkills()
		} );
		this.session = session;
		await session.start();

		// Single player: drop in a few bots automatically so you can test instantly
		if ( net.mode === 'solo' ) for ( let i = 0; i < 3; i ++ ) net.client.addBot();

	}

	toggleSkills() {

		if ( this.overlay ) {

			this.overlay.remove();
			this.overlay = null;
			return;

		}

		this.input.exitLock();
		this.overlay = createSkillsPanel( this.store, () => this.toggleSkills() );
		this.ui.append( this.overlay );

	}

	// ── loop ────────────────────────────────────────────────────────────────

	#frame( timestamp ) {

		this.timer.update( timestamp );
		const dt = Math.min( 0.05, this.timer.getDelta() );

		if ( this.session ) {

			this.session.update( dt );
			this.session.render();

		} else if ( this.backdrop ) {

			const b = this.backdrop;
			b.angle += dt * 0.04;
			const r = 46;
			b.camera.position.set( Math.cos( b.angle ) * r, 16, Math.sin( b.angle ) * r );
			b.camera.lookAt( 0, 2, 0 );
			b.effects.update( dt );
			this.renderer.render();

		}

		this.input.endFrame();

	}

}
