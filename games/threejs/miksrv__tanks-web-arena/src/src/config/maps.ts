import type { Weather } from './weather'
import type { Archetype } from './world'

/** A named map: a fixed seed with its country, season and weather (the layout is the seed's every time). */
export interface MapPreset {
	id: string
	name: string
	seed: number
	archetype: Archetype
	season: 'summer' | 'autumn' | 'winter'
	weather: Weather
}

export const MAP_PRESETS: MapPreset[] = [
	{ id: 'prokhorovka', name: 'Прохоровка', seed: 1948, archetype: 'steppe', season: 'summer', weather: 'clear' },
	{ id: 'kursk', name: 'Курская дуга', seed: 1947, archetype: 'steppe', season: 'summer', weather: 'dusk' },
	{ id: 'polesie', name: 'Полесье', seed: 3103, archetype: 'swamp', season: 'autumn', weather: 'fog' },
	{ id: 'pass', name: 'Перевал', seed: 4201, archetype: 'pass', season: 'winter', weather: 'snow' },
	{ id: 'kerch', name: 'Керчь', seed: 5502, archetype: 'coast', season: 'summer', weather: 'clear' },
	{ id: 'rzhev', name: 'Ржев', seed: 6604, archetype: 'classic', season: 'winter', weather: 'overcast' },
	{ id: 'orel', name: 'Орёл', seed: 6602, archetype: 'classic', season: 'autumn', weather: 'rain' },
	{ id: 'malinovka', name: 'Малиновка', seed: 6601, archetype: 'classic', season: 'summer', weather: 'dawn' },
]
