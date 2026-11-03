/** Oriented box on the XZ plane with a height band — buildings, rocks, tank hulls all use it. */
export class OBB {
	cos: number
	sin: number
	/** Scratch output of `toLocal` (no per-call allocation). */
	private lx = 0
	private lz = 0
	constructor(
		public x: number,
		public z: number,
		public hw: number,
		public hd: number,
		public rot: number,
		public y0: number,
		public y1: number,
	) {
		this.cos = Math.cos(rot)
		this.sin = Math.sin(rot)
	}
	set(x: number, z: number, rot: number) {
		this.x = x
		this.z = z
		this.rot = rot
		this.cos = Math.cos(rot)
		this.sin = Math.sin(rot)
	}
	/** World → local into `this.lx` / `this.lz` (lx along the box's own x/width axis, lz along its depth axis). */
	private toLocal(x: number, z: number) {
		const dx = x - this.x
		const dz = z - this.z
		this.lx = dx * this.cos - dz * this.sin
		this.lz = dx * this.sin + dz * this.cos
	}
	toWorld(lx: number, lz: number): [number, number] {
		return [this.x + lx * this.cos + lz * this.sin, this.z - lx * this.sin + lz * this.cos]
	}
	contains(x: number, z: number, pad = 0): boolean {
		this.toLocal(x, z)
		return Math.abs(this.lx) <= this.hw + pad && Math.abs(this.lz) <= this.hd + pad
	}
	/** Push a circle out of the box; returns the push vector (0,0 when not overlapping). */
	pushCircle(x: number, z: number, r: number, out: { x: number; z: number }): boolean {
		this.toLocal(x, z)
		const lx = this.lx
		const lz = this.lz
		const cx = Math.max(-this.hw, Math.min(this.hw, lx))
		const cz = Math.max(-this.hd, Math.min(this.hd, lz))
		let dx = lx - cx
		let dz = lz - cz
		let d = Math.hypot(dx, dz)
		if (d >= r) {
			out.x = out.z = 0
			return false
		}
		if (d < 1e-6) {
			// Centre is inside: push out through the nearest face
			const px = this.hw - Math.abs(lx)
			const pz = this.hd - Math.abs(lz)
			if (px < pz) {
				dx = Math.sign(lx) || 1
				dz = 0
				d = -px
			} else {
				dx = 0
				dz = Math.sign(lz) || 1
				d = -pz
			}
			const push = r - d
			out.x = dx * this.cos + dz * this.sin
			out.z = -dx * this.sin + dz * this.cos
			out.x *= push
			out.z *= push
			return true
		}
		const push = (r - d) / d
		const wx = dx * this.cos + dz * this.sin
		const wz = -dx * this.sin + dz * this.cos
		out.x = wx * push
		out.z = wz * push
		return true
	}
	/**
	 * Segment (ax,ay,az)→(bx,by,bz) vs the box: returns the entry parameter t ∈ (0,1] or -1.
	 * A segment that starts inside the box does not hit it (a gun poking through a wall fires out of it; a camera
	 * inside a house looks out of it). The hit normal (world XZ or ±Y) is written to `n` when given.
	 */
	raySegment(
		ax: number,
		ay: number,
		az: number,
		bx: number,
		by: number,
		bz: number,
		n?: { x: number; y: number; z: number },
	): number {
		this.toLocal(ax, az)
		const lax = this.lx
		const laz = this.lz
		if (Math.abs(lax) <= this.hw && Math.abs(laz) <= this.hd && ay >= this.y0 && ay <= this.y1) return -1
		this.toLocal(bx, bz)
		const lbx = this.lx
		const lbz = this.lz
		const dx = lbx - lax
		const dy = by - ay
		const dz = lbz - laz
		let t0 = 0
		let t1 = 1
		let axis = -1
		let sign = 0
		const slab = (p: number, d: number, lo: number, hi: number, ax: number) => {
			if (Math.abs(d) < 1e-9) return p >= lo && p <= hi
			let ta = (lo - p) / d
			let tb = (hi - p) / d
			let s = -1
			if (ta > tb) {
				;[ta, tb] = [tb, ta]
				s = 1
			}
			if (ta > t0) {
				t0 = ta
				axis = ax
				sign = s
			}
			if (tb < t1) t1 = tb
			return t0 <= t1
		}
		if (!slab(lax, dx, -this.hw, this.hw, 0)) return -1
		if (!slab(ay, dy, this.y0, this.y1, 1)) return -1
		if (!slab(laz, dz, -this.hd, this.hd, 2)) return -1
		if (t0 > 1 || t1 < 0) return -1
		if (n) {
			if (axis === 0) {
				n.x = sign * this.cos
				n.y = 0
				n.z = -sign * this.sin
			} else if (axis === 2) {
				n.x = sign * this.sin
				n.y = 0
				n.z = sign * this.cos
			} else {
				n.x = 0
				n.y = sign
				n.z = 0
			}
			if (axis === -1) {
				n.x = 0
				n.y = 1
				n.z = 0
			}
		}
		return Math.max(0, t0)
	}
}
