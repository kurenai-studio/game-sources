// The player's aircraft (V in battle): an arcade flight model and its bomb load. Units: metres, seconds, radians.

export const PLANE = {
	spawnHeight: 130, // m above the player's tank when the plane is called in
	ceiling: 380, // m above sea level: no climbing past it
	minSpeed: 38, // m/s at idle throttle in level flight
	maxSpeed: 85, // m/s at full throttle
	cruise: 0.6, // throttle at take-off
	throttleRate: 0.6, // throttle change per second while W / S is held
	accel: 0.6, // 1/s: how fast the speed follows the throttle
	climbDrag: 0.5, // share of gravity that slows a climb and speeds up a dive
	turnRate: 0.85, // rad/s of heading toward the mouse direction
	pitchRate: 0.8, // rad/s of nose up/down toward the mouse direction
	maxClimb: 0.7, // rad nose up
	maxDive: 1.1, // rad nose down
	maxBank: 1.2, // rad of roll in a turn (cosmetic)
	edge: 420, // m from the centre: past it the plane turns back over the map
	spotRadius: 220, // m on the ground around the plane where enemies are spotted for the team
	cooldown: 6, // s after a crash before the plane can be called in again
	camera: { distance: 22, min: 12, max: 60, height: 4 },
	bomb: {
		max: 6, // bombs in the bays
		rearm: 5, // s per bomb restocked while flying
		interval: 0.35, // s between two drops
		pen: 120, // mm: a direct hit goes through any roof
		dmg: 800,
		caliber: 250,
		splash: 14, // m blast radius
		life: 30, // s of free fall before the bomb is dropped from the list
	},
}
