extends AnimatedSprite2D
class_name AnimationController

const DIR_DOWN = "_down"
const DIR_UP = "_up"
const DIR_LEFT = "_left"
const DIR_RIGHT = "_right"

var _direction: Vector2 = Vector2.ZERO

func set_direction(dir: Vector2) -> void:
  if dir != _direction:
    if dir != Vector2.ZERO:
      _direction = dir
  play_directional(animation.split("_")[0])


func play_directional(anim_name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false) -> void:
    if _direction.y > 0:
      anim_name += DIR_DOWN
    elif _direction.y < 0:
      anim_name += DIR_UP
    elif _direction.x > 0:
      anim_name += DIR_RIGHT
    elif _direction.x < 0:
      anim_name += DIR_LEFT
    else:
      anim_name += DIR_DOWN
    
    play(anim_name, custom_speed, from_end)