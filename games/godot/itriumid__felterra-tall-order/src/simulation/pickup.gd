class_name Pickup
extends RefCounted
## Something to pick up: salvage from what he breaks, bolts and steel and tools, thrown out where
## it broke. It flies, lands, bounces and slides like anything else, and he takes it by walking
## over it.

const REACH := 0.4

var body := Body.new()
var amount := 1


func _init() -> void:
	body.radius = 0.06
	body.tall = 0.05
	body.restitution = 0.4
	body.kind = "salvage"
