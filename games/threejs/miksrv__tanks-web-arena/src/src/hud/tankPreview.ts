import * as THREE from 'three'
import type { TankDef } from '../config'
import { TankView } from '../tank/tankView'

const FOV = 30 // deg
/** Three-quarter view from the front left, a little from above. */
const VIEW_YAW = 0.75 // rad
const VIEW_PITCH = 0.3 // rad
const SPIN_SPEED = 0.5 // rad/s, the selected vehicle's turntable
const MARGIN = 1.08 // framing slack around the silhouette

/** What the camera frames: the turntable's centre height, its radius about the y axis and its half height. */
interface Frame {
	cy: number
	reach: number
	halfH: number
}

/**
 * Vehicle portraits for the garage cards: one small offscreen renderer of its own (the battle renderer keeps its
 * size, scene and state), copied into each card's 2D canvas. Models are built on demand and kept for the session.
 */
export class TankPreview {
	private readonly renderer: THREE.WebGLRenderer
	private readonly scene = new THREE.Scene()
	private readonly camera = new THREE.PerspectiveCamera(FOV, 1, 0.1, 200)
	private readonly views = new Map<string, { view: TankView; frame: Frame }>()
	private readonly tmpBox = new THREE.Box3()
	private readonly tmpV = new THREE.Vector3()
	private current: TankView | null = null

	constructor() {
		this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
		this.renderer.setPixelRatio(1) // canvases are sized in device pixels by the caller
		this.renderer.toneMapping = THREE.ACESFilmicToneMapping
		this.scene.add(new THREE.HemisphereLight('#dfe6ee', '#4a4636', 1.6))
		const sun = new THREE.DirectionalLight('#fff1dc', 2.2)
		sun.position.set(6, 10, 8)
		this.scene.add(sun)
	}

	/** Draw `def` turned by `yaw` into a 2D canvas (its width and height are taken as device pixels). */
	draw(def: TankDef, target: HTMLCanvasElement, yaw = 0) {
		const { width: w, height: h } = target
		if (w === 0 || h === 0) return
		const { view, frame } = this.model(def)
		if (this.current !== view) {
			if (this.current) this.scene.remove(this.current.group)
			this.scene.add(view.group)
			this.current = view
		}
		view.group.rotation.y = yaw

		const size = this.renderer.getSize(new THREE.Vector2())
		if (size.x !== w || size.y !== h) this.renderer.setSize(w, h, false)
		const cam = this.camera
		cam.aspect = w / h
		// Fit the turntable's silhouette (any heading) into both fields of view; the near side is `reach` closer
		const tan = Math.tan(THREE.MathUtils.degToRad(FOV / 2))
		const halfV = frame.halfH * Math.cos(VIEW_PITCH) + frame.reach * Math.sin(VIEW_PITCH)
		const dist = Math.max(halfV / tan, frame.reach / (tan * cam.aspect)) * MARGIN + frame.reach * 0.5
		const center = this.tmpV.set(0, frame.cy, 0)
		cam.position.set(
			Math.sin(VIEW_YAW) * Math.cos(VIEW_PITCH) * dist,
			frame.cy + Math.sin(VIEW_PITCH) * dist,
			Math.cos(VIEW_YAW) * Math.cos(VIEW_PITCH) * dist,
		)
		cam.lookAt(center)
		cam.updateProjectionMatrix()
		this.renderer.render(this.scene, cam)

		// The drawing buffer is still intact within the task that rendered it
		const ctx = target.getContext('2d')
		if (!ctx) return
		ctx.clearRect(0, 0, w, h)
		ctx.drawImage(this.renderer.domElement, 0, 0)
	}

	/** Radians the selected vehicle turns in `dt` seconds. */
	static spin(dt: number) {
		return dt * SPIN_SPEED
	}

	private model(def: TankDef) {
		let m = this.views.get(def.id)
		if (!m) {
			const view = new TankView(def, def.nation, 7)
			view.setTurret(0, 0.05)
			view.group.updateMatrixWorld(true)
			// Turned about the hull centre (the y axis), so the frame must hold every heading
			const { min, max } = this.tmpBox.setFromObject(view.group)
			const reach = Math.hypot(Math.max(-min.x, max.x), Math.max(-min.z, max.z))
			const frame = { cy: (min.y + max.y) / 2, reach, halfH: (max.y - min.y) / 2 }
			m = { view, frame }
			this.views.set(def.id, m)
		}
		return m
	}
}
