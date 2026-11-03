import type { HitResult } from '../combat/armor'
import type { Tank } from '../tank/tank'
import { hitPlace } from './messages'

/** The player's exchange with one enemy vehicle, one way. */
interface Row {
	tank: Tank
	hits: number
	pens: number
	ricochets: number
	/** Hits the armour stopped (no penetration, no ricochet). */
	blocked: number
	damage: number
	/** Module and crew criticals. */
	crits: number
	killed: boolean
	/** Where the shells landed: "башня", "нижний лист", … with a count. */
	places: Map<string, number>
}

const r = Math.round
const pct = (a: number, b: number) => (b ? `${r((a / b) * 100)} %` : '—')

/** After-battle breakdown: every hit the player made and took, per enemy vehicle, and the shot totals. */
export class BattleReport {
	private shots = 0
	private readonly dealt = new Map<Tank, Row>()
	private readonly taken = new Map<Tank, Row>()

	reset() {
		this.shots = 0
		this.dealt.clear()
		this.taken.clear()
	}

	shot() {
		this.shots++
	}

	/** A direct hit by or on the player (friendly fire is left out). */
	hit(target: Tank, by: Tank, player: Tank, hit: HitResult) {
		if (target.team === by.team) return
		const row = by === player ? this.row(this.dealt, target) : target === player ? this.row(this.taken, by) : null
		if (!row) return
		row.hits++
		if (hit.penetrated) row.pens++
		else if (hit.ricochet) row.ricochets++
		else if (hit.damage <= 0) row.blocked++
		row.damage += hit.damage
		if (hit.crew || hit.ammoRack || hit.gunHit || hit.engine || hit.ring || hit.fire || hit.tracked) row.crits++
		const place = hitPlace(hit)
		row.places.set(place, (row.places.get(place) ?? 0) + 1)
	}

	/** HE splash by or on the player. */
	splash(target: Tank, by: Tank, player: Tank, dmg: number) {
		if (target.team === by.team) return
		if (by === player) this.row(this.dealt, target).damage += dmg
		else if (target === player) this.row(this.taken, by).damage += dmg
	}

	destroyed(t: Tank, by: Tank | null, player: Tank) {
		if (!by || by.team === t.team) return
		if (by === player) this.row(this.dealt, t).killed = true
		else if (t === player) this.row(this.taken, by).killed = true
	}

	/** The breakdown for the garage, or '' when the player neither fired nor was hit. */
	html(): string {
		if (!this.shots && !this.taken.size) return ''
		const dealt = [...this.dealt.values()]
		const hits = dealt.reduce((s, x) => s + x.hits, 0)
		const pens = dealt.reduce((s, x) => s + x.pens, 0)
		const totals = [
			`выстрелов ${this.shots}`,
			`попаданий ${hits} (${pct(hits, this.shots)})`,
			`пробитий ${pens} (${pct(pens, hits)})`,
			`урон ${r(dealt.reduce((s, x) => s + x.damage, 0))}`,
			`получено ${r([...this.taken.values()].reduce((s, x) => s + x.damage, 0))}`,
		].join(' · ')
		return (
			`<div class="totals">${totals}</div>` +
			table('Нанесено', 'Цель', dealt, 'kill') +
			table('Получено', 'Стрелял', [...this.taken.values()], 'killer')
		)
	}

	private row(map: Map<Tank, Row>, tank: Tank): Row {
		let row = map.get(tank)
		if (!row) {
			row = {
				tank,
				hits: 0,
				pens: 0,
				ricochets: 0,
				blocked: 0,
				damage: 0,
				crits: 0,
				killed: false,
				places: new Map(),
			}
			map.set(tank, row)
		}
		return row
	}
}

/** One side of the exchange; the row of a kill gets `killClass` (our kill, or the one who killed us). */
function table(title: string, who: string, rows: Row[], killClass: string): string {
	if (!rows.length) return `<h3>${title}</h3><div class="none">ничего</div>`
	rows.sort((a, b) => b.damage - a.damage)
	const body = rows
		.map((x) => {
			const places = [...x.places].map(([p, n]) => (n > 1 ? `${p} ×${n}` : p)).join(', ')
			return (
				`<tr${x.killed ? ` class="${killClass}"` : ''}><td>${x.tank.name} <small>${x.tank.def.name}</small></td>` +
				`<td>${x.hits}</td><td>${x.pens}</td><td>${x.ricochets}</td><td>${x.blocked}</td><td>${x.crits}</td>` +
				`<td>${r(x.damage)}</td><td>${places || '—'}</td><td>${x.killed ? '✕' : ''}</td></tr>`
			)
		})
		.join('')
	return (
		`<h3>${title}</h3><table><tr><th>${who}</th><th>попад.</th><th>пробит.</th><th>рикош.</th>` +
		`<th>не пробил</th><th>криты</th><th>урон</th><th>куда</th><th></th></tr>${body}</table>`
	)
}
