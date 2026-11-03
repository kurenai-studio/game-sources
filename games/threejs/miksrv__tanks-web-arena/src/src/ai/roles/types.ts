import type { Tank, WorldRefs } from '../../tank/tank'
import type { Fighter } from '../fight'
import type { BotGunner } from '../gunner'
import type { TeamTactics } from '../team'
import type { BotMode, DriveCommand, Pt } from '../types'

/** What a role sees of its bot, and may steer: the shared state and the moves every role can make. */
export interface Bot {
	readonly tank: Tank
	readonly tactics: TeamTactics
	readonly gunner: BotGunner
	readonly fighter: Fighter
	mode: BotMode
	target: Tank | null
	/** Where to stop at the end of the current path (null = drive through). */
	holdSpot: Pt | null
	readonly pathDone: boolean
	/** The last enemy is out there: everyone hunts it, nobody waits or falls back. */
	readonly hunting: boolean
	/** Sent back to break up a capture of our base: stay put there. */
	readonly defending: boolean
	/** On the way to (or in) a base circle to take it. */
	readonly capturing: boolean
	/** Taking a base or sent to defend one: no joining fights on the way, no moving off. */
	readonly onObjective: boolean
	/** On an objective and inside its circle: it must not leave it. */
	readonly holdingCircle: boolean
	setPath(path: Pt[], holdSpot: Pt | null): void
	/** Drive to `spot` (over a crossing if one is in the way) and stop there. */
	goTo(w: WorldRefs, spot: Pt): void
	/** Go and look for the enemy (mode 'hunt'): around the last sighting, or across its half of the map. */
	seek(w: WorldRefs, time: number): void
	/** Take a base circle (always with `force`, else by the team's odds); false when there is none to take. */
	capture(w: WorldRefs, force: boolean): boolean
	dist(p: Pt | Tank): number
}

/** One frame's inputs for a role. */
export interface Frame {
	w: WorldRefs
	dt: number
	time: number
	/** Distance to the nearest enemy the team sees (∞ when none). */
	enemyNear: number
	/** Took damage since the last frame. */
	hurt: boolean
}

/** Round-start plan: where to go and where to stop. */
export interface RoundPlan {
	mode: BotMode
	path: Pt[]
	holdSpot: Pt | null
}

/**
 * The behaviour of one vehicle class. One instance per bot, so a role may keep its own state; the bot core
 * (`bot.ts`) does the targeting, gunnery, driving and the hunt for the last enemy, and asks the role for the rest.
 */
export interface RoleAi {
	plan(w: WorldRefs, bot: Bot): RoundPlan
	/** The role's decisions each frame, after targeting and before driving: survival, joining a fight, moving on. */
	think(bot: Bot, f: Frame): void
	/** A target the role insists on (e.g. a raiding scout's enemy artillery), else null for the usual choice. */
	preferTarget?(bot: Bot, w: WorldRefs, time: number): Tank | null
	/** In a fight: metres past where the team wants us (> 0 = come no further forward). */
	aheadBy?(bot: Bot, w: WorldRefs, engaged: boolean): number
	/** Driving in a role's own mode (e.g. 'regroup'); true when it drove this frame. */
	drive?(bot: Bot, w: WorldRefs, cmd: DriveCommand): boolean
}
