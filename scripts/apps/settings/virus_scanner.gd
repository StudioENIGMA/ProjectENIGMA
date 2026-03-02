extends VBoxContainer

signal minigame_request()
signal app_uninstalled(app_name: GameData.App)

#region CHILDREN NODES REFERENCES
@export var virus_result: VBoxContainer
@export var apps_result: VBoxContainer
@export var remove_virus_button: Button
@export var remove_apps_button: Button
@export var scan_button: Button
@export var scan_timer: Timer
@export var virus_result_label: Label
@export var apps_result_label: Label
#endregion

func _ready() -> void:
	virus_result.visible = false
	apps_result.visible = false
	scan_button.pressed.connect(_on_scan_button_pressed)
	scan_timer.timeout.connect(_on_scan_timer_timeout)

	remove_apps_button.pressed.connect(_on_remove_apps_button_pressed)
	remove_virus_button.pressed.connect(_on_remove_virus_button_pressed)

func _on_scan_button_pressed() -> void:
	scan_button.disabled = true
	scan_button.text = "Varredura em progresso"
	scan_timer.start()

func _on_scan_timer_timeout() -> void:
	virus_result.visible = true
	apps_result.visible = true
	scan_button.disabled = false
	scan_button.text = "Iniciar Varredura"

	var has_viruses = GameData.number_of_viruses > 0
	virus_result_label.text = "Vírus detectados: " + str(GameData.number_of_viruses)

	if has_viruses:
		remove_virus_button.disabled = false
		virus_result_label.add_theme_color_override("font_color", Color.RED)
	else:
		remove_virus_button.disabled = true
		virus_result_label.add_theme_color_override("font_color", Color.GREEN)

	var installed_unsafe_apps = GameData.unsafe_apps.filter(func(app):
		return GameData.downloaded_apps.has(app)
	)
	var has_unsafe_apps = installed_unsafe_apps.size() > 0
	apps_result_label.text = "Aplicativos inseguros detectados: " + str(installed_unsafe_apps.size())

	if has_unsafe_apps:
		remove_apps_button.disabled = false
		apps_result_label.add_theme_color_override("font_color", Color.RED)
	else:
		remove_apps_button.disabled = true
		apps_result_label.add_theme_color_override("font_color", Color.GREEN)

func _on_remove_virus_button_pressed() -> void:
	GameData.number_of_viruses = 0
	virus_result_label.text = "Vírus detectados: 0"
	virus_result_label.add_theme_color_override("font_color", Color.GREEN)
	remove_virus_button.disabled = true

	minigame_request.emit()

func _on_remove_apps_button_pressed() -> void:
	for unsafe_app in GameData.unsafe_apps:
		if GameData.downloaded_apps.has(unsafe_app):
			GameData.downloaded_apps.erase(unsafe_app)
			app_uninstalled.emit(unsafe_app)
	apps_result_label.text = "Aplicativos inseguros detectados: 0"
	apps_result_label.add_theme_color_override("font_color", Color.GREEN)
	remove_apps_button.disabled = true

	minigame_request.emit()
