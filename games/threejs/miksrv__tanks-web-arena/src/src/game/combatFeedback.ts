import * as THREE from 'three'
import { CREW, type CrewRole } from '../config'
import type { CameraRig } from '../camera'
import type { HitResult } from '../combat/armor'
import type { Impact, Shells } from '../combat/shells'
import type { Audio } from '../fx/audio'
import type { Particles } from '../fx/particles'
import type { Hud } from '../hud'
import { Tank, type ShotParams } from '../tank/tank'
import type { BattleReport } from './battleReport'
import { COLOR, hitTakenText, killHtml, playerHitText } from './messages'

export interface FeedbackDeps {
	hud: Hud
	particles: Particles
	audio: Audio
	rig: CameraRig
	shells: Shells
	report: BattleReport
	/** The current round's player tank (it changes every round). */
	player: () => Tank
}

/** "ранен наводчик", "контужен командир". */
function woundedText(r: CrewRole): string {
	return `${r === 'commander' ? 'контужен' : 'ранен'} ${CREW.label[r]}`
}

interface PendingImpact {
	x: number
	y: number
	z: number
	damage: number
}

/**
 * Turns combat events (shots, hits, splash, kills) into particles, sound, camera shake and HUD messages.
 * Every shot (player, bots, salvo rockets) goes through `Shells.onFire`, so the muzzle effects are shared.
 */
export class CombatFeedback {
	// Fall-of-shot feedback for the player's howitzer: the impact is remembered for the frame, and if neither the
	// direct hit nor the splash hurt anyone, a "miss" marker pops up where the shell landed.
	private playerImpact: PendingImpact | null = null
	private pendingDirect = 0

	constructor(private readonly d: FeedbackDeps) {
		d.shells.onFire = (owner, p) => this.onFire(owner, p)
		d.shells.onTankHit = (target, by, hit) => this.onTankHit(target, by, hit)
		d.shells.onImpact = (imp, by) => this.onImpact(imp, by)
		d.shells.onSplashDamage = (target, by, dmg) => this.onSplash(target, by, dmg)
		Tank.onDestroyed = (t, by) => this.onDestroyed(t, by)
	}

	/** Call after the shells have moved: shows "Мимо" for a player howitzer round that hurt nobody. */
	flushMissMarker() {
		const imp = this.playerImpact
		if (!imp) return
		if (imp.damage <= 0) this.d.hud.popup('Мимо', new THREE.Vector3(imp.x, imp.y + 2, imp.z), COLOR.warn)
		this.playerImpact = null
	}

	private onFire(owner: Tank, p: ShotParams) {
		const { particles, audio, rig } = this.d
		const player = this.d.player()
		const at = owner === player ? null : p.origin
		if (owner === player) this.d.report.shot()
		particles.muzzle(p.origin, p.dir, p.rocket ? p.caliber * 0.6 : p.caliber)
		if (p.rocket) audio.rocket(at)
		else audio.shot(p.caliber, at)
		if (owner === player) rig.addShake(p.rocket ? 0.12 : 0.3 + p.caliber / 300)
	}

	private onTankHit(target: Tank, by: Tank, hit: HitResult) {
		const { particles, audio, hud, rig } = this.d
		const player = this.d.player()
		this.d.report.hit(target, by, player, hit)
		particles.armorHit(hit.x, hit.y, hit.z, hit.penetrated, hit.ricochet)
		audio.hit(hit, hit.penetrated, hit.ricochet)
		if (by === player) {
			this.pendingDirect += hit.damage
			const msg = playerHitText(hit)
			hud.log(msg.text, msg.color)
			if (hit.tracked) hud.log('Гусеница сбита', COLOR.damage)
			if (hit.fire) hud.log('Противник горит!', COLOR.fire)
			if (hit.crew) hud.log(`Крит: ${woundedText(hit.crew)}`, COLOR.damage)
			if (hit.ammoRack === 'damaged') hud.log('Крит: боеукладка повреждена', COLOR.damage)
			if (hit.engine) hud.log('Крит: двигатель повреждён', COLOR.damage)
			if (hit.ring) hud.log('Крит: заклинило погон башни', COLOR.damage)
			if (hit.gunHit) hud.log('Крит: орудие повреждено', COLOR.damage)
			if (hit.damage > 0) {
				hud.popup(`−${Math.round(hit.damage)}`, new THREE.Vector3(hit.x, hit.y + 1.5, hit.z), COLOR.damage)
			}
		}
		if (target === player) {
			rig.addShake(0.5)
			const msg = hitTakenText(hit, by)
			hud.log(msg.text, msg.color)
			if (hit.tracked) hud.log('Вам сбили гусеницу — R для ремонта', COLOR.damage)
			if (hit.fire) {
				hud.log('ПОЖАР — F огнетушитель', COLOR.fire)
				audio.alarm()
			}
			if (hit.crew) {
				const text = woundedText(hit.crew)
				hud.log(`${text[0].toUpperCase()}${text.slice(1)} — E аптечка`, COLOR.damage)
			}
			if (hit.ammoRack === 'damaged') hud.log('Боеукладка повреждена: перезарядка дольше', COLOR.damage)
			if (hit.engine) hud.log('Двигатель повреждён: ход вдвое медленнее — R ремкомплект', COLOR.damage)
			if (hit.ring) hud.log('Заклинило погон: башня поворачивается медленно — R ремкомплект', COLOR.damage)
			if (hit.gunHit) hud.log('Орудие повреждено: разброс больше — R ремкомплект', COLOR.damage)
			const a = Math.atan2(by.pos.x - player.pos.x, by.pos.z - player.pos.z)
			hud.hitFrom(-(a - rig.yaw))
		}
	}

	private onImpact(imp: Impact, by: Tank) {
		const { particles, audio } = this.d
		const player = this.d.player()
		const big = imp.he && imp.splash > 3
		particles.impact(imp.x, imp.y, imp.z, imp.he ? Math.min(1.5, imp.splash / 4) : 0.2)
		if (big) particles.marks.splashRing(imp.x, imp.y, imp.z, imp.splash)
		audio.impact(imp, big)
		if (by === player && player.def.gun.howitzer) {
			this.playerImpact = { x: imp.x, y: imp.y, z: imp.z, damage: this.pendingDirect }
			this.pendingDirect = 0
		}
	}

	private onSplash(target: Tank, by: Tank, dmg: number) {
		const { hud, rig } = this.d
		const player = this.d.player()
		this.d.report.splash(target, by, player, dmg)
		if (by === player) {
			hud.log(`Осколки: −${Math.round(dmg)} (${target.def.name})`, COLOR.damage)
			hud.popup(`−${Math.round(dmg)}`, target.pos.clone().add(new THREE.Vector3(0, 3, 0)), COLOR.damage)
			if (this.playerImpact) this.playerImpact.damage += dmg
		}
		if (target === player) {
			hud.log(`Осколки: −${Math.round(dmg)} (${by.def.name})`, COLOR.bad)
			rig.addShake(0.4)
		}
	}

	private onDestroyed(t: Tank, by: Tank | null) {
		const { particles, audio, hud } = this.d
		const player = this.d.player()
		this.d.report.destroyed(t, by, player)
		particles.explosion(t.pos.x, t.pos.y, t.pos.z)
		audio.explosion(t.pos)
		if (t.detonated) {
			// The rack going up: a second, taller blast where the turret was
			particles.explosion(t.pos.x, t.pos.y + 2.5, t.pos.z)
			audio.explosion(t.pos)
		}
		hud.announce(killHtml(t, by))
		if (t === player) {
			hud.log('Ваш танк уничтожен', COLOR.bad)
			hud.center(`Танк уничтожен<br><small>Пробел — следующий союзник · бой продолжается</small>`)
		}
		if (by === player) hud.log(`Уничтожен ${t.def.name}!${t.detonated ? ' Боеукладка!' : ''}`, COLOR.good)
		if (t === player && t.detonated) hud.log('Детонация боеукладки', COLOR.bad)
		t.spottedBy = [true, true]
	}
}
