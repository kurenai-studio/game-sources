import { ARCHETYPES, MATCH, MODE_LABEL, TANKS, WEATHER, type Archetype, type BattleMode, type Weather } from '../config'

/**
 * Test hooks read from the URL:
 * - `?autostart` skips the garage (and restarts after each result)
 * - `&seed=N` fixes the first map, `&tank=id` picks the player's vehicle
 * - `&round=N` shortens the round, `&speed=K` scales game time
 * - `&weather=fog` forces the weather of every map, `&mode=encounter` the battle mode, `&map=steppe` the archetype
 * - `&view=top` puts the satellite camera over the map centre (screenshots of the whole map)
 * - `&debug` logs the match state every 5 s to the console
 */
export interface TestOptions {
	autostart: boolean
	seed: number | null
	tankId: string | null
	timeScale: number
	overviewTop: boolean
	debug: boolean
	weather: Weather | null
	mode: BattleMode | null
	archetype: Archetype | null
}

export function readTestOptions(search = location.search): TestOptions {
	const params = new URLSearchParams(search)
	const num = (name: string) => (params.has(name) ? Number(params.get(name)) : null)
	const tank = params.get('tank')
	const round = num('round')
	const weather = params.get('weather')
	const mode = params.get('mode')
	const map = params.get('map')
	if (round !== null) MATCH.roundTime = round
	return {
		autostart: params.has('autostart'),
		seed: num('seed'),
		tankId: tank && tank in TANKS ? tank : null,
		timeScale: num('speed') ?? 1,
		overviewTop: params.get('view') === 'top',
		debug: params.has('debug'),
		weather: weather && weather in WEATHER ? (weather as Weather) : null,
		mode: mode && mode in MODE_LABEL ? (mode as BattleMode) : null,
		archetype: map && map in ARCHETYPES ? (map as Archetype) : null,
	}
}

/** Puts a debugging handle on `window` (for the browser console and automated tests). */
export function exposeOnWindow(name: string, value: unknown) {
	;(window as unknown as Record<string, unknown>)[name] = value
}
