import type { Tank } from '../tank/tank'
import type { Match } from './match'

export interface Medal {
	name: string
	/** What it was for, shown under the name. */
	why: string
}

/** Battle medals for the player, WoT-style, from the battle's stats (scaled to 7 × 7). */
export function awardMedals(player: Tank, tanks: readonly Tank[], match: Match): Medal[] {
	const s = player.stats
	const won = match.winner === player.team
	const top = Math.max(...tanks.map((t) => t.damageDealt))
	const out: Medal[] = []
	const add = (on: boolean, name: string, why: string) => on && out.push({ name, why })
	add(won && match.lastStand >= 3, 'Медаль Колобанова', `победа в одиночку против ${match.lastStand}`)
	add(player.kills >= 3, 'Воин', `уничтожено ${player.kills}`)
	add(player.damageDealt >= 1000 && player.damageDealt >= top, 'Основной калибр', 'больше всех урона в бою')
	add(s.longPens >= 4, 'Снайпер', `${s.longPens} пробитий с 250 м и дальше`)
	add(player.spots >= 4, 'Разведчик', `обнаружено ${player.spots}`)
	add(s.assist >= 800, 'Поддержка', `урон по засвету ${Math.round(s.assist)}`)
	add(s.blocked >= 1200 && s.blockedHits >= 6, 'Стальная стена', `заблокировано ${Math.round(s.blocked)}`)
	add(s.capture >= 50 && won && match.outcome === 'capture', 'Захватчик', 'база взята')
	add(s.defense >= 40, 'Защитник', `сбито очков захвата ${Math.round(s.defense)}`)
	add(s.crits >= 4, 'Мастер критов', `критических попаданий ${s.crits}`)
	return out
}
