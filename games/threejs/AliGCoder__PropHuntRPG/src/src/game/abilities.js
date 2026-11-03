/**
 * Trade abilities as data. The host simulation looks up `effect` and applies
 * it (see HostServer#useAbility); the UI reads names/descriptions/cooldowns.
 */
export const ABILITIES = Object.freeze( {
	hunter: {
		woodcutting: {
			id: 'timber_sense', name: 'Timber Sense', cooldown: 25,
			description: 'Outline every hider disguised as a wood prop within 18 m.',
			effect: { type: 'reveal', radius: 18, duration: 2.5, family: 'woodcutting' }
		},
		mining: {
			id: 'seismic_pulse', name: 'Seismic Pulse', cooldown: 25,
			description: 'Outline every hider within 9 m.',
			effect: { type: 'reveal', radius: 9, duration: 2, family: null }
		},
		fishing: {
			id: 'harpoon_line', name: 'Harpoon Line', cooldown: 20,
			description: 'Long-range shot (40 m). Reveals and damages the hider it hits.',
			effect: { type: 'harpoon', range: 40, duration: 4, damage: 15 }
		}
	},
	hider: {
		woodcutting: {
			id: 'take_root', name: 'Take Root', cooldown: 20,
			description: 'Take 50% less damage for 6 s, but you cannot move.',
			effect: { type: 'root', duration: 6, reduction: 0.5 }
		},
		mining: {
			id: 'decoy', name: 'Decoy', cooldown: 30,
			description: 'Leave a copy of your current prop behind (max 2).',
			effect: { type: 'decoy' }
		},
		fishing: {
			id: 'slippery', name: 'Slippery', cooldown: 18,
			description: '+80% movement speed for 3 s.',
			effect: { type: 'speed', duration: 3, multiplier: 1.8 }
		}
	}
} );

export function getAbility( team, trade ) {

	return ABILITIES[ team ]?.[ trade ] ?? null;

}
