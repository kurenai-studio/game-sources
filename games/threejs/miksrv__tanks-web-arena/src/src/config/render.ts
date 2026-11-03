export const RENDER = {
	maxFps: 60, // frame-rate cap on any refresh rate (high-refresh displays would otherwise multiply the GPU load and heat)
	garageFps: 30, // nothing moves in the garage backdrop
	maxScale: 1.25, // render scale ceiling (× devicePixelRatio capped here); the adaptive scaler works below it
	minScale: 0.75,
}

export const CAMERA = {
	distance: 14, // m behind the tank
	minDistance: 7,
	maxDistance: 32,
	height: 5,
	sniperFov: [16, 8, 4], // deg zoom steps
	fov: 55,
	artyHeight: [90, 520, 260] as const, // satellite view height above the aim point: min, max, default (wheel zooms)
}
