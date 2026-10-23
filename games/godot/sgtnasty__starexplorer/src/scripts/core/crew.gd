# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Crew
extends RefCounted
## Six officers with a skill level each, plus the number of hands aboard.
## Hands are the ship's hit points in a boarding action.

const ROLES: Array[String] = ["captain", "pilot", "science", "engineer", "doctor", "weapons"]
const MAX_SKILL := 5
const HIRE_COST := 80

const ROLE_NAMES := {
	"captain": "Captain",
	"pilot": "Pilot",
	"science": "Science Officer",
	"engineer": "Engineer",
	"doctor": "Doctor",
	"weapons": "Weapons Officer",
}

const ROLE_DESC := {
	"captain": "Better prices, boarding, intimidation",
	"pilot": "Evasion and escape chance",
	"science": "Detects rarer deposits; sneaking",
	"engineer": "Mining yield; field repairs",
	"doctor": "Saves casualties after battle",
	"weapons": "Hit chance, damage, boarding",
}

var skills := {"captain": 1, "pilot": 1, "science": 1, "engineer": 1, "doctor": 1, "weapons": 1}
var hands := 8
var max_hands := 12


func skill(role: String) -> int:
	return skills[role]


func training_cost(role: String) -> int:
	return 150 * (skill(role) + 1)


func can_train(role: String) -> bool:
	return skill(role) < MAX_SKILL


func train(role: String) -> void:
	skills[role] = mini(skill(role) + 1, MAX_SKILL)


func to_dict() -> Dictionary:
	return {"skills": skills.duplicate(), "hands": hands, "max_hands": max_hands}


func from_dict(d: Dictionary) -> void:
	var saved: Dictionary = d.get("skills", {})
	for r in ROLES:
		skills[r] = clampi(int(saved.get(r, 1)), 0, MAX_SKILL)
	max_hands = int(d.get("max_hands", 12))
	hands = clampi(int(d.get("hands", 8)), 0, max_hands)
