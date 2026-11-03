import type { CamMode } from '../camera'
import { AMMO, AMMO_IDS, AMMO_LOAD, CREW_ROLES, ROLE_LABEL } from '../config'
import type { Tank } from '../tank/tank'
import { $, createEl, setClass, setStyle, setText, show } from './dom'

const MODE_LABEL: Record<CamMode, string> = {
	chase: 'аркадный',
	sniper: 'снайперский',
	arty: 'артиллерийский',
	spectate: 'наблюдение',
	plane: 'самолёт',
}
const HIT_FLASH = 0.35 // s
const MS_TO_KMH = 3.6

const hpColor = (frac: number) => (frac > 0.5 ? '#8fd36b' : frac > 0.25 ? '#e0a04a' : '#ff5a5a')
const formatClock = (t: number) => {
	const s = Math.max(0, t)
	return `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`
}

/** The player's vehicle panel (health, modules, consumables, ammo), team pips, the round clock and the hit flash. */
export class StatusPanel {
	private readonly ammoEls: HTMLElement[] = []
	private readonly crewEls = CREW_ROLES.map(
		(r) => $('crew').querySelector<HTMLElement>(`[data-crew="${r}"]`) ?? createEl('span', '', $('crew')),
	)
	private hitFlash = 0
	private lastHits = 0

	constructor() {
		for (const _id of AMMO_IDS) this.ammoEls.push(createEl('span', 'chip', $('ammo')))
	}

	reset() {
		this.lastHits = 0
	}

	update(dt: number, player: Tank, tanks: Tank[], roundLeft: number, mode: CamMode, resupplying: boolean) {
		this.updateVehicle(player, mode)
		this.updateAmmo(player, resupplying)
		this.updateHitFlash(dt, player)
		this.updateTeams(tanks)
		setText($('timer'), formatClock(roundLeft))
	}

	private updateVehicle(player: Tank, mode: CamMode) {
		const d = player.def
		setText($('tankName'), d.name)
		setText($('tankRole'), ROLE_LABEL[d.role])
		setText($('hpText'), `${Math.ceil(player.hp)} / ${d.hp}`)
		setStyle($('hpBar'), 'width', `${(player.hpFrac * 100).toFixed(1)}%`)
		setStyle($('hpBar'), 'background', hpColor(player.hpFrac))
		setClass($('mTrack'), player.tracked > 0 ? 'bad' : '')
		setText($('mTrack'), player.tracked > 0 ? `гусеница ${player.tracked.toFixed(0)}с` : 'гусеница')
		setClass($('mFire'), player.burning > 0 ? 'bad' : '')
		setClass($('mGun'), player.gunDamaged > 0 ? 'bad' : '')
		setClass($('mEngine'), player.engineDamaged > 0 ? 'bad' : '')
		setClass($('mRing'), player.ringDamaged > 0 ? 'bad' : '')
		show($('mRing'), d.shape.turret, 'inline-block')
		setClass($('mRack'), player.rackDamaged > 0 ? 'bad' : '')
		CREW_ROLES.forEach((r, i) => setClass(this.crewEls[i], player.crew.wounded[r] ? 'bad' : ''))
		const seen = player.alive && player.spottedBy[1 - player.team]
		setClass($('mSpot'), seen ? 'bad' : '')
		setStyle($('mSpot'), 'color', seen ? '#ffd166' : '')
		setClass($('cRepair'), player.repairKit ? '' : 'used')
		setClass($('cExt'), player.extinguisher ? '' : 'used')
		setClass($('cMed'), player.crew.medkit ? '' : 'used')
		setText($('speedText'), `${Math.abs(player.speed * MS_TO_KMH).toFixed(0)} км/ч · ${MODE_LABEL[mode]}`)
	}

	/** Shell chips with the rounds left (a type the vehicle does not carry is hidden), and the base top-up line. */
	private updateAmmo(player: Tank, resupplying: boolean) {
		const g = player.def.gun
		this.ammoEls.forEach((el, i) => {
			const id = AMMO_IDS[i]
			const a = AMMO[id]
			const cnt = player.ammoCount[id]
			show(el, player.ammoFull[id] > 0, 'inline-block')
			setText(
				el,
				`${a.key} ${a.label} ×${cnt} · ${Math.round(g.pen * a.penMult)}/${Math.round(g.dmg * a.dmgMult)}`,
			)
			setClass(el, `chip${id === player.ammo ? ' on' : ''}${cnt <= 0 ? ' empty' : ''}`)
		})
		const low = player.alive && player.ammoShare < AMMO_LOAD.lowShare
		const line = $('resupply')
		show(line, resupplying || low)
		setText(
			line,
			resupplying ? 'пополнение: снаряды и расходники' : 'боекомплект на исходе — пополнение на своей базе',
		)
		setClass(line, resupplying ? 'on' : 'low')
	}

	/** Red flash on a hit (fire ticks do not count: `hits` only advances on impacts). */
	private updateHitFlash(dt: number, player: Tank) {
		if (player.hits !== this.lastHits) {
			this.hitFlash = HIT_FLASH
			this.lastHits = player.hits
		}
		this.hitFlash = Math.max(0, this.hitFlash - dt)
		const bg = this.hitFlash > 0 ? `rgba(255,40,20,${(this.hitFlash * 0.5).toFixed(3)})` : 'transparent'
		setStyle($('hit'), 'background', bg)
	}

	/** One pip per tank in each team, dimmed when it is destroyed. */
	private updateTeams(tanks: Tank[]) {
		for (const [id, team] of [
			['teamA', 0],
			['teamB', 1],
		] as const) {
			const el = $(id)
			const members = tanks.filter((t) => t.team === team)
			if (el.childElementCount !== members.length) el.innerHTML = '<div class="pip"></div>'.repeat(members.length)
			members.forEach((t, i) => setClass(el.children[i] as HTMLElement, t.alive ? 'pip' : 'pip dead'))
		}
	}
}
