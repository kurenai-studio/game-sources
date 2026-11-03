import * as THREE from 'three'
import { Spotting } from '../game/spotting'
import type { Tank } from '../tank/tank'
import { $, createEl, ndcToScreen, setStyle, show } from './dom'

interface LabelEl {
	root: HTMLDivElement
	name: HTMLSpanElement
	bar: HTMLDivElement
	last: string
}

const ABOVE_TURRET = 1.2 // m above the turret roof
const COLORS = { allyName: '#8fd36b', enemyName: '#ff8a80', allyBar: '#8fd36b', enemyBar: '#ff5a5a' }

/** Name and health bar floating over every visible tank except the player's own. */
export class TankLabels {
	private readonly labels = new Map<Tank, LabelEl>()
	private readonly tmp = new THREE.Vector3()

	reset() {
		for (const l of this.labels.values()) l.root.remove()
		this.labels.clear()
	}

	update(player: Tank, tanks: Tank[], camera: THREE.Camera, time: number) {
		for (const t of tanks) {
			const el = this.labelOf(t)
			const visible = t !== player && t.alive && Spotting.visibleTo(player.team, t, time)
			const p = visible ? this.project(t, camera) : null
			show(el.root, !!p)
			if (p) this.fill(el, t, p, t.team === player.team)
		}
	}

	private labelOf(t: Tank): LabelEl {
		let el = this.labels.get(t)
		if (el) return el
		const root = createEl('div', 'label', $('labels'))
		const name = createEl('span', '', root)
		const bar = createEl('div', '', createEl('div', 'lbar', root))
		el = { root, name, bar, last: '' }
		this.labels.set(t, el)
		return el
	}

	/** Screen point over the turret, or null when it is behind the camera or off screen. */
	private project(t: Tank, camera: THREE.Camera): { x: number; y: number } | null {
		const p = this.tmp
			.set(t.pos.x, t.pos.y + t.view.hullTop + t.def.shape.tH + ABOVE_TURRET, t.pos.z)
			.project(camera)
		if (p.z > 1 || Math.abs(p.x) > 1.05 || Math.abs(p.y) > 1.05) return null
		return ndcToScreen(p.x, p.y)
	}

	private fill(el: LabelEl, t: Tank, s: { x: number; y: number }, ally: boolean) {
		setStyle(el.root, 'transform', `translate(${Math.round(s.x)}px, ${Math.round(s.y)}px) translate(-50%, -100%)`)
		const txt = `${t.name} · ${t.def.name}`
		if (el.last !== txt) {
			el.name.textContent = txt
			el.last = txt
			el.name.style.color = ally ? COLORS.allyName : COLORS.enemyName
		}
		setStyle(el.bar, 'width', `${(t.hpFrac * 100).toFixed(0)}%`)
		setStyle(el.bar, 'background', ally ? COLORS.allyBar : COLORS.enemyBar)
	}
}
