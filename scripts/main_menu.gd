extends Control

@export var new_game_button: Button
@export var confirmation_panel: PanelContainer
@export var post_game_panel: PanelContainer

func _ready() -> void:
	confirmation_panel.start_new_game.connect(new_game_button.change_scene)
	new_game_button.show_confirmation_panel.connect(confirmation_panel.show)

	if GameData.current_day == 7:
		GameData.reset_to_defaults()
		post_game_panel.show()
