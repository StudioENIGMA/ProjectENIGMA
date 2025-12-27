extends Control

@export var app_icon: TextureRect
@export var app_name_label: Label
@export var app_description_label: Label
@export var interact_button: Button

func setup(app_name: GameData.App, is_installed: bool, is_fake: bool) -> void:
	var app_info = GameData.apps_data[app_name]

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
