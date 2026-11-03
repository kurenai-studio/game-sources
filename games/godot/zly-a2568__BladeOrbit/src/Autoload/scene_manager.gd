extends CanvasLayer

var game_level=1
var camera_inst:PhantomCamera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func reset():
	game_level=1

func change_scene(path:String)->void:
	var tree=get_tree()
	var target:=load(path) as PackedScene
	if target:
		var t = create_tween()
		t.tween_property(tree,"paused",true,0.0)
		t.tween_property($Mask,"modulate:a",1.0,0.5)
		t.tween_interval(0.2)
		t.tween_callback(tree.change_scene_to_packed.bind(target))
		t.tween_interval(0.2)
		t.tween_property($Mask,"modulate:a",0.0,0.5)
		t.tween_property(tree,"paused",false,0.0)
		
	else:
		push_error("{0}:no such a Scene".format([path]))
		tree.quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
