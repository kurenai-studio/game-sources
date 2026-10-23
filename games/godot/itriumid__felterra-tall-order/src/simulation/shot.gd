class_name Shot
extends RefCounted
## A round in flight. Fast enough to cross a rat between one step and the next, so hits are
## found along the whole path it moved, not just where it ended up.

var position := Vector2.ZERO
var height := 0.0
var velocity := Vector2.ZERO
var vertical_speed := 0.0
var life := 0.0
var weapon: Weapon
var damage := 1.0
## Who fired it, so adrenaline knows whose health to give back.
var shooter: Cat
## A lobbed round falls under gravity, and one with a blast bursts where it hits or lands,
## striking everything that close instead of only what it hit.
var falls := false
var blast := 0.0
## What it can still go through, and glance off, and what it's hit already (it hits each once).
var pierce_left := 0
var ricochet_left := 0
var struck := {}
## Where it was at the start of the last step, for the tracer and the swept hit.
var previous := Vector2.ZERO
var previous_height := 0.0
var spent := false
