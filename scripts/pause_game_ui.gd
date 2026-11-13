extends Control

@export var resume_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var menu_button: Button
@export var confirmation_panel: PanelContainer
@export var difficulty_changer: OptionButton

const SETTINGS_SCENE_PATH = "res://scenes/game_settings.tscn"

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	self.visible = false

func show_pause_menu() -> void:
	get_tree().paused = true
	self.visible = true

## Opens the settings over the pause menu, the game stays paused behind them. Their back button
## closes them, see settings_back_button.gd
func _on_settings_button_pressed() -> void:
	add_child(load(SETTINGS_SCENE_PATH).instantiate())

func _on_menu_button_pressed() -> void:
	confirmation_panel.setup("menu")
	confirmation_panel.show()

func _on_quit_button_pressed() -> void:
	confirmation_panel.setup("quit")
	confirmation_panel.show()
