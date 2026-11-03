/**
 * Keyboard + mouse input with pointer lock. Gameplay code asks for *actions*
 * ("jump", "ability") rather than raw keys so bindings live in one place.
 */
export const BINDINGS = Object.freeze( {
	forward: [ 'KeyW', 'ArrowUp' ],
	back: [ 'KeyS', 'ArrowDown' ],
	left: [ 'KeyA', 'ArrowLeft' ],
	right: [ 'KeyD', 'ArrowRight' ],
	jump: [ 'Space' ],
	sprint: [ 'ShiftLeft', 'ShiftRight' ],
	disguise: [ 'KeyE' ],
	gather: [ 'KeyF' ],
	ability: [ 'KeyQ', 'Digit1' ],
	lockRotation: [ 'KeyR' ],
	taunt: [ 'KeyT' ],
	skills: [ 'Tab' ],
	nextSpectate: [ 'KeyN' ]
} );

export class Input {

	constructor( element ) {

		this.element = element;
		this.down = new Set();
		this.pressed = new Set();     // pressed this frame
		this.mouseDX = 0;
		this.mouseDY = 0;
		this.primaryDown = false;
		this.primaryPressed = false;
		this.enabled = true;
		this.sensitivity = 0.0022;

		this._onKeyDown = ( e ) => {

			if ( ! this.enabled || isTyping( e ) ) return;
			if ( e.code === 'Tab' ) e.preventDefault();
			if ( ! this.down.has( e.code ) ) this.pressed.add( e.code );
			this.down.add( e.code );

		};

		this._onKeyUp = ( e ) => this.down.delete( e.code );
		this._onMouseMove = ( e ) => {

			if ( ! this.isLocked ) return;
			this.mouseDX += e.movementX;
			this.mouseDY += e.movementY;

		};

		this._onMouseDown = ( e ) => {

			if ( ! this.enabled ) return;
			if ( ! this.isLocked && e.target === element ) {

				this.requestLock();
				return;

			}

			if ( e.button === 0 ) {

				this.primaryDown = true;
				this.primaryPressed = true;

			}

		};

		this._onMouseUp = ( e ) => {

			if ( e.button === 0 ) this.primaryDown = false;

		};

		this._onBlur = () => {

			this.down.clear();
			this.primaryDown = false;

		};

		window.addEventListener( 'keydown', this._onKeyDown );
		window.addEventListener( 'keyup', this._onKeyUp );
		window.addEventListener( 'mousemove', this._onMouseMove );
		window.addEventListener( 'mousedown', this._onMouseDown );
		window.addEventListener( 'mouseup', this._onMouseUp );
		window.addEventListener( 'blur', this._onBlur );

	}

	get isLocked() {

		return document.pointerLockElement === this.element;

	}

	requestLock() {

		this.element.requestPointerLock?.()?.catch?.( () => {} );

	}

	exitLock() {

		if ( this.isLocked ) document.exitPointerLock();

	}

	isDown( action ) {

		return BINDINGS[ action ].some( ( c ) => this.down.has( c ) );

	}

	wasPressed( action ) {

		return BINDINGS[ action ].some( ( c ) => this.pressed.has( c ) );

	}

	/** Consume mouse delta accumulated since last frame. */
	consumeMouse() {

		const d = { x: this.mouseDX * this.sensitivity, y: this.mouseDY * this.sensitivity };
		this.mouseDX = 0;
		this.mouseDY = 0;
		return d;

	}

	/** Call at the end of each frame. */
	endFrame() {

		this.pressed.clear();
		this.primaryPressed = false;

	}

	dispose() {

		window.removeEventListener( 'keydown', this._onKeyDown );
		window.removeEventListener( 'keyup', this._onKeyUp );
		window.removeEventListener( 'mousemove', this._onMouseMove );
		window.removeEventListener( 'mousedown', this._onMouseDown );
		window.removeEventListener( 'mouseup', this._onMouseUp );
		window.removeEventListener( 'blur', this._onBlur );

	}

}

function isTyping( e ) {

	const t = e.target;
	return t && ( t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable );

}
