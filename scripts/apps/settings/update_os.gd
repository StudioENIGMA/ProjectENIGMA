extends Control

#region CHILDREN NODES REFERENCES
@export var update_button: Button
@export var animator: AnimationPlayer
#endregion CHILDREN NODES REFERENCES

func _ready() -> void:
	update_button.pressed.connect(_on_update_button_pressed)

func _on_update_button_pressed() -> void:
	GameData.updated_os_today = true
	update_button.text = "Atualizando Sistema"
	update_button.disabled = true
	animator.play("update_os")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	# Use to detect when update is over (at the end of the animation)
	update_button.text = "Sistema atualizado hoje"
