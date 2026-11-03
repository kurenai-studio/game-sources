import * as THREE from 'three'

/** Full-window WebGL renderer with shadows and filmic tone mapping, attached to the page. */
export function createRenderer(pixelRatio: number): THREE.WebGLRenderer {
	const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' })
	renderer.setPixelRatio(pixelRatio)
	renderer.setSize(window.innerWidth, window.innerHeight)
	renderer.shadowMap.enabled = true
	renderer.shadowMap.type = THREE.PCFShadowMap // PCFSoft costs ~2× the shadow taps for a barely visible difference
	renderer.toneMapping = THREE.ACESFilmicToneMapping
	renderer.toneMappingExposure = 1.0
	document.body.prepend(renderer.domElement)
	return renderer
}
