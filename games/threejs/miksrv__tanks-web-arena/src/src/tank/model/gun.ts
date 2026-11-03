import * as THREE from 'three'
import type { GunLook, TankDef } from '../../config'
import { C, type TankBuilder } from './builder'

const DEFAULT_GUN: GunLook = { mantlet: 'box', brake: 'none' }

/** Katyusha: eight I-beam rails with a rocket on each over a frame, pivoting at their rear end. */
function rails(gb: TankBuilder, def: TankDef) {
	const s = def.shape
	const n = 8
	const pitch = (s.tW * 0.9) / (n - 1)
	gb.box(s.tW * 0.95, 0.1, s.gunLen * 0.55, C.steel, 0, -0.12, s.gunLen * 0.3, true)
	for (let i = 0; i < n; i++) {
		const x = (i - (n - 1) / 2) * pitch
		gb.box(0.06, 0.1, s.gunLen, C.steel, x, 0, s.gunLen / 2 - 0.4)
		gb.cyl(s.gunR, s.gunR, 1.4, 6, C.steel, x, 0.11, s.gunLen * 0.45, false, Math.PI / 2)
		gb.cyl(0.02, s.gunR, 0.2, 6, C.steel, x, 0.11, s.gunLen * 0.45 + 0.8, false, Math.PI / 2) // nose cone
	}
}

/** Nebelwerfer 42: ten tubes in two rows of five round a central frame. */
function tubes(gb: TankBuilder, def: TankDef) {
	const s = def.shape
	gb.box(s.tW * 0.8, 0.12, 0.5, C.steel, 0, -0.15, 0.1, true)
	for (let row = 0; row < 2; row++) {
		for (let i = 0; i < 5; i++) {
			const x = (i - 2) * s.gunR * 2.3
			gb.cyl(s.gunR, s.gunR, s.gunLen, 8, C.steel, x, row * s.gunR * 2.3, s.gunLen / 2 - 0.2, false, Math.PI / 2)
		}
	}
}

/** Mantlet, recoil sleeve, tapered barrel and muzzle brake as the vehicle's gun look describes them. */
function cannon(gb: TankBuilder, def: TankDef, base: THREE.Color) {
	const s = def.shape
	const look = s.gunLook ?? DEFAULT_GUN
	const r = s.gunR
	const mw = s.tW * (look.mantletW ?? 0.4)
	const mh = Math.min(s.tH * 0.62, r * 5 + 0.3)
	switch (look.mantlet) {
		case 'box':
			gb.box(mw, mh, 0.3, base, 0, 0, 0.1, true)
			break
		case 'round':
			gb.cyl(mh / 2, mh / 2, mw, 8, base, 0, 0, 0, true, 0, Math.PI / 2)
			break
		case 'ball':
			gb.part(
				new THREE.SphereGeometry(r * 3 + 0.18, 8, 6),
				base,
				new THREE.Matrix4().makeTranslation(0, 0, 0.05),
				true,
			)
			break
		case 'saukopf':
			gb.cyl(r * 1.6, r * 3 + 0.12, 0.5, 8, base, 0, 0, 0.2, true, Math.PI / 2)
			break
		case 'shield':
			gb.box(mw, s.tH * 0.75, 0.05, base, 0, s.tH * 0.12, 0.2, true)
			gb.box(0.35, 0.35, 0.9, C.steel, 0, 0, -0.35) // breech and cradle
			break
		case 'none':
			break
	}
	if (look.sleeve) gb.cyl(r * 1.9, r * 2, look.sleeve, 8, base, 0, 0, 0.25 + look.sleeve / 2, true, Math.PI / 2)
	gb.cyl(r, r * 1.35, s.gunLen, 8, base, 0, 0, s.gunLen / 2, true, Math.PI / 2)
	const end = s.gunLen
	switch (look.brake) {
		case 'single':
			gb.cyl(r * 1.7, r * 1.7, 0.3, 8, base, 0, 0, end - 0.15, true, Math.PI / 2)
			break
		case 'double':
			gb.cyl(r * 1.9, r * 1.9, 0.13, 8, base, 0, 0, end - 0.065, true, Math.PI / 2)
			gb.cyl(r * 1.9, r * 1.9, 0.13, 8, base, 0, 0, end - 0.32, true, Math.PI / 2)
			break
		case 'multi':
			gb.box(r * 3.4, r * 3, 0.65, base, 0, 0, end - 0.32, true)
			break
		case 'none':
			break
	}
}

/** The gun or the rocket launcher (in the gun frame); returns the muzzle point in that frame. */
export function buildGun(gb: TankBuilder, def: TankDef, base: THREE.Color): THREE.Vector3 {
	const s = def.shape
	if (s.launcher === 'rails') rails(gb, def)
	else if (s.launcher === 'tubes') tubes(gb, def)
	else cannon(gb, def, base)
	return new THREE.Vector3(0, s.launcher === 'rails' ? 0.11 : 0, s.gunLen + 0.2)
}
