import * as THREE from 'three'
import type { CameraRig, CamMode } from '../camera'
import { aimedArmor, estimateArmor, plateClass, reticleClass } from '../combat/armor'
import { HOWITZER, howitzerSolve } from '../combat/ballistics'
import { traceShot } from '../combat/trace'
import { GRAVITY } from '../config'
import type { Tank, WorldRefs } from '../tank/tank'
import { $, ndcToScreen, setAttr, setClass, setStyle, setText, show } from './dom'

const MIN_RETICLE_PX = 14
const MAX_RETICLE_SHARE = 0.6 // of the window height
const ARTY_RING_PX = 30
const RING_GAP_PX = 9
const READY_FLASH = 0.45 // s of the green "loaded" flash
const TRACE_TIME = { direct: 4, howitzer: 12 } // s of flight the gun marker follows
const ZONE_LABEL = { lower: 'нижний лист', mantlet: 'маска', cupola: 'башенка', screen: 'экран' } as const

/** Aiming aids: the dispersion circle, reload ring, aim readout and the gun marker. */
export class Reticle {
	private ringReady = 0 // s left of the green "loaded" flash on the reload ring
	private readonly gunO = new THREE.Vector3()
	private readonly gunD = new THREE.Vector3()
	private readonly gunP = new THREE.Vector3()
	private readonly tmp = new THREE.Vector3()

	update(
		dt: number,
		player: Tank,
		rig: CameraRig,
		world: WorldRefs,
		locked: boolean,
		mode: CamMode,
		artyBlocked: boolean,
	) {
		const sizePx = this.updateCircle(player, rig)
		this.updateReloadRing(player, mode === 'arty' ? ARTY_RING_PX : sizePx, dt, player.alive && locked)
		this.updateInfo(player, rig, artyBlocked)
		// In the artillery view the reticle is the dispersion circle drawn on the ground (ArtyView), not this one
		const aiming = player.alive && locked
		const onScreen = aiming && mode !== 'arty'
		show($('cross'), onScreen)
		show($('dot'), onScreen)
		show($('aimInfo'), aiming)
		this.updateGunMarker(player, rig, world, onScreen)
		show($('vignette'), mode === 'sniper')
	}

	/** Circle radius from the dispersion (m at 100 m) projected through the camera; returns its size in px. */
	private updateCircle(player: Tank, rig: CameraRig): number {
		const cross = $('cross')
		const ang = player.reticle / 100
		const px = (Math.tan(ang) / Math.tan((rig.camera.fov * Math.PI) / 360)) * (window.innerHeight / 2)
		const sizePx = Math.max(MIN_RETICLE_PX, Math.min(window.innerHeight * MAX_RETICLE_SHARE, px * 2))
		const size = `${sizePx.toFixed(0)}px`
		setStyle(cross, 'width', size)
		setStyle(cross, 'height', size)
		setClass(cross, player.aimClass)
		return sizePx
	}

	/**
	 * Distance, the target and its armour (colouring the centre dot and the readout; the circle shows convergence),
	 * and for artillery the shell's flight time (or what stops it) and the convergence.
	 */
	private updateInfo(player: Tank, rig: CameraRig, blocked: boolean) {
		const dist = Math.hypot(rig.aimPoint.x - player.pos.x, rig.aimPoint.z - player.pos.z)
		let cls = ''
		let info = `${Math.round(dist)} м`
		const at = rig.aimedTank
		if (at?.alive && at.team !== player.team) {
			// The plate right under the reticle (lower plate, mantlet, cupola…), seen from the muzzle
			player.view.muzzle(this.tmp)
			const plate = player.def.gun.howitzer ? null : aimedArmor(player, at, this.tmp, rig.aimPoint)
			cls = plate ? plateClass(player, plate) : reticleClass(player, at)
			const mm = plate ? (plate.ricochet ? 'рикошет' : `${Math.round(plate.effective)} мм`) : null
			const spot = plate?.zone ? ` (${ZONE_LABEL[plate.zone]})` : ''
			info += ` · ${at.def.name} · броня ${mm ?? `≈${Math.round(estimateArmor(player, at))} мм`}${spot}`
		}
		if (player.def.gun.howitzer) {
			// Time of flight on the high arc, or a warning when the point is beyond the gun's reach
			const muzzleY = player.pos.y + player.view.hullTop + player.view.gun.position.y
			const sol = howitzerSolve(dist, rig.aimPoint.y - muzzleY)
			info += !sol ? ' · ВНЕ ДОСЯГАЕМОСТИ' : blocked ? ' · ПРЕПЯТСТВИЕ' : ` · полёт ${sol.time.toFixed(1)} с`
			info += ` · сведение ${Math.round(100 / (1 + player.bloom))}%`
		}
		setClass($('dot'), cls)
		setClass($('aimInfo'), cls)
		setText($('aimInfo'), info)
	}

	/**
	 * Gun marker: where a shell fired this instant would actually go, traced along the real barrel (the turret and
	 * the gun lag behind the reticle). It converges on the reticle once the turret has caught up.
	 */
	private updateGunMarker(player: Tank, rig: CameraRig, w: WorldRefs, on: boolean) {
		const el = $('gunDot')
		if (!on) {
			show(el, false)
			return
		}
		player.view.muzzle(this.gunO, this.gunD)
		const g = player.def.gun
		const speed = g.howitzer
			? (howitzerSolve(player.aimDist, player.aimTarget.y - this.gunO.y)?.speed ?? 100)
			: g.shellSpeed * player.ammoDef.speedMult
		const gravity = g.howitzer ? HOWITZER.gravity : GRAVITY
		const maxTime = g.howitzer ? TRACE_TIME.howitzer : TRACE_TIME.direct
		traceShot(w, this.gunO, this.gunD, speed, gravity, maxTime, player, this.gunP)
		const p = this.tmp.copy(this.gunP).project(rig.camera)
		if (p.z > 1) {
			show(el, false)
			return
		}
		const s = ndcToScreen(THREE.MathUtils.clamp(p.x, -0.97, 0.97), THREE.MathUtils.clamp(p.y, -0.95, 0.95))
		show(el, true)
		setStyle(el, 'transform', `translate(${Math.round(s.x)}px, ${Math.round(s.y)}px)`)
	}

	/**
	 * Reload ring just outside the reticle (both camera modes share the reticle): fills clockwise from the top while
	 * loading, flashes green for a moment when the gun is ready, then disappears so the sight stays clean.
	 */
	private updateReloadRing(player: Tank, reticlePx: number, dt: number, aiming: boolean) {
		const ring = $('ring')
		const [track, arc] = Array.from(ring.children)
		const loading = player.reload > 0
		this.ringReady = loading ? READY_FLASH : Math.max(0, this.ringReady - dt)
		const visible = aiming && (loading || this.ringReady > 0)
		show(ring, visible)
		if (!visible) return
		const r = reticlePx / 2 + RING_GAP_PX
		const circ = 2 * Math.PI * r
		const progress = loading ? 1 - player.reload / player.reloadFull : 1
		setAttr(track, 'r', r.toFixed(1))
		setAttr(arc, 'r', r.toFixed(1))
		setAttr(arc, 'stroke-dasharray', circ.toFixed(1))
		setAttr(arc, 'stroke-dashoffset', (circ * (1 - progress)).toFixed(1))
		setAttr(ring, 'class', loading ? '' : 'ready') // SVG: className is read-only, so the attribute is set directly
		setStyle(ring, 'opacity', loading ? '1' : (this.ringReady / READY_FLASH).toFixed(2))
	}
}
