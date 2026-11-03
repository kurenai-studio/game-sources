// DOM access is cached and every write is skipped when the value is unchanged: the HUD runs every frame, and an
// unconditional textContent / style write costs a style recalculation even when nothing moved.

const elements = new Map<string, HTMLElement>()
const memo = new WeakMap<Element, Record<string, string>>()

/** Element by id (cached). Throws when the page lacks it: a missing HUD element is a markup bug. */
export function $(id: string): HTMLElement {
	let e = elements.get(id)
	if (!e) {
		const found = document.getElementById(id)
		if (!found) throw new Error(`HUD element #${id} is missing from index.html`)
		e = found
		elements.set(id, e)
	}
	return e
}

function memoOf(el: Element): Record<string, string> {
	let m = memo.get(el)
	if (!m) {
		m = {}
		memo.set(el, m)
	}
	return m
}

/** Runs `write` only when `key` of `el` changes to `value`. */
function writeOnChange(el: Element, key: string, value: string, write: () => void) {
	const m = memoOf(el)
	if (m[key] === value) return
	m[key] = value
	write()
}

export const setText = (el: HTMLElement, v: string) => writeOnChange(el, 'text', v, () => (el.textContent = v))
export const setHtml = (el: HTMLElement, v: string) => writeOnChange(el, 'html', v, () => (el.innerHTML = v))
export const setClass = (el: HTMLElement, v: string) => writeOnChange(el, 'cls', v, () => (el.className = v))
export const setAttr = (el: Element, name: string, v: string) =>
	writeOnChange(el, 'a:' + name, v, () => el.setAttribute(name, v))
export const setStyle = (el: HTMLElement, prop: string, v: string) =>
	writeOnChange(el, 's:' + prop, v, () => el.style.setProperty(cssName(prop), v))
export const show = (el: HTMLElement, on: boolean, mode = 'block') => setStyle(el, 'display', on ? mode : 'none')

/** camelCase style property → CSS name (`background` stays, `fontSize` → `font-size`). */
const cssName = (prop: string) => prop.replace(/[A-Z]/g, (c) => '-' + c.toLowerCase())

/** Element with a class (and optional text), appended to `parent`. */
export function createEl<K extends keyof HTMLElementTagNameMap>(
	tag: K,
	className: string,
	parent?: HTMLElement,
): HTMLElementTagNameMap[K] {
	const el = document.createElement(tag)
	el.className = className
	parent?.appendChild(el)
	return el
}

/** Normalised device coordinates (−1..1) → CSS pixels of the window. */
export function ndcToScreen(x: number, y: number): { x: number; y: number } {
	return { x: ((x + 1) / 2) * window.innerWidth, y: ((1 - y) / 2) * window.innerHeight }
}
