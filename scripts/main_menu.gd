extends Control

@export var new_game_button: Button
@export var confirmation_panel: PanelContainer

func _ready() -> void:
	confirmation_panel.start_new_game.connect(new_game_button.change_scene)
	new_game_button.show_confirmation_panel.connect(confirmation_panel.show)
