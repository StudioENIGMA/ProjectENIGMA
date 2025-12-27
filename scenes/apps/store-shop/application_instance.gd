extends Control

signal subscreen_open_requested(subscreen_name:String)

@export var app_icon: TextureRect
@export var app_name_label: Label
@export var app_description_label: Label
@export var interact_button: Button

var current_app_name: GameData.App
var is_fake_app: bool = false

func setup(app_name: GameData.App, is_installed: bool, is_fake: bool) -> void:
	var app_info = GameData.apps_data[app_name]

	current_app_name = app_name
	is_fake_app = is_fake

	app_icon.texture = load(app_info.icon_path)

	if is_fake:
		app_name_label.text = app_info.chinese_name
		app_description_label.text = app_info.description_in_chinese
		if is_installed:
			interact_button.text = GameData.apps_chinese_operations["open"]
		else:
			interact_button.text = GameData.apps_chinese_operations["install"]
	else:
		app_name_label.text = app_info.name
		app_description_label.text = app_info.description
		if is_installed:
			interact_button.text = "Abrir"
		else:
			interact_button.text = "Instalar"

func _on_app_button_pressed() -> void:
	var is_installed: bool = GameData.downloaded_apps.has(current_app_name)
	if is_installed:
		subscreen_open_requested.emit(current_app_name)
	else:
		if is_fake_app:
			interact_button.text = GameData.apps_chinese_operations["installing"]
		else:
			interact_button.text = "Instalando..."
		await get_tree().create_timer(3.0).timeout
		GameData.downloaded_apps.append(current_app_name)
		if is_fake_app:
			interact_button.text = GameData.apps_chinese_operations["open"]
		else:
			interact_button.text = "Abrir"
