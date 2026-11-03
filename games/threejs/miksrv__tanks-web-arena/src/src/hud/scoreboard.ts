import { NATION_LABEL } from '../config'
import type { Tank } from '../tank/tank'
import { $, show } from './dom'

const REFRESH = 0.25 // s
const HEADER = ['Команда', 'Танкист', 'Машина', 'Урон', 'По засвету', 'Броня', 'Уничтожил', 'Обнаружил']

function rowHtml(t: Tank, player: Tank): string {
	const cls = `${t === player ? 'me' : ''} ${t.alive ? '' : 'dead'}`
	const cells = [
		`<td class="${t.def.nation}">${NATION_LABEL[t.def.nation]}</td>`,
		`<td>${t.name}${t.alive ? '' : ' †'}</td>`,
		`<td>${t.def.name}</td>`,
		`<td>${Math.round(t.damageDealt)}</td>`,
		`<td>${Math.round(t.stats.assist)}</td>`,
		`<td>${Math.round(t.stats.blocked)}</td>`,
		`<td>${t.kills}</td>`,
		`<td>${t.spots}</td>`,
	]
	return `<tr class="${cls}">${cells.join('')}</tr>`
}

/** The Tab score table: both teams sorted by damage dealt. */
export class Scoreboard {
	private timer = 0

	update(dt: number, visible: boolean, tanks: Tank[], player: Tank) {
		this.timer -= dt
		if (!visible) {
			show($('scores'), false)
			this.timer = 0
			return
		}
		if (this.timer > 0) return
		this.timer = REFRESH
		const el = $('scores')
		show(el, true)
		const rows = [...tanks].sort((a, b) => a.team - b.team || b.damageDealt - a.damageDealt)
		const head = `<tr>${HEADER.map((h) => `<th>${h}</th>`).join('')}</tr>`
		el.innerHTML = `<table>${head}${rows.map((t) => rowHtml(t, player)).join('')}</table>`
	}
}
