import type { BotBrain } from '../ai/bot'
import type { TeamTactics } from '../ai/team'
import type { CameraRig } from '../camera'
import type { Hud } from '../hud'
import type { Tank, WorldRefs } from '../tank/tank'
import type { Capture, CaptureZone } from './capture'
import { COLOR } from './messages'
import type { Signal } from './playerController'

const SIGNAL_COOLDOWN = 2 // s between two team signals
const FOCUS_TIME = 25 // s the team prefers the called-out target
const ORDER_HOLD = 40 // s bots sent by a signal stay where they were sent

/** The player's side: who sends the signal and who answers it. */
export interface Squad {
	player: Tank
	world: WorldRefs
	tactics: TeamTactics
	bots: readonly BotBrain[]
}

/** Team signals from the player to the bots, and the warning when the enemy starts to take a base. */
export class TeamSignals {
	/** Game time before which another signal is ignored. */
	private readyAt = 0
	/** Who was taking each base circle last frame. */
	private capturing: (0 | 1 | null)[] = []

	constructor(
		private readonly hud: Hud,
		private readonly rig: CameraRig,
	) {}

	/** A new battle: the player is told when they knock points off a capture. */
	reset(capture: Capture, player: Tank) {
		this.readyAt = 0
		this.capturing = []
		capture.onReset = (_z, by, pts) => {
			if (by === player) this.hud.log(`Захват сбит: −${Math.round(pts)}`, COLOR.good)
		}
	}

	/**
	 * The player's team signal, as in WoT: a ping on the minimap, a line in the feed, and the nearest bots answer.
	 * Attack: everyone onto the enemy under the reticle, or three bots to the spot it points at. Help: two bots come
	 * to the player. Defend: two bots go back to the base (ours, or the neutral one).
	 */
	send(sig: Signal, squad: Squad, time: number) {
		const { hud, rig } = this
		const { player: p, world, tactics: tac } = squad
		if (!p.alive || time < this.readyAt) return
		this.readyAt = time + SIGNAL_COOLDOWN
		const near = (x: number, z: number, n: number) =>
			squad.bots
				.filter((b) => b.tank.alive && b.tank.def.role !== 'spg')
				.sort((a, b) => a.dist({ x, z }) - b.dist({ x, z }))
				.slice(0, n)
		const reply = (bots: BotBrain[], text: string) => {
			if (bots.length) hud.announce(`<b>${bots[0].tank.name}</b>: ${text}`)
		}
		const t = rig.aimedTank
		if (sig === 'attack' && t && t.team !== p.team && t.alive) {
			tac.focusOn(t, time + FOCUS_TIME)
			hud.announce(`<b>Вы</b>: Атакую ${t.def.name}!`)
			hud.ping(t.pos.x, t.pos.z, COLOR.bad)
			reply(near(t.pos.x, t.pos.z, 1), 'Понял, огонь по цели!')
		} else if (sig === 'attack') {
			const at = rig.aimPoint
			hud.announce('<b>Вы</b>: Атакую сюда!')
			hud.ping(at.x, at.z, COLOR.warn)
			const bots = near(at.x, at.z, 3)
			for (const b of bots) b.order(world, { x: at.x, z: at.z }, time, ORDER_HOLD)
			reply(bots, 'Понял, выдвигаюсь!')
		} else if (sig === 'help') {
			hud.announce('<b>Вы</b>: Нужна помощь!')
			hud.ping(p.pos.x, p.pos.z, COLOR.info)
			const bots = near(p.pos.x, p.pos.z, 2)
			for (const b of bots) b.order(world, { x: p.pos.x, z: p.pos.z }, time, ORDER_HOLD)
			reply(bots, 'Иду на помощь!')
		} else {
			const zone = world.zones.find((z) => z.owner === p.team) ?? world.zones.find((z) => z.owner === -1)
			if (!zone) {
				hud.log('Нашей базы на этой карте нет', COLOR.warn)
				return
			}
			hud.announce('<b>Вы</b>: Защищайте базу!')
			hud.ping(zone.x, zone.z, COLOR.good)
			const bots = near(zone.x, zone.z, 2)
			for (const b of bots) {
				tac.defenders.add(b.tank)
				b.defend(world, zone)
				b.holdOrder(time, ORDER_HOLD)
			}
			reply(bots, 'Возвращаюсь на базу!')
		}
	}

	/** The enemy has started to take our base (or the neutral one): a warning in the log. */
	watchCapture(player: Tank, zones: readonly CaptureZone[]) {
		const team = player.team
		zones.forEach((z, i) => {
			const was = this.capturing[i] ?? null
			this.capturing[i] = z.capturing
			if (z.capturing === null || z.capturing === was || z.capturing === team || z.owner === 1 - team) return
			this.hud.log(z.owner === -1 ? 'Противник захватывает базу!' : 'Нашу базу захватывают!', COLOR.bad)
		})
	}
}
