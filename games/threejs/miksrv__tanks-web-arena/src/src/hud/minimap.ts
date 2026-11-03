import { CAPTURE, WORLD_HALF } from '../config'
import type { CaptureZone } from '../game/capture'
import { Spotting } from '../game/spotting'
import type { Tank } from '../tank/tank'
import { PALETTE, type Biome, type Terrain } from '../world/terrain'

type Rgb = [number, number, number]

/** Minimap size in canvas pixels. */
export const MINIMAP_SIZE = 220
const REDRAW_INTERVAL = 1 / 20 // s: nothing on the map moves faster than that
const PING_LIFE = 3 // s
const SCALE = MINIMAP_SIZE / (WORLD_HALF * 2)
const mx = (x: number) => (x + WORLD_HALF) * SCALE
const mz = (z: number) => (z + WORLD_HALF) * SCALE

const hexToRgb = (h: string): Rgb => [
	parseInt(h.slice(1, 3), 16),
	parseInt(h.slice(3, 5), 16),
	parseInt(h.slice(5, 7), 16),
]

function biomeColors(terrain: Terrain): Record<Biome, Rgb> {
	const pal = PALETTE[terrain.season]
	const col: Record<Biome, Rgb> = {
		field: hexToRgb(pal.field),
		meadow: hexToRgb(pal.meadow),
		forest: hexToRgb(pal.forest),
		mountain: hexToRgb(pal.mountain),
		road: hexToRgb(pal.road),
		water: [50, 100, 140],
		mud: hexToRgb(pal.mud),
		village: hexToRgb(pal.village),
		town: hexToRgb(pal.town),
		base: hexToRgb(pal.base),
		sand: hexToRgb(pal.sand),
		rail: [70, 64, 58],
	}
	if (terrain.season === 'winter') {
		col.forest = [150, 165, 150]
		col.road = [120, 112, 105]
	}
	return col
}

/** Relief shading: mountains darken with height, lowland gets a gentle lift. */
function shadeOf(biome: Biome, h: number): number {
	if (biome === 'mountain') return 0.6 + Math.min(0.5, (h - 20) / 80)
	return 0.85 + 0.15 * Math.min(1, Math.max(0, (h - 2) / 25))
}

/** Bridges as light bars across the river, fords as pale dots. */
function drawCrossings(ctx: CanvasRenderingContext2D, terrain: Terrain) {
	for (const cr of terrain.crossings) {
		if (cr.kind === 'bridge') {
			ctx.strokeStyle = '#f2e8cc'
			ctx.lineWidth = 2.5
			ctx.lineCap = 'round'
			ctx.beginPath()
			ctx.moveTo(mx(cr.x - cr.nx * cr.half), mz(cr.z - cr.nz * cr.half))
			ctx.lineTo(mx(cr.x + cr.nx * cr.half), mz(cr.z + cr.nz * cr.half))
			ctx.stroke()
		} else {
			ctx.fillStyle = 'rgba(170, 215, 240, 0.9)'
			ctx.beginPath()
			ctx.arc(mx(cr.x), mz(cr.z), 2.5, 0, Math.PI * 2)
			ctx.fill()
		}
	}
}

function context2d(c: HTMLCanvasElement): CanvasRenderingContext2D {
	const ctx = c.getContext('2d')
	if (!ctx) throw new Error('2D canvas is not available')
	return ctx
}

/** Paint the minimap backdrop for a terrain (≈ 50k samples); install it with `Minimap.setBackdrop`. */
export function bakeMinimap(terrain: Terrain): HTMLCanvasElement {
	const c = document.createElement('canvas')
	c.width = c.height = MINIMAP_SIZE
	const ctx = context2d(c)
	const img = ctx.createImageData(MINIMAP_SIZE, MINIMAP_SIZE)
	const d = img.data
	const col = biomeColors(terrain)
	for (let j = 0; j < MINIMAP_SIZE; j++) {
		for (let i = 0; i < MINIMAP_SIZE; i++) {
			const x = -WORLD_HALF + (i / MINIMAP_SIZE) * WORLD_HALF * 2
			const z = -WORLD_HALF + (j / MINIMAP_SIZE) * WORLD_HALF * 2
			const b = terrain.biome(x, z)
			const shade = shadeOf(b, terrain.height(x, z))
			const [r, g, bb] = col[b]
			const k = (j * MINIMAP_SIZE + i) * 4
			d[k] = r * shade
			d[k + 1] = g * shade
			d[k + 2] = bb * shade
			d[k + 3] = 235
		}
	}
	ctx.putImageData(img, 0, 0)
	drawCrossings(ctx, terrain)
	return c
}

/** The live minimap: backdrop, spotted tanks, the player's arrow and view cone. */
export class Minimap {
	private readonly ctx: CanvasRenderingContext2D
	private backdrop: HTMLCanvasElement | null = null
	private timer = 0
	/** Team signal pings: expanding rings that fade out. */
	private pings: { x: number; z: number; color: string; life: number }[] = []

	constructor(canvas: HTMLCanvasElement) {
		canvas.width = canvas.height = MINIMAP_SIZE
		this.ctx = context2d(canvas)
	}

	setBackdrop(c: HTMLCanvasElement) {
		this.backdrop = c
		this.timer = 0
	}

	ping(x: number, z: number, color: string) {
		this.pings.push({ x, z, color, life: PING_LIFE })
		this.timer = 0
	}

	update(dt: number, player: Tank, tanks: Tank[], zones: readonly CaptureZone[], cameraYaw: number, time: number) {
		for (const p of this.pings) p.life -= dt
		this.pings = this.pings.filter((p) => p.life > 0)
		this.timer -= dt
		if (this.timer > 0) return
		this.timer = REDRAW_INTERVAL
		this.draw(player, tanks, zones, cameraYaw, time)
	}

	private draw(player: Tank, tanks: Tank[], zones: readonly CaptureZone[], cameraYaw: number, time: number) {
		if (!this.backdrop) return
		const ctx = this.ctx
		ctx.drawImage(this.backdrop, 0, 0)
		for (const z of zones) this.drawZone(z, player.team)
		for (const t of tanks) {
			if (t !== player && Spotting.visibleTo(player.team, t, time)) this.drawTank(t, t.team === player.team)
		}
		this.drawPlayer(player, cameraYaw)
		for (const p of this.pings) this.drawPing(p)
	}

	private drawPing(p: { x: number; z: number; color: string; life: number }) {
		const ctx = this.ctx
		const k = 1 - p.life / PING_LIFE
		ctx.globalAlpha = Math.min(1, p.life)
		ctx.strokeStyle = p.color
		ctx.lineWidth = 2
		for (const r of [4 + ((k * 3) % 1) * 12, 3]) {
			ctx.beginPath()
			ctx.arc(mx(p.x), mz(p.z), r, 0, Math.PI * 2)
			ctx.stroke()
		}
		ctx.globalAlpha = 1
		ctx.lineWidth = 1
	}

	/** A base circle in its side's colour, with the capture progress as an arc. */
	private drawZone(z: CaptureZone, team: 0 | 1) {
		const ctx = this.ctx
		const r = CAPTURE.radius * SCALE
		ctx.lineWidth = 1.5
		ctx.strokeStyle = z.owner === -1 ? '#f2ecd8' : z.owner === team ? '#8fd36b' : '#ff5a5a'
		ctx.beginPath()
		ctx.arc(mx(z.x), mz(z.z), r, 0, Math.PI * 2)
		ctx.stroke()
		if (z.points <= 0 || z.capturing === null) return
		ctx.lineWidth = 3
		ctx.strokeStyle = z.capturing === team ? '#8fd36b' : '#ff5a5a'
		ctx.beginPath()
		ctx.arc(mx(z.x), mz(z.z), r + 2.5, -Math.PI / 2, -Math.PI / 2 + (z.points / CAPTURE.points) * Math.PI * 2)
		ctx.stroke()
		ctx.lineWidth = 1
	}

	private drawTank(t: Tank, ally: boolean) {
		const ctx = this.ctx
		ctx.fillStyle = !t.alive ? '#444' : ally ? '#8fd36b' : '#ff5a5a'
		ctx.beginPath()
		ctx.arc(mx(t.pos.x), mz(t.pos.z), 3, 0, Math.PI * 2)
		ctx.fill()
		if (!t.alive) return
		ctx.strokeStyle = ctx.fillStyle
		ctx.beginPath()
		ctx.moveTo(mx(t.pos.x), mz(t.pos.z))
		ctx.lineTo(mx(t.pos.x) + t.fx * 6, mz(t.pos.z) + t.fz * 6)
		ctx.stroke()
	}

	private drawPlayer(player: Tank, cameraYaw: number) {
		const ctx = this.ctx
		const px = mx(player.pos.x)
		const pz = mz(player.pos.z)
		const { fx, fz } = player
		// View direction cone
		const heading = -cameraYaw + Math.PI / 2
		ctx.fillStyle = 'rgba(255,255,255,0.12)'
		ctx.beginPath()
		ctx.moveTo(px, pz)
		ctx.arc(px, pz, player.viewRange * SCALE, heading - 0.5, heading + 0.5)
		ctx.closePath()
		ctx.fill()
		// Arrow
		ctx.fillStyle = '#fff'
		ctx.strokeStyle = '#000'
		ctx.beginPath()
		ctx.moveTo(px + fx * 6, pz + fz * 6)
		ctx.lineTo(px - fx * 4 + fz * 3.5, pz - fz * 4 - fx * 3.5)
		ctx.lineTo(px - fx * 4 - fz * 3.5, pz - fz * 4 + fx * 3.5)
		ctx.closePath()
		ctx.fill()
		ctx.stroke()
	}
}
