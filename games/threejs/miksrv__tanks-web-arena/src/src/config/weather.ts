// Weather and time of day: rolled per map; the look lives in src/render/environment.ts.

export type Weather = 'clear' | 'overcast' | 'dawn' | 'dusk' | 'fog' | 'rain' | 'snow'

export interface WeatherDef {
	label: string
	/** View range multiplier for every vehicle. */
	view: number
	/** Fog distance multiplier for the ground view (the satellite view gets `artyFog`). */
	fog: number
	artyFog: number
}

export const WEATHER: Record<Weather, WeatherDef> = {
	clear: { label: 'ясно', view: 1, fog: 1, artyFog: 1 },
	overcast: { label: 'пасмурно', view: 0.95, fog: 0.85, artyFog: 0.9 },
	dawn: { label: 'рассвет', view: 0.9, fog: 0.8, artyFog: 0.85 },
	dusk: { label: 'закат', view: 0.85, fog: 0.75, artyFog: 0.8 },
	fog: { label: 'туман', view: 0.6, fog: 0.22, artyFog: 0.4 },
	rain: { label: 'дождь', view: 0.8, fog: 0.6, artyFog: 0.7 },
	snow: { label: 'снегопад', view: 0.8, fog: 0.55, artyFog: 0.65 },
}

/** Roll weights per season (rain never falls in winter, snow only then). */
export const WEATHER_ODDS: Record<'summer' | 'autumn' | 'winter', Partial<Record<Weather, number>>> = {
	summer: { clear: 0.38, overcast: 0.14, dawn: 0.1, dusk: 0.12, fog: 0.1, rain: 0.16 },
	autumn: { clear: 0.22, overcast: 0.22, dawn: 0.08, dusk: 0.1, fog: 0.16, rain: 0.22 },
	winter: { clear: 0.3, overcast: 0.22, dawn: 0.08, dusk: 0.1, fog: 0.12, snow: 0.18 },
}
