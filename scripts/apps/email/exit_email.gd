extends Button

var new_game_scene : Resource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	new_game_scene = preload("res://scenes/game_screen.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _on_pressed() -> void:
	change_scene()

func change_scene() -> void:
	new_game_scene.instantiate()
	get_tree().change_scene_to_packed(new_game_scene)
