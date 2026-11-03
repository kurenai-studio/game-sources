import {
	ARCHETYPES,
	MAP_PRESETS,
	MODE_LABEL,
	RENDER,
	ROLE_LABEL,
	TANKS,
	tanksOf,
	WEATHER,
	type BattleMode,
	type Nation,
	type TankDef,
} from '../config'
import type { MapChoice } from '../game/world'
import { FramePacer } from '../render/framePacer'
import { $, show } from './dom'
import { TankPreview } from './tankPreview'

const RAD_TO_DEG = 57.3
const MODE_NOTE: Record<BattleMode, string> = {
	standard: 'у каждой команды своя база: уничтожить всех или захватить базу противника',
	encounter: 'одна нейтральная база в центре: её может захватить любая команда',
	assault: 'одна команда обороняет базу, другая её штурмует; время на стороне обороны',
}

/** Bar scale maxima for the vehicle cards. */
const STAT_MAX = { hp: 1400, speed: 16, pen: 200, dmg: 2100, armor: 200, view: 410 }

function statBar(label: string, v: number, max: number, text: string): string {
	const width = Math.min(100, (v / max) * 100).toFixed(0)
	return `<div class="stat"><span>${label}</span><div class="sbar"><div style="width:${width}%"></div></div><b>${text}</b></div>`
}

/** Short special-feature notes under a vehicle card. */
function vehicleNotes(d: TankDef): string {
	const g = d.gun
	let fire = ''
	if (g.howitzer) {
		fire = g.salvo
			? `реактивная: залп ${g.salvo} ракет, только ОФ, сплэш ${g.splash} м`
			: 'гаубица: навесной огонь, вид сверху'
	} else if (g.arc < 3) fire = `без башни: сектор ±${Math.round(g.arc * RAD_TO_DEG)}°`
	let shell = ''
	if (g.derp) shell = `фугасы по умолчанию, сплэш ${g.splash} м`
	else if (g.bloomShot && !g.salvo) shell = 'автопушка: очередь без потери сведения'
	return [fire, shell, d.shape.openTop ? 'открытая рубка' : ''].filter(Boolean).join(' · ')
}

function vehicleCardHtml(d: TankDef): string {
	const dmg = d.gun.dmg * (d.gun.salvo ?? 1)
	const notes = vehicleNotes(d)
	const armor = `${d.armor.front}/${d.armor.side}/${d.armor.rear}`
	return (
		`<span class="role">${ROLE_LABEL[d.role]}</span><b>${d.name}</b>` +
		statBar('прочность', d.hp, STAT_MAX.hp, String(d.hp)) +
		statBar('скорость', d.speed, STAT_MAX.speed, `${Math.round(d.speed * 3.6)}`) +
		statBar('пробитие', d.gun.pen, STAT_MAX.pen, String(d.gun.pen)) +
		statBar('урон', dmg, STAT_MAX.dmg, String(dmg)) +
		statBar('броня', d.armor.front, STAT_MAX.armor, `${d.armor.front}`) +
		statBar('обзор', d.viewRange, STAT_MAX.view, String(d.viewRange)) +
		`<small>${d.gun.caliber} мм · перезарядка ${d.gun.reload} с · броня ${armor}${notes ? '<br>' + notes : ''}</small>`
	)
}

/** "13 машин": Russian plural of the vehicle count. */
function vehicleCount(n: number): string {
	const d = n % 10
	const teen = n % 100 >= 11 && n % 100 <= 14
	const word = teen || d === 0 || d >= 5 ? 'машин' : d === 1 ? 'машина' : 'машины'
	return `${n} ${word}`
}

/**
 * The battle help reflowed for the garage's full width: every "key — action" pair (lines and their " · " parts) is a
 * chip that does not break, so the list wraps into a few lines; the closing tip stays a line of its own.
 */
function controlsHtml(help: HTMLElement): string {
	const src = help.cloneNode(true) as HTMLElement
	const tip = src.querySelector('small')
	tip?.remove()
	const pairs = src.innerHTML
		.split(/<br\s*\/?>/)
		.flatMap((line) => line.split(' · '))
		.map((p) => p.trim().replace(/\s+/g, ' '))
		.filter(Boolean)
	return pairs.map((p) => `<span class="key">${p}</span>`).join('') + (tip ? tip.outerHTML : '')
}

const SEASON = { summer: 'лето', autumn: 'осень', winter: 'зима' } as const
const STORE_KEY = 'tanks-web-arena.battle'

/** The last map and mode choice (per browser; an empty or blocked storage gives the defaults). */
function loadChoice(): MapChoice {
	try {
		const c = JSON.parse(localStorage.getItem(STORE_KEY) ?? '{}') as Partial<MapChoice>
		const map = typeof c.map === 'string' && MAP_PRESETS.some((p) => p.id === c.map) ? c.map : 'random'
		const mode = c.mode && (c.mode === 'random' || c.mode in MODE_LABEL) ? c.mode : 'random'
		return { map, mode }
	} catch {
		return { map: 'random', mode: 'random' }
	}
}

function saveChoice(c: MapChoice) {
	try {
		localStorage.setItem(STORE_KEY, JSON.stringify(c))
	} catch {
		/* storage blocked: the choice lasts for the session */
	}
}

/** Vehicle selection screen: nation tabs, a carousel of vehicle cards with 3D portraits and the "to battle" button. */
export class Garage {
	nation: Nation = 'ussr'
	tankId = 't34_85'
	/** Map and battle mode for the next battles. */
	readonly choice: MapChoice = loadChoice()
	onGo: (() => void) | null = null
	private readonly preview = new TankPreview()
	private readonly pacer = new FramePacer()
	private cards = new Map<string, { el: HTMLElement; canvas: HTMLCanvasElement }>()
	/** Nation the cards were built for. */
	private builtFor: Nation | null = null
	private yaw = 0
	private lastFrame = 0
	private spinning = false

	constructor() {
		for (const n of this.nationTabs()) {
			n.onclick = () => {
				this.nation = n.dataset.n as Nation
				this.tankId = tanksOf(this.nation)[1]
				this.render()
			}
		}
		$('goBtn').onclick = () => this.onGo?.()
		$('garageHelp').innerHTML = controlsHtml($('help'))
		for (const c of Array.from($('garage').querySelectorAll<HTMLElement>('[data-count]')))
			c.textContent = vehicleCount(tanksOf(c.dataset.count as Nation).length)
		this.buildChoices()
		$('carPrev').onclick = () => this.step(-1)
		$('carNext').onclick = () => this.step(1)
		// A vertical wheel scrolls the row sideways
		$('tankList').addEventListener(
			'wheel',
			(e) => {
				if (Math.abs(e.deltaY) <= Math.abs(e.deltaX)) return
				e.preventDefault()
				$('tankList').scrollBy({ left: e.deltaY })
			},
			{ passive: false },
		)
		window.addEventListener('keydown', (e) => {
			if (!this.isOpen) return
			if (e.code === 'ArrowLeft' || e.code === 'KeyA') this.step(-1)
			else if (e.code === 'ArrowRight' || e.code === 'KeyD') this.step(1)
			else if (e.code === 'Enter') this.onGo?.()
		})
		window.addEventListener('resize', () => {
			if (this.isOpen) this.drawAll()
		})
	}

	get isOpen() {
		return $('garage').style.display === 'block'
	}

	show(on: boolean) {
		show($('garage'), on)
		if (on) {
			this.builtFor = null // the window may have changed size while the battle ran
			this.render()
		}
		if (on && !this.spinning) {
			this.spinning = true
			this.lastFrame = performance.now()
			requestAnimationFrame(this.spin)
		}
	}

	/** The map and mode chips: a random map or a named one, a random mode or a fixed one. */
	private buildChoices() {
		const maps: [string, string, string][] = [['random', 'Случайная', 'каждый бой новая карта']]
		for (const p of MAP_PRESETS) {
			const note = `${ARCHETYPES[p.archetype].label} · ${SEASON[p.season]} · ${WEATHER[p.weather].label}`
			maps.push([p.id, p.name, note])
		}
		const modes: [string, string, string][] = [['random', 'Случайный', 'стандартный, встречный или штурм']]
		for (const [m, label] of Object.entries(MODE_LABEL)) modes.push([m, label, MODE_NOTE[m as BattleMode]])
		this.chips(
			'mapChoice',
			maps,
			() => this.choice.map,
			(v) => (this.choice.map = v),
		)
		this.chips(
			'modeChoice',
			modes,
			() => this.choice.mode,
			(v) => (this.choice.mode = v as MapChoice['mode']),
		)
	}

	private chips(id: string, items: [string, string, string][], get: () => string, set: (v: string) => void) {
		const root = $(id)
		root.innerHTML = ''
		const els = items.map(([value, label, note]) => {
			const el = document.createElement('button')
			el.className = 'opt'
			el.textContent = label
			el.title = note
			el.onclick = () => {
				set(value)
				saveChoice(this.choice)
				for (const [i, e] of els.entries()) e.classList.toggle('on', items[i][0] === get())
			}
			el.classList.toggle('on', value === get())
			root.appendChild(el)
			return el
		})
	}

	private nationTabs(): HTMLElement[] {
		return Array.from($('garage').querySelectorAll<HTMLElement>('.nation'))
	}

	/** Move the selection by `dir` cards along the row. */
	private step(dir: number) {
		const ids = tanksOf(this.nation)
		const i = Math.max(0, Math.min(ids.length - 1, ids.indexOf(this.tankId) + dir))
		this.select(ids[i])
	}

	private select(id: string) {
		if (id === this.tankId) return
		this.tankId = id
		this.yaw = 0
		this.render()
	}

	private render() {
		for (const n of this.nationTabs()) n.classList.toggle('on', n.dataset.n === this.nation)
		if (this.builtFor !== this.nation) this.build()
		for (const [id, c] of this.cards) c.el.classList.toggle('on', id === this.tankId)
		const ids = tanksOf(this.nation)
		const i = ids.indexOf(this.tankId)
		;($('carPrev') as HTMLButtonElement).disabled = i <= 0
		;($('carNext') as HTMLButtonElement).disabled = i >= ids.length - 1
		this.cards.get(this.tankId)?.el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' })
	}

	/** Cards for the current nation, each with a still portrait; the selected one turns in `spin`. */
	private build() {
		const list = $('tankList')
		list.innerHTML = ''
		this.cards.clear()
		for (const id of tanksOf(this.nation)) {
			const el = document.createElement('div')
			el.className = 'tank'
			const canvas = document.createElement('canvas')
			canvas.className = 'model'
			el.appendChild(canvas)
			el.insertAdjacentHTML('beforeend', vehicleCardHtml(TANKS[id]))
			el.onclick = () => this.select(id)
			list.appendChild(el)
			this.cards.set(id, { el, canvas })
		}
		this.builtFor = this.nation
		this.drawAll()
	}

	/** Size every portrait canvas to its box in device pixels and draw it. */
	private drawAll() {
		const dpr = Math.min(window.devicePixelRatio, 2)
		for (const [id, { canvas }] of this.cards) {
			canvas.width = Math.round(canvas.clientWidth * dpr)
			canvas.height = Math.round(canvas.clientHeight * dpr)
			this.preview.draw(TANKS[id], canvas, id === this.tankId ? this.yaw : 0)
		}
	}

	private readonly spin = (now: number) => {
		if (!this.isOpen) {
			this.spinning = false
			return
		}
		requestAnimationFrame(this.spin)
		if (!this.pacer.shouldRender(now, RENDER.garageFps)) return
		this.yaw += TankPreview.spin((now - this.lastFrame) / 1000)
		this.lastFrame = now
		const card = this.cards.get(this.tankId)
		if (card) this.preview.draw(TANKS[this.tankId], card.canvas, this.yaw)
	}
}
