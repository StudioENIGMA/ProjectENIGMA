extends Control

signal subscreen_open_requested(subscreen_name:GameData.App)

signal app_installed(app_name:GameData.App)

@export var app_icon: TextureRect
@export var app_name_label: Label
@export var app_description_label: Label
@export var interact_button: Button

var current_app_name: GameData.App
var is_fake_app: bool = false
var is_app_operation_in_progress: bool = false

func setup(app_name: GameData.App, is_installed: bool, is_fake: bool) -> void:
	var app_info = GameData.apps_data[app_name]
	var has_available_updates: bool = GameData.apps_with_available_updates.has(app_name)

	current_app_name = app_name
	is_fake_app = is_fake

	app_icon.texture = load(app_info.icon_path)

	if is_fake:
		app_name_label.text = app_info.chinese_name
		app_description_label.text = app_info.description_in_chinese
		if has_available_updates:
			interact_button.text = GameData.apps_chinese_operations["update"]
		elif is_installed:
			interact_button.text = GameData.apps_chinese_operations["open"]
		else:
			interact_button.text = GameData.apps_chinese_operations["install"]
	else:
		app_name_label.text = app_info.name
		app_description_label.text = app_info.description
		if has_available_updates:
			interact_button.text = "Atualizar"
		elif is_installed:
			interact_button.text = "Abrir"
		else:
			interact_button.text = "Instalar"

func _on_app_button_pressed() -> void:
	if is_app_operation_in_progress:
		return

	is_app_operation_in_progress = true
	interact_button.disabled = true

	var is_installed: bool = GameData.downloaded_apps.has(current_app_name)
	var has_available_updates: bool = GameData.apps_with_available_updates.has(current_app_name)

	if has_available_updates and is_installed:
		await _update_app()
	elif is_installed:
		_open_app()
	else:
		await _install_app()

	_update_interact_button_text()
	interact_button.disabled = false
	is_app_operation_in_progress = false


func _install_app() -> void:
	interact_button.text = _get_operation_text("installing")

	await get_tree().create_timer(3.0).timeout

	if not GameData.downloaded_apps.has(current_app_name):
		GameData.downloaded_apps.append(current_app_name)

	GameData.apps_with_available_updates.erase(current_app_name)
	app_installed.emit(current_app_name)


func _update_app() -> void:
	interact_button.text = _get_operation_text("updating")

	await get_tree().create_timer(3.0).timeout

	GameData.apps_with_available_updates.erase(current_app_name)

	if not GameData.downloaded_apps.has(current_app_name):
		GameData.downloaded_apps.append(current_app_name)


func _open_app() -> void:
	subscreen_open_requested.emit(current_app_name)


func _update_interact_button_text() -> void:
	var is_installed: bool = GameData.downloaded_apps.has(current_app_name)
	var has_available_updates: bool = GameData.apps_with_available_updates.has(current_app_name)

	if has_available_updates and is_installed:
		interact_button.text = _get_operation_text("update")
	elif is_installed:
		interact_button.text = _get_operation_text("open")
	else:
		interact_button.text = _get_operation_text("install")


func _get_operation_text(operation: String) -> String:
	if is_fake_app:
		return GameData.apps_chinese_operations.get(operation, "")

	match operation:
		"install":
			return "Instalar"
		"installing":
			return "Instalando..."
		"update":
			return "Atualizar"
		"updating":
			return "Atualizando..."
		"open":
			return "Abrir"
		_:
			return ""