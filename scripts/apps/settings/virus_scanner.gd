extends Control

signal minigame_request()
signal app_uninstalled(app_name: GameData.App)

#region CHILDREN NODES REFERENCES
@export var virus_panel: Panel
@export var apps_panel: Panel
@export var hack_panel: Panel
@export var virus_result: VBoxContainer
@export var apps_result: VBoxContainer
@export var hack_result: VBoxContainer
@export var remove_virus_button: Button
@export var remove_apps_button: Button
@export var remove_hack_button: Button
@export var scan_button: Button
@export var virus_result_label: Label
@export var apps_result_label: Label
@export var hack_result_label: Label
@export var scanner_animation: Control
@export var scanner_video_stream: VideoStreamPlayer
@export var scanner_audio_stream: AudioStreamPlayer
#endregion

var red_style: StyleBoxFlat
var green_style: StyleBoxFlat

func _ready() -> void:
	virus_panel.visible = false
	apps_panel.visible = false
	hack_panel.visible = false
	red_style = virus_panel.get_theme_stylebox("panel").duplicate()
	green_style = apps_panel.get_theme_stylebox("panel").duplicate()
	scan_button.pressed.connect(_on_scan_button_pressed)
	scanner_video_stream.finished.connect(_on_video_stream_finished)

	remove_apps_button.pressed.connect(_on_remove_apps_button_pressed)
	remove_virus_button.pressed.connect(_on_remove_virus_button_pressed)
	remove_hack_button.pressed.connect(_on_remove_hack_button_pressed)

func _on_scan_button_pressed() -> void:
	scan_button.disabled = true
	scanner_animation.visible = true

	var has_viruses = GameData.number_of_viruses > 0
	var video_stream
	if has_viruses or GameData.is_hacked:
		video_stream = load("res://assets/videos/scanner-virus.ogv")
	else:
		video_stream = load("res://assets/videos/scanner-no-virus.ogv")

	scanner_video_stream.stream = video_stream
	scanner_audio_stream.play()
	scanner_video_stream.play()

func _on_video_stream_finished() -> void:
	scanner_audio_stream.stop()
	scanner_animation.visible = false
	await get_tree().process_frame # Ensure UI updates before showing results
	virus_panel.visible = true
	apps_panel.visible = true
	hack_panel.visible = true
	scan_button.disabled = false
	scan_button.text = "INICIAR VARREDURA"

	var has_viruses = GameData.number_of_viruses > 0
	virus_result_label.text = "Vírus detectados: " + str(GameData.number_of_viruses)
	remove_virus_button.text = "Remover vírus"

	if has_viruses:
		remove_virus_button.disabled = false
		virus_result_label.add_theme_color_override("font_color", Color.RED)
		virus_panel.add_theme_stylebox_override("panel", red_style)
	else:
		remove_virus_button.disabled = true
		virus_result_label.add_theme_color_override("font_color", Color.GREEN)
		virus_panel.add_theme_stylebox_override("panel", green_style)


	var installed_unsafe_apps = GameData.unsafe_apps.filter(func(app):
		return GameData.downloaded_apps.has(app)
	)
	var has_unsafe_apps = installed_unsafe_apps.size() > 0
	apps_result_label.text = "Aplicativos inseguros detectados: " + str(installed_unsafe_apps.size())
	remove_apps_button.text = "Desinstalar aplicativos"

	if has_unsafe_apps:
		remove_apps_button.disabled = false
		apps_result_label.add_theme_color_override("font_color", Color.RED)
		apps_panel.add_theme_stylebox_override("panel", red_style)
	else:
		remove_apps_button.disabled = true
		apps_result_label.add_theme_color_override("font_color", Color.GREEN)
		apps_panel.add_theme_stylebox_override("panel", green_style)

	
	var has_hack = GameData.is_hacked

	if has_hack:
		hack_result.visible = true
		hack_result_label.text = "Sistema comprometido!"
		hack_result_label.add_theme_color_override("font_color", Color.RED)
		hack_panel.add_theme_stylebox_override("panel", red_style)
		remove_hack_button.disabled = false

		# Disable other buttons, hack must be solved first
		remove_apps_button.disabled = true
		remove_apps_button.text = "Resolva ameaça primeiro"
		remove_virus_button.disabled = true
		remove_virus_button.text = "Resolva ameaça primeiro"
	else:
		remove_hack_button.disabled = true
		hack_result_label.text = "Nenhuma ameaça detectada"
		hack_result_label.add_theme_color_override("font_color", Color.GREEN)
		hack_panel.add_theme_stylebox_override("panel", green_style)

func _on_remove_virus_button_pressed() -> void:
	GameData.number_of_viruses = 0
	minigame_request.emit()

func _on_remove_apps_button_pressed() -> void:
	for unsafe_app in GameData.unsafe_apps:
		if GameData.downloaded_apps.has(unsafe_app):
			app_uninstalled.emit(unsafe_app)
	minigame_request.emit()

func _on_remove_hack_button_pressed() -> void:
	minigame_request.emit()
