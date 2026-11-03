class_name MergeParticles
extends CPUParticles2D

func _ready() -> void:
	# Clean up from memory once the burst completes
	finished.connect(queue_free)
	# Trigger the burst
	emitting = true

func setup_tier(tier: int) -> void:
	initial_velocity_min = 60.0 + (tier * 15.0)
	initial_velocity_max = 120.0 + (tier * 25.0)
	# Optional: scale particle count with tier
	amount = 10 + (tier * 2)
	lifetime = lifetime + (tier * 0.2)
	scale_amount_min = scale_amount_min + (tier * 0.2)
	scale_amount_max = scale_amount_max + (tier * 0.2)
