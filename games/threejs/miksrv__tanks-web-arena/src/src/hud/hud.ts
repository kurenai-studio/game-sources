import type * as THREE from 'three'
import type { CameraRig, CamMode } from '../camera'
import { PLANE } from '../config'
import type { Plane } from '../plane/plane'
import type { Tank, WorldRefs } from '../tank/tank'
import type { Terrain } from '../world/terrain'
import { CaptureBar } from './captureBar'
import { $, setHtml, setText, show } from './dom'
import { Garage } from './garage'
import { Minimap, bakeMinimap } from './minimap'
import { Notifications } from './notifications'
import { Reticle } from './reticle'
import { Ribbons } from './ribbons'
import { Scoreboard } from './scoreboard'
import { RadialMenu } from './radialMenu'
import { StatusPanel } from './statusPanel'
import { TankLabels } from './tankLabels'

const SIXTH_SENSE_TIME = 4 // s the lamp stays lit

export interface HudStats {
	fps: number
	calls: number
	shells: number
	particles: number
	scale: number
}

/** Everything the HUD reads in one frame. */
export interface HudFrame {
	dt: number
	time: number
	player: Tank
	tanks: Tank[]
	rig: CameraRig
	world: WorldRefs
	roundLeft: number
	showScores: boolean
	locked: boolean
	mode: CamMode
	/** The gun is held while the player looks around. */
	freeLook: boolean
	/** The battle is paused (the mouse was released). */
	paused: boolean
	/** The player's tank is taking on shells at its base. */
	resupplying: boolean
	/** The player's plane while it flies. */
	plane: Plane | null
	/** Artillery view: the planned arc is blocked short of the aim point. */
	artyBlocked: boolean
	stats: HudStats
}

/** The DOM overlay: garage, panels, reticle, minimap, labels and messages. */
export class Hud {
	readonly garage = new Garage()
	/** Team signals on a hold-to-open wheel (Q). */
	readonly radial = new RadialMenu()
	private readonly status = new StatusPanel()
	private readonly reticle = new Reticle()
	private readonly minimap = new Minimap($('minimap') as HTMLCanvasElement)
	private readonly notifications = new Notifications()
	private readonly labels = new TankLabels()
	private readonly scoreboard = new Scoreboard()
	private readonly ribbons = new Ribbons()
	private readonly captureBar = new CaptureBar()
	showFps = false
	private sixthTimer = 0

	// ---------------------------------------------------------------- overlays
	showGarage(on: boolean) {
		this.garage.show(on)
	}
	showResult(html: string) {
		this.overlay('result', html)
	}
	/** The last battle's breakdown in the garage (hidden when empty). */
	setReport(html: string) {
		const el = $('reportBody')
		el.innerHTML = html
		show($('report'), html !== '')
	}
	center(html: string) {
		this.overlay('center', html)
	}
	hint(html: string) {
		this.overlay('hint', html)
	}
	toggleHelp() {
		const h = $('help')
		show(h, h.style.display !== 'block')
	}
	private overlay(id: string, html: string) {
		const el = $(id)
		show(el, !!html)
		setHtml(el, html)
	}

	// ---------------------------------------------------------------- minimap
	/** Paint the minimap backdrop for a terrain; install it with `setMap`. */
	bakeMap(terrain: Terrain): HTMLCanvasElement {
		return bakeMinimap(terrain)
	}
	setMap(c: HTMLCanvasElement) {
		this.minimap.setBackdrop(c)
	}

	// ---------------------------------------------------------------- messages
	popup(text: string, pos: THREE.Vector3, color: string) {
		this.notifications.popup(text, pos, color)
	}
	announce(html: string) {
		this.notifications.announce(html)
	}
	log(text: string, color?: string) {
		this.notifications.log(text, color)
	}
	hitFrom(angleFromCamera: number) {
		this.notifications.hitFrom(angleFromCamera)
	}
	/** A team signal's ping on the minimap. */
	ping(x: number, z: number, color: string) {
		this.minimap.ping(x, z, color)
	}
	/** Light the "you are spotted" lamp. */
	sixthSense() {
		this.sixthTimer = SIXTH_SENSE_TIME
	}

	// ---------------------------------------------------------------- per frame
	update(f: HudFrame) {
		this.status.update(f.dt, f.player, f.tanks, f.roundLeft, f.mode, f.resupplying)
		this.ribbons.update(f.dt, f.player)
		this.captureBar.update(f.world.zones, f.player)
		this.reticle.update(f.dt, f.player, f.rig, f.world, f.locked && !f.plane, f.mode, f.artyBlocked)
		this.updatePlane(f.plane, f.locked)
		show($('freeLook'), f.freeLook)
		this.sixthTimer = f.player.alive ? Math.max(0, this.sixthTimer - f.dt) : 0
		show($('sixth'), this.sixthTimer > 0)
		const askForLock = !f.locked && !this.garage.isOpen
		show($('hint'), askForLock)
		if (askForLock)
			setHtml(
				$('hint'),
				f.paused ? 'Пауза · кликните по экрану, чтобы продолжить' : 'Кликните по экрану, чтобы захватить мышь',
			)
		this.labels.update(f.player, f.tanks, f.rig.camera, f.time)
		this.notifications.update(f.dt, f.rig.camera)
		this.minimap.update(f.dt, f.player, f.tanks, f.world.zones, f.rig.yaw, f.time)
		this.scoreboard.update(f.dt, f.showScores, f.tanks, f.player)
		this.updateFps(f.stats)
	}

	/** Flight readout and the course cross while the plane flies. */
	private updatePlane(plane: Plane | null, locked: boolean) {
		show($('planeHud'), !!plane)
		show($('planeCross'), !!plane && locked)
		if (!plane) return
		const bombs = '●'.repeat(plane.bombs) + '○'.repeat(PLANE.bomb.max - plane.bombs)
		setHtml(
			$('planeHud'),
			`<b>Самолёт</b> высота ${Math.round(plane.altitude)} м · ${Math.round(plane.speed * 3.6)} км/ч · газ ${Math.round(plane.throttle * 100)} %` +
				`<br>бомбы <span class="bombs">${bombs}</span>`,
		)
	}

	private updateFps(s: HudStats) {
		const el = $('fps')
		show(el, this.showFps)
		if (!this.showFps) return
		const parts = [`${s.fps} fps`, `${s.calls} draw`, `масштаб ${s.scale.toFixed(3)}`]
		setText(el, [...parts, `снарядов ${s.shells}`, `частиц ${s.particles}`].join(' · '))
	}

	reset() {
		this.sixthTimer = 0
		this.labels.reset()
		this.status.reset()
		this.ribbons.reset()
		this.captureBar.reset()
	}
}
