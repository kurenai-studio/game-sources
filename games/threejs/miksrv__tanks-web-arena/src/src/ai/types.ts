export type BotMode = 'advance' | 'regroup' | 'engage' | 'hold' | 'retreat' | 'relocate' | 'hunt'

export interface Pt {
	x: number
	z: number
}

/** Driving inputs for one frame (−1..1). */
export interface DriveCommand {
	throttle: number
	steer: number
}
