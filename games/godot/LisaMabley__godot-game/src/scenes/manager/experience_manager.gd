extends Node

signal experience_updated(current_experience: float, target_experience: float)
signal level_up(new_level: int)

const TARGET_EXPERIENCE_GROWTH = 5

var current_experience = 0
var current_level = 1
var target_experience = 5


func _ready():
	GameEvents.experience_gem_collected.connect(_on_experience_gem_collected)


func _increment_experience(number: float):
	var experience_earned = current_experience + number
	current_experience = min(experience_earned, target_experience)
	experience_updated.emit(current_experience, target_experience)
	if current_experience == target_experience:
		current_level += 1
		current_experience = experience_earned - target_experience
		target_experience += TARGET_EXPERIENCE_GROWTH
		experience_updated.emit(current_experience, target_experience)
		level_up.emit(current_level)


func _on_experience_gem_collected(number: float):
	_increment_experience(number)
