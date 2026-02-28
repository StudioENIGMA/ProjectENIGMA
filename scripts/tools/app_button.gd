@tool

extends VBoxContainer

## Once app is changed we must call _update_ui to reflect the changes in the editor
@export var app: GameData.App:
	set(value):
		if app == value:
			return
		app = value
		_update_ui()

#region CHILDREN NODES REFERENCES
@export var app_icon: TextureRect
@export var app_name_label: Label
#endregion

func _ready() -> void:
	_update_ui()

## Updates the app button UI based on the current game data
func _update_ui() -> void:
	if app_icon == null or app_name_label == null:
		return

	var apps_data = get_most_recent_game_data()
	if apps_data == null:
		return

	if not apps_data.has(app):
		return

	var app_info: Dictionary = apps_data[app]
	app_icon.texture = load(app_info["icon_path"])
	app_name_label.text = app_info["name"]

## GameData is a singleton, we will use a exported version to get the most recent data
func get_most_recent_game_data() -> Variant:
	var file_path = "res://data/exported_game_data.json"

	if not FileAccess.file_exists(file_path):
		return null

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return null

	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return null

	var exported_apps_data = parsed.get("apps_data", {})
	if typeof(exported_apps_data) != TYPE_DICTIONARY:
		return null

	# Convert string keys back to enum ints
	var normalized_apps_data: Dictionary = {}
	for key in exported_apps_data.keys():
		normalized_apps_data[int(key)] = exported_apps_data[key]

	return normalized_apps_data
