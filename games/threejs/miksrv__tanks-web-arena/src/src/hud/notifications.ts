import * as THREE from 'three'
import { $, createEl, ndcToScreen, setStyle } from './dom'

interface Timed {
	el: HTMLDivElement
	life: number
}
interface Popup extends Timed {
	pos: THREE.Vector3
}

const FEED_LIFE = 8
const FEED_MAX = 6
const LOG_LIFE = 2.6
const LOG_MAX = 4
const ARROW_LIFE = 2
const ARROW_FADE = 0.8
const POPUP_LIFE = 1.6
const POPUP_RISE = 2.5 // m/s

/** A list of DOM lines that fade out over their last second and drop off the top when there are too many. */
class FadingList {
	private items: Timed[] = []

	constructor(
		private readonly containerId: string,
		private readonly className: string,
		private readonly life: number,
		private readonly max: number,
	) {}

	push(fill: (el: HTMLDivElement) => void) {
		const el = createEl('div', this.className, $(this.containerId))
		fill(el)
		this.items.push({ el, life: this.life })
		while (this.items.length > this.max) this.items.shift()?.el.remove()
	}

	update(dt: number, fadeTime = 1) {
		for (let i = this.items.length - 1; i >= 0; i--) {
			const f = this.items[i]
			f.life -= dt
			if (f.life <= 0) {
				f.el.remove()
				this.items.splice(i, 1)
			} else if (f.life < fadeTime) setStyle(f.el, 'opacity', (f.life / fadeTime).toFixed(2))
		}
	}
}

/** Kill feed, battle log, floating damage numbers and hit-direction arrows. */
export class Notifications {
	private readonly feed = new FadingList('feed', 'feed', FEED_LIFE, FEED_MAX)
	private readonly logs = new FadingList('log', 'log', LOG_LIFE, LOG_MAX)
	private readonly arrows = new FadingList('hitdir', 'arrow', ARROW_LIFE, Infinity)
	private popups: Popup[] = []
	private readonly tmp = new THREE.Vector3()

	announce(html: string) {
		this.feed.push((el) => (el.innerHTML = html))
	}

	log(text: string, color = '#e8e4d8') {
		this.logs.push((el) => {
			el.textContent = text
			el.style.color = color
		})
	}

	/** Red arrow at the screen edge pointing toward where the hit came from. */
	hitFrom(angleFromCamera: number) {
		this.arrows.push((el) => {
			el.style.transform = `rotate(${angleFromCamera}rad)`
			el.style.opacity = '1'
		})
	}

	/** Floating text at a world point (damage numbers, "miss"). */
	popup(text: string, pos: THREE.Vector3, color: string) {
		const el = createEl('div', 'popup', $('labels'))
		el.textContent = text
		el.style.color = color
		this.popups.push({ el, pos: pos.clone(), life: POPUP_LIFE })
	}

	update(dt: number, camera: THREE.Camera) {
		this.updatePopups(dt, camera)
		this.feed.update(dt)
		this.logs.update(dt)
		this.arrows.update(dt, ARROW_FADE)
	}

	private updatePopups(dt: number, camera: THREE.Camera) {
		for (let i = this.popups.length - 1; i >= 0; i--) {
			const pp = this.popups[i]
			pp.life -= dt
			if (pp.life <= 0) {
				pp.el.remove()
				this.popups.splice(i, 1)
				continue
			}
			pp.pos.y += dt * POPUP_RISE
			const p = this.tmp.copy(pp.pos).project(camera)
			if (p.z > 1) {
				pp.el.style.display = 'none'
				continue
			}
			const s = ndcToScreen(p.x, p.y)
			pp.el.style.display = 'block'
			pp.el.style.transform = `translate(${s.x}px, ${s.y}px) translate(-50%, -50%)`
			pp.el.style.opacity = String(Math.min(1, pp.life))
		}
	}
}
