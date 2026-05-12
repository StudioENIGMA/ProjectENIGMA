extends Control

const MENU_SCENE_PATH = "res://scenes/main_menu.tscn"

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "credit_roll":
		get_tree().change_scene_to_file(MENU_SCENE_PATH)
