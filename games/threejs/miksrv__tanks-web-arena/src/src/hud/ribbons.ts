import type { Tank } from '../tank/tank'
import { $, createEl, setText } from './dom'

/** One ribbon: its title and the counter it follows on the player's tank. */
interface RibbonDef {
	label: string
	count: (t: Tank) => number
}

/** WoT-style battle ribbons, in the order they line up. */
const RIBBONS: RibbonDef[] = [
	{ label: 'Уничтожение', count: (t) => t.kills },
	{ label: 'Пробитие', count: (t) => t.stats.pens },
	{ label: 'Крит', count: (t) => t.stats.crits },
	{ label: 'Поджог', count: (t) => t.stats.fires },
	{ label: 'Гусеница', count: (t) => t.stats.tracks },
	{ label: 'Обнаружение', count: (t) => t.spots },
	{ label: 'Урон по засвету', count: (t) => t.stats.assistHits },
	{ label: 'Броня', count: (t) => t.stats.blockedHits },
	{ label: 'Таран', count: (t) => t.stats.rams },
	{ label: 'Захват', count: (t) => (t.stats.capture > 0 ? 1 : 0) },
	{ label: 'Защита базы', count: (t) => (t.stats.defense > 0 ? 1 : 0) },
]
const PULSE = 0.6 // s a ribbon stays highlighted after it counts up

/** Ribbons above the ammo row: each appears with its first event and counts up for the rest of the battle. */
export class Ribbons {
	private readonly els: (HTMLElement | null)[] = RIBBONS.map(() => null)
	private readonly last = RIBBONS.map(() => 0)
	private readonly pulse = RIBBONS.map(() => 0)

	reset() {
		$('ribbons').innerHTML = ''
		this.els.fill(null)
		this.last.fill(0)
		this.pulse.fill(0)
	}

	update(dt: number, player: Tank) {
		RIBBONS.forEach((r, i) => {
			const n = r.count(player)
			if (n !== this.last[i]) {
				this.last[i] = n
				if (n > 0) this.show(i, n)
			}
			if (this.pulse[i] > 0) {
				this.pulse[i] -= dt
				if (this.pulse[i] <= 0) this.els[i]?.classList.remove('new')
			}
		})
	}

	private show(i: number, n: number) {
		let el = this.els[i]
		if (!el) {
			el = createEl('span', 'ribbon', $('ribbons'))
			el.innerHTML = `<b></b>${RIBBONS[i].label}`
			// Keep the fixed order however the ribbons arrive
			const next = this.els.slice(i + 1).find((e) => e)
			if (next) $('ribbons').insertBefore(el, next)
			this.els[i] = el
		}
		setText(el.firstElementChild as HTMLElement, n > 1 ? `×${n}` : '')
		el.classList.remove('new')
		void el.offsetWidth // restart the pulse animation
		el.classList.add('new')
		this.pulse[i] = PULSE
	}
}
