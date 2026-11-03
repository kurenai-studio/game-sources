import { CAPTURE } from '../config'
import type { CaptureZone } from '../game/capture'
import type { Tank } from '../tank/tank'
import { $, createEl, setClass, setHtml, setStyle } from './dom'

/** One bar per base being taken: green while our side captures, red while the enemy does. */
export class CaptureBar {
	private readonly bars: { el: HTMLElement; label: HTMLElement; fill: HTMLElement }[] = []

	update(zones: readonly CaptureZone[], player: Tank) {
		const root = $('capture')
		while (this.bars.length < zones.length) {
			const el = createEl('div', 'cap-bar', root)
			const label = createEl('span', '', el)
			const fill = createEl('div', 'fill', createEl('div', 'track', el))
			this.bars.push({ el, label, fill })
		}
		this.bars.forEach(({ el, label, fill }, i) => {
			const z = zones[i]
			const on = !!z && z.points > 0 && z.capturing !== null
			setStyle(el, 'display', on ? '' : 'none')
			if (!on) return
			const ours = z.capturing === player.team
			const whose =
				z.owner === -1 ? 'нейтральной базы' : z.owner === player.team ? 'нашей базы' : 'базы противника'
			const pct = Math.floor((z.points / CAPTURE.points) * 100)
			setClass(el, `cap-bar ${ours ? 'ours' : 'theirs'}${z.contested ? ' frozen' : ''}`)
			setHtml(label, `Захват ${whose} · ${pct}%${z.contested ? ' · заморожен' : ''}`)
			setStyle(fill, 'width', `${pct}%`)
		})
	}

	reset() {
		for (const b of this.bars) b.el.remove()
		this.bars.length = 0
	}
}
