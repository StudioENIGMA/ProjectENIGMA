extends Control

signal subscreen_open_requested(subscreen_name: String)
signal request_password_notification(
	app: GameData.App,
	content: String,
	title: String,
	time: int
)

@export var passwords_manager_button: Button
@export var update_os_button: Button
@export var virus_scanner_button: Button

func _ready() -> void:
	#var day = GameData.current_day

	passwords_manager_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.PASSWORDMANAGER])
	)
	virus_scanner_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.VIRUSSCANNER])
	)

	update_os_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.UPDATEOS])
	)

	# Hide certain settings based on the current day
	#if day < 2:
	#	update_os_button.disabled = true
	#	virus_scanner_button.disabled = true
	#else:
	#	update_os_button.disabled = false
	#	virus_scanner_button.disabled = false

func _on_sub_app_pressed(app: GameData.App) -> void:
	emit_signal("subscreen_open_requested", app)

## Warns the player that passwords expired and must be changed, if any installed app is
## still waiting for today's change. Called at the start of every day
func notify_outdated_passwords() -> void:
	if GameData.get_outdated_password_apps().is_empty():
		return

	request_password_notification.emit(
		GameData.App.SETTINGS,
		"Por segurança, troque hoje as senhas dos seus aplicativos no Gerenciador de Senhas.",
		"Senhas expiradas",
		GameData.hours_minutes
	)
