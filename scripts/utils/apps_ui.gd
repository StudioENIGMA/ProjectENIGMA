extends GridContainer

signal app_opened(app_id: GameData.App)

const APP_BUTTON_SCENE = preload("res://scenes/tools/AppButton.tscn")

#region CHILDREN NODES REFERENCES
@export var touch_sound_player:AudioStreamPlayer2D
#endregion

#region APP BUTTONS REFERENCES
func _ready() -> void:
	for child in get_children():
		if child is not Control:
			continue

		# We need to do it this way to avoid setting default apps as invisible
		var is_downloaded = GameData.downloaded_apps.has(child.app)
		if is_downloaded:
			child.visible = true

		child.gui_input.connect(_on_app_gui_input.bind(child))

func _on_app_gui_input(event: InputEvent, app_node: Node) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var app_id = _get_app_id(app_node)
		touch_sound_player.play_touch_sound()
		emit_signal("app_opened", app_id)

func _get_app_id(app_node: Node) -> GameData.App:
	return app_node.app
#endregion

#region INSTALLATION HELPERS
## Handles the app installation request
func on_app_installed(app:GameData.App) -> void:
	# Add the app to downloaded apps
	if not GameData.downloaded_apps.has(app):
		GameData.downloaded_apps.append(app)

	# Show the icon on the home screen
	var app_button = APP_BUTTON_SCENE.instantiate()
	app_button.app = app
	app_button.gui_input.connect(_on_app_gui_input.bind(app_button))
	add_child(app_button)

## Handles the app uninstalled event from the store app
func on_app_uninstalled(app:GameData.App) -> void:
	# Remove the app from downloaded apps
	if GameData.downloaded_apps.has(app):
		GameData.downloaded_apps.erase(app)

	# Remove the icon from the home screen
	for child in get_children():
		if child.app == app:
			child.visible = false
			break
#endregion INSTALLATION HELPERS
