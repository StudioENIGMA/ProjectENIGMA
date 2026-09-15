extends Control

signal subscreen_open_requested(subscreen_name:GameData.App)

signal app_installed(app_name:GameData.App)

const OPERATION_DURATION: float = 3.0

@export var app_icon: TextureRect
@export var app_name_label: Label
@export var app_description_label: Label
@export var interact_button: Button
@export var install_progress: ProgressBar

#region Button styles
@export var primary_style: StyleBox
@export var primary_active_style: StyleBox
@export var primary_font_color: Color = Color(1, 1, 1, 1)
@export var secondary_style: StyleBox
@export var secondary_active_style: StyleBox
@export var secondary_font_color: Color = Color(0.05490196, 0.41960785, 0.34509805, 1)
#endregion Button styles

var current_app_name: GameData.App
var is_fake_app: bool = false
var is_app_operation_in_progress: bool = false

## Fills the row with an app's icon, name and description, and puts its button
## in the state matching what the player can currently do with that app.
func setup(app_name: GameData.App, is_fake: bool) -> void:
	var app_info = GameData.apps_data[app_name]

	current_app_name = app_name
	is_fake_app = is_fake

	app_icon.texture = load(app_info.icon_path)
	install_progress.visible = false

	if is_fake:
		app_name_label.text = app_info.chinese_name
		app_description_label.text = app_info.description_in_chinese
	else:
		app_name_label.text = app_info.name
		app_description_label.text = app_info.description

	_refresh_interact_button()


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

	interact_button.disabled = false
	is_app_operation_in_progress = false
	_refresh_interact_button()


func _install_app() -> void:
	interact_button.text = _get_operation_text("installing")

	await _run_progress()

	if not GameData.downloaded_apps.has(current_app_name):
		GameData.downloaded_apps.append(current_app_name)

	GameData.apps_with_available_updates.erase(current_app_name)
	app_installed.emit(current_app_name)


func _update_app() -> void:
	interact_button.text = _get_operation_text("updating")

	await _run_progress()

	GameData.apps_with_available_updates.erase(current_app_name)

	if not GameData.downloaded_apps.has(current_app_name):
		GameData.downloaded_apps.append(current_app_name)


func _open_app() -> void:
	subscreen_open_requested.emit(current_app_name)


## Runs the progress bar from empty to full, taking as long as the install or
## update it stands for.
func _run_progress() -> void:
	install_progress.value = 0.0
	install_progress.visible = true

	var tween: Tween = create_tween()
	tween.tween_property(install_progress, "value", 100.0, OPERATION_DURATION)
	await tween.finished

	install_progress.visible = false


## Puts the button's label and styling in sync with the app's current state:
## installing and updating change the game, so they get the loud primary look,
## while opening an app the player already has stays quiet.
func _refresh_interact_button() -> void:
	var is_installed: bool = GameData.downloaded_apps.has(current_app_name)
	var has_available_updates: bool = GameData.apps_with_available_updates.has(current_app_name)

	if has_available_updates and is_installed:
		interact_button.text = _get_operation_text("update")
		_apply_button_style(true)
	elif is_installed:
		interact_button.text = _get_operation_text("open")
		_apply_button_style(false)
	else:
		interact_button.text = _get_operation_text("install")
		_apply_button_style(true)


func _apply_button_style(is_primary: bool) -> void:
	var normal_style: StyleBox = primary_style if is_primary else secondary_style
	var active_style: StyleBox = primary_active_style if is_primary else secondary_active_style
	var font_color: Color = primary_font_color if is_primary else secondary_font_color

	interact_button.add_theme_stylebox_override("normal", normal_style)
	interact_button.add_theme_stylebox_override("hover", active_style)
	interact_button.add_theme_stylebox_override("pressed", active_style)
	interact_button.add_theme_color_override("font_color", font_color)
	interact_button.add_theme_color_override("font_hover_color", font_color)
	interact_button.add_theme_color_override("font_pressed_color", font_color)


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
