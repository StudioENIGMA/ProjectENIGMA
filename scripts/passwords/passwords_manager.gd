extends Control

signal password_change_requested(app: GameData.App, data: Dictionary)

const STORED_PASSWORD_SCENE = preload("res://scenes/settings/password_instance.tscn")

#region CHILDREN NODES REFERENCES
@export var password_container: VBoxContainer
@export var empty_state: CenterContainer
#endregion

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	refresh_passwords_list()

## Rebuilds one password instance per app that requires a password, then updates the
## empty state
func refresh_passwords_list() -> void:
	# Clear existing password instances
	for child in password_container.get_children():
		password_container.remove_child(child)
		child.queue_free()

	# Recreate password instances for each app that requires a password
	for app in GameData.passwords.keys():
		var password_instance = STORED_PASSWORD_SCENE.instantiate()
		password_container.add_child(password_instance)
		password_instance.setup({"GatedApp": app})
		password_instance.subscreen_open_requested.connect(password_change_requested.emit)

	empty_state.visible = GameData.passwords.is_empty()

## Reopening the screen re-reads GameData, so the list never shows a stale password
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		refresh_passwords_list()

