// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Feel numbers of the Yard that are not part of the CONCEPT_V2 curve: sizes, ranges and timings.
// First guesses, written down so the playtest can move them. The round curve itself lives in sim/curve.ts.

/** Every phone sees the same world width, so the ladder is fair; the height follows the screen's shape. */
export const VIEW_W = 720;
/** The Yard: two screens wide and one and a half tall, about three phone screens of ground. */
export const WORLD_W = 1440;
export const WORLD_H = 2340;
/** Width of the soft boundary band where the ant's outward speed fades to zero. */
export const SOFT_EDGE = 110;

export const NEST_RADIUS = 80;
/** Standing inside this distance from the nest's centre during a break opens the shop. */
export const NEST_SHOP_RADIUS = 110;

export const ANT_RADIUS = 16;
export const DART_SPEED = 950;
export const DART_RANGE = 620;
/** Auto aim picks the nearest predator inside this distance. */
export const TARGET_RANGE = 600;
/** After a hit the ant flashes and cannot be hurt for this long. */
export const GRACE_MS = 650;
/** One predator bites at most once in this window. */
export const BITE_COOLDOWN_MS = 900;
/** Wasps and spiders glow orange this long before a shot, so a player can read it. */
export const SHOT_WINDUP_MS = 380;
export const STING_SPEED = 330;
export const WEB_SPEED = 280;
export const SHOT_LIFE_MS = 1700;

export const PICKUP_RADIUS = 30;
export const MAGNET_RADIUS = 120;
export const BEAD_SPEED = 560;

/** Seconds of "get ready" before round 1. */
export const INTRO_SECONDS = 2.5;
/** A new predator fades in at its hole for this long and cannot bite meanwhile. */
export const SPAWN_FADE_MS = 420;
/** Spawn holes closer than this to the ant are skipped. */
export const SPAWN_MIN_DIST = 420;
/** Holes farther than this are used only when no hole sits in the ring, so first contact comes in seconds. */
export const SPAWN_MAX_DIST = 1000;
/** Strength of the push that keeps a crowd from stacking into one blob. */
export const SEPARATION = 260;
/** The camera sits a little above the ant, so more of the Yard shows ahead of the thumb. */
export const CAMERA_LEAD_Y = 0.08;
