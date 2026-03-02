extends Control

signal subscreen_open_requested(subscreen_name:String)

@export var passwords_manager_gui: Control
@export var update_os_gui: Control
@export var virus_scanner_gui: Control

func _ready() -> void:
	var day = GameData.current_day

	passwords_manager_gui.setup("Gerenciador de Senhas")
	update_os_gui.setup("Atualização de Software")
	virus_scanner_gui.setup("Verificar Presença de Vírus")

	passwords_manager_gui.settings_gui_pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.PASSWORDMANAGER])
	)
	virus_scanner_gui.settings_gui_pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.VIRUSSCANNER])
	)

	update_os_gui.settings_gui_pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.UPDATEOS])
	)

func _on_sub_app_pressed(app:GameData.App) -> void:
	emit_signal("subscreen_open_requested", app)
