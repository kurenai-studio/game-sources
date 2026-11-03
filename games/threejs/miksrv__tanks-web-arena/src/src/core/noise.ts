// 2D simplex noise (Gustavson), seeded.

const GRAD = [
	[1, 1],
	[-1, 1],
	[1, -1],
	[-1, -1],
	[1, 0],
	[-1, 0],
	[0, 1],
	[0, -1],
]

export function mulberry32(seed: number) {
	return () => {
		seed |= 0
		seed = (seed + 0x6d2b79f5) | 0
		let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
		t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296
	}
}

export class Simplex2D {
	private perm = new Uint8Array(512)
	constructor(seed: number) {
		const rnd = mulberry32(seed)
		const p = Array.from({ length: 256 }, (_, i) => i)
		for (let i = 255; i > 0; i--) {
			const j = Math.floor(rnd() * (i + 1))
			;[p[i], p[j]] = [p[j], p[i]]
		}
		for (let i = 0; i < 512; i++) this.perm[i] = p[i & 255]
	}
	noise(x: number, y: number): number {
		const F2 = 0.5 * (Math.sqrt(3) - 1)
		const G2 = (3 - Math.sqrt(3)) / 6
		const s = (x + y) * F2
		const i = Math.floor(x + s)
		const j = Math.floor(y + s)
		const t = (i + j) * G2
		const x0 = x - (i - t)
		const y0 = y - (j - t)
		const i1 = x0 > y0 ? 1 : 0
		const j1 = x0 > y0 ? 0 : 1
		const x1 = x0 - i1 + G2
		const y1 = y0 - j1 + G2
		const x2 = x0 - 1 + 2 * G2
		const y2 = y0 - 1 + 2 * G2
		const ii = i & 255
		const jj = j & 255
		let n = 0
		const corner = (xx: number, yy: number, gi: number) => {
			let t = 0.5 - xx * xx - yy * yy
			if (t < 0) return 0
			t *= t
			const g = GRAD[gi % 8]
			return t * t * (g[0] * xx + g[1] * yy)
		}
		n += corner(x0, y0, this.perm[ii + this.perm[jj]])
		n += corner(x1, y1, this.perm[ii + i1 + this.perm[jj + j1]])
		n += corner(x2, y2, this.perm[ii + 1 + this.perm[jj + 1]])
		return 70 * n
	}
	fbm(x: number, y: number, octaves = 4, lac = 2, gain = 0.5): number {
		let a = 1
		let f = 1
		let sum = 0
		let norm = 0
		for (let o = 0; o < octaves; o++) {
			sum += a * this.noise(x * f, y * f)
			norm += a
			a *= gain
			f *= lac
		}
		return sum / norm
	}
}
