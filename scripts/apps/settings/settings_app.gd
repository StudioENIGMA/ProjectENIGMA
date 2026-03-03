extends Control

signal subscreen_open_requested(subscreen_name: String)

@export var passwords_manager_button: TextureButton
@export var update_os_button: TextureButton
@export var virus_scanner_button: TextureButton

func _ready() -> void:
	var day = GameData.current_day

	passwords_manager_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.PASSWORDMANAGER])
	)
	virus_scanner_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.VIRUSSCANNER])
	)

	# Hide certain settings based on the current day
	if day < 2:
		update_os_button.disabled = true
		virus_scanner_button.disabled = true
	else:
		update_os_button.disabled = false
		virus_scanner_button.disabled = false

func _on_sub_app_pressed(app: GameData.App) -> void:
	emit_signal("subscreen_open_requested", app)
