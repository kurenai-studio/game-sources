/**
 * Global tunables. Gameplay balance lives in `game/rules.js`; this file holds
 * engine / timing / world constants only.
 */
export const CONFIG = Object.freeze( {

	net: {
		peerPrefix: 'prophunt-rpg-v1-',   // namespaces lobby codes on the PeerJS broker
		snapshotHz: 15,
		positionHz: 20,
		codeLength: 5
	},

	round: {
		prepSeconds: 30,
		huntSeconds: 180,
		resultsSeconds: 8,
		minPlayers: 2
	},

	world: {
		size: 180,          // terrain edge length (world units = metres)
		islandRadius: 72,
		waterLevel: 0,
		terrainSegments: 180
	},

	player: {
		radius: 0.4,
		height: 1.7,
		walkSpeed: 5.2,
		sprintMultiplier: 1.55,
		jumpVelocity: 6.5,
		gravity: 20,
		swimSpeedMultiplier: 0.55
	},

	camera: {
		fov: 65,
		distance: 5,
		height: 1.75,
		shoulder: 0.55
	},

	quality: {
		high: { pixelRatio: 2, shadowMap: 2048, grass: 30000, ao: true, bloom: true, msaa: 0 },
		medium: { pixelRatio: 1.5, shadowMap: 1024, grass: 16000, ao: false, bloom: true, msaa: 4 },
		low: { pixelRatio: 1, shadowMap: 1024, grass: 6000, ao: false, bloom: false, msaa: 0 }
	}

} );
