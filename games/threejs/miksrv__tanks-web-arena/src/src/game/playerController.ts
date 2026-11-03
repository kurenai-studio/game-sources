import { AMMO, AMMO_IDS, DRIVE } from '../config'
import type { CameraRig } from '../camera'
import type { Shells } from '../combat/shells'
import type { Audio } from '../fx/audio'
import type { Hud } from '../hud'
import type { Input } from '../input'
import type { Plane } from '../plane/plane'
import type { Tank } from '../tank/tank'
import type { Phase } from './match'
import { COLOR } from './messages'
import { Spotting } from './spotting'

/**
 * Team signals: T — attack (the enemy under the reticle, or that spot), G — help me, B — defend the base; or all
 * three on the radial menu while Q is held.
 */
export type Signal = 'attack' | 'help' | 'defend'
const SIGNAL_KEYS: [string, Signal][] = [
	['KeyT', 'attack'],
	['KeyG', 'help'],
	['KeyB', 'defend'],
]

const MENU_KEY = 'KeyQ'
const SHOT_BUFFER = 0.3 // s: a click this close to the end of the reload fires the moment the gun is loaded
const RELOAD_CUE_MIN = 2 // s: guns that reload faster than this (autocannons) give no "loaded" cue

/**
 * Keyboard and mouse → the player's tank, camera modes and consumables; spectating teammates after death; the plane
 * (V calls it in and back) while it flies.
 */
export class PlayerController {
	/** The teammate the camera follows once the player is dead. */
	spectating: Tank | null = null
	/** A click that came just before the reload ended. */
	private queuedShot = false
	/** The gun was reloading last frame (for the "loaded" cue). */
	private loading = false
	/** The enemy saw the player last frame (for the sixth sense). */
	private seen = false
	/** The reticle has opened up since it last converged: the next convergence gets the "aimed" cue. */
	private aimArmed = false
	/** A team signal key was pressed (the game hands it to the bots). */
	onSignal: ((s: Signal) => void) | null = null

	constructor(
		private readonly input: Input,
		private readonly rig: CameraRig,
		private readonly hud: Hud,
		private readonly audio: Audio,
		private readonly shells: Shells,
		private readonly plane: Plane,
	) {}

	resetRound() {
		this.plane.reset()
		this.spectating = null
		this.queuedShot = this.loading = this.seen = this.aimArmed = false
	}

	/** The tank the camera should follow this frame. */
	cameraTarget(player: Tank): Tank {
		return player.alive ? player : (this.spectating ?? player)
	}

	update(player: Tank, tanks: Tank[], phase: Phase, time: number) {
		this.globalKeys()
		this.sixthSense(player, time)
		this.aimCue(player)
		const menu = this.signalMenu(player, phase)
		if (!this.input.locked) {
			player.throttle = player.steer = 0
			this.plane.throttleAxis = 0
			return
		}
		if (this.plane.active) {
			this.fly(player, phase)
			return
		}
		// The plane has crashed or gone back: the camera returns to the tank
		if (this.rig.mode === 'plane') this.rig.setMode('chase', player)
		if (!player.alive) {
			this.queuedShot = false
			this.spectate(player, tanks)
			return
		}
		// While the signal menu is open the mouse moves its pointer: the camera and the gun stay put
		if (menu) this.rig.turn(0, 0, 0, player)
		else this.rig.turn(this.input.mouseDx, this.input.mouseDy, this.input.wheel, player)
		this.cameraModeKeys(player)
		this.drive(player, phase)
		if (!this.freeLook) player.aimTarget.copy(this.rig.aimPoint)
		this.consumables(player)
		this.ammoKeys(player)
		if (phase === 'battle')
			for (const [key, sig] of SIGNAL_KEYS) if (this.input.justPressed(key)) this.onSignal?.(sig)
		if (!menu) this.trigger(player, phase)
		if (this.input.justPressed('KeyV')) this.callPlane(player, phase)
	}

	/**
	 * Q held in battle (alive, in the tank, mouse captured) opens the signal menu; releasing Q sends the option the
	 * pointer is on. Returns true while the menu is open.
	 */
	private signalMenu(player: Tank, phase: Phase): boolean {
		const { input } = this
		const menu = this.hud.radial
		const can = phase === 'battle' && player.alive && input.locked && !this.plane.active
		if (can && input.down(MENU_KEY)) {
			if (!menu.isOpen) menu.open()
			menu.move(input.mouseDx, input.mouseDy)
			return true
		}
		const sig = menu.close()
		if (sig && can) this.onSignal?.(sig)
		return false
	}

	/** Right button held: look around while the gun stays laid where it was. */
	get freeLook(): boolean {
		return this.input.rightDown && this.input.locked
	}

	/** WoT's "aimed" tick: once the reticle has opened up, a soft cue the moment it is fully converged again. */
	private aimCue(player: Tank) {
		if (!player.alive) return
		if (player.bloom > DRIVE.looseBloom * 0.5) this.aimArmed = true
		else if (this.aimArmed && player.bloom <= DRIVE.aimedBloom) {
			this.aimArmed = false
			this.audio.aimed()
		}
	}

	/** WoT's sixth sense: a lamp and a chime the moment the enemy team spots the player. */
	private sixthSense(player: Tank, time: number) {
		const seen = player.alive && Spotting.visibleTo((1 - player.team) as 0 | 1, player, time)
		if (seen && !this.seen) {
			this.audio.spotted()
			this.hud.sixthSense()
		}
		this.seen = seen
	}

	/** V in battle: the plane appears above the tank; the tank stands still until the player comes back. */
	private callPlane(player: Tank, phase: Phase) {
		const { plane, rig, hud } = this
		if (phase !== 'battle') return
		if (plane.cooldown > 0) {
			hud.log(`Самолёт будет готов через ${Math.ceil(plane.cooldown)} с`, COLOR.warn)
			return
		}
		this.queuedShot = false
		plane.launch(player, rig.yaw, player.def.nation)
		rig.setMode('plane', null)
		rig.pitch = 0.15
		hud.log('Самолёт в воздухе: мышь — курс, W / S — газ, ЛКМ или пробел — бомба, V — назад в танк', COLOR.good)
	}

	/** Flying: the mouse sets the course, W / S the throttle, LMB or Space drops a bomb, V returns to the tank. */
	private fly(player: Tank, phase: Phase) {
		const { input, plane, rig } = this
		player.throttle = player.steer = 0
		rig.turn(input.mouseDx, input.mouseDy, input.wheel, null)
		plane.aimYaw = rig.yaw
		plane.aimPitch = -rig.pitch
		plane.throttleAxis = (input.down('KeyW') ? 1 : 0) - (input.down('KeyS') ? 1 : 0)
		if (input.leftClicked || input.justPressed('Space')) {
			if (phase === 'battle' && plane.drop(player, this.shells)) this.audio.click()
			else if (!plane.bombs) this.hud.log('Бомбы кончились — пополняются в полёте', COLOR.warn)
		}
		if (input.justPressed('KeyV')) {
			plane.land()
			rig.setMode(player.alive ? 'chase' : 'spectate', player)
			if (player.alive) rig.yaw = player.yaw
		}
	}

	private globalKeys() {
		const { input, hud } = this
		if (input.justPressed('KeyH')) hud.toggleHelp()
		if (input.justPressed('KeyP')) hud.showFps = !hud.showFps
		if (input.justPressed('KeyM')) hud.announce(this.audio.toggleMute() ? 'Звук выключен' : 'Звук включён')
	}

	private spectate(player: Tank, tanks: Tank[]) {
		const allies = tanks.filter((t) => t.team === player.team && t.alive)
		if (!this.spectating?.alive) this.spectating = allies[0] ?? null
		if (this.input.justPressed('Space') && allies.length) {
			const i = this.spectating ? allies.indexOf(this.spectating) : -1
			this.spectating = allies[(i + 1) % allies.length]
		}
		if (this.rig.mode !== 'spectate') this.rig.setMode('spectate', player)
		this.rig.turn(this.input.mouseDx, this.input.mouseDy, this.input.wheel, null)
	}

	private cameraModeKeys(player: Tank) {
		const { input, rig } = this
		if (!input.justPressed('ShiftLeft') && !input.justPressed('ShiftRight')) return
		if (player.def.gun.howitzer) rig.setMode(rig.mode === 'arty' ? 'chase' : 'arty', player)
		else rig.setMode(rig.mode === 'sniper' ? 'chase' : 'sniper', player)
	}

	private drive(player: Tank, phase: Phase) {
		const axis = (plus: string, minus: string) => (this.input.down(plus) ? 1 : 0) - (this.input.down(minus) ? 1 : 0)
		player.throttle = axis('KeyW', 'KeyS')
		player.steer = axis('KeyA', 'KeyD')
		if (phase === 'countdown') player.throttle = player.steer = 0
	}

	private consumables(player: Tank) {
		const { input, hud } = this
		if (input.justPressed('KeyR')) {
			if (player.useRepairKit()) hud.log('Модули отремонтированы', COLOR.good)
			else if (!player.repairKit) hud.log('Ремкомплект использован', COLOR.warn)
		}
		if (input.justPressed('KeyE')) {
			if (player.crew.treat()) hud.log('Экипаж перевязан', COLOR.good)
			else if (!player.crew.medkit) hud.log('Аптечка использована', COLOR.warn)
		}
		if (input.justPressed('KeyF')) {
			if (player.useExtinguisher()) hud.log('Пожар потушен', COLOR.good)
			else if (!player.extinguisher) hud.log('Огнетушитель использован', COLOR.warn)
		}
	}

	private ammoKeys(player: Tank) {
		for (const id of AMMO_IDS) {
			if (!this.input.justPressed(`Digit${AMMO[id].key}`) || !player.setAmmo(id)) continue
			this.hud.log(`Заряжаем: ${AMMO[id].label}`)
			this.audio.click()
			this.queuedShot = false
		}
	}

	/** LMB fires; a click in the last moments of the reload is kept and fires as soon as the gun is loaded. */
	private trigger(player: Tank, phase: Phase) {
		const loaded = this.loading && player.reload <= 0
		if (phase !== 'battle') this.queuedShot = false
		else if (this.input.leftClicked) {
			if (player.reload > 0 && player.reload <= SHOT_BUFFER) this.queuedShot = true
			else this.fire(player)
		} else if (this.queuedShot && player.reload <= 0) {
			this.queuedShot = false
			this.fire(player)
		}
		if (loaded && player.reload <= 0 && player.def.gun.reload >= RELOAD_CUE_MIN) this.audio.reloaded()
		this.loading = player.reload > 0
	}

	private fire(player: Tank) {
		const was = player.ammo
		const empty = player.ammoCount[was] <= 0
		const shot = player.fire()
		if (shot) this.shells.fire(player, shot)
		else if (empty) {
			const text =
				player.ammoShare <= 0
					? 'Боекомплект израсходован — пополнение на своей базе'
					: `${AMMO[was].label} закончились — заряжаем ${AMMO[player.ammo].label}`
			this.hud.log(text, COLOR.warn)
			this.audio.click()
		} else if (player.reload > 0) this.audio.click()
	}
}
