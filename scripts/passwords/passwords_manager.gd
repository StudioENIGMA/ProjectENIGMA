extends Control

signal password_change_requested(app: GameData.App, data: Dictionary)

const STORED_PASSWORD_SCENE = preload("res://scenes/settings/password_instance.tscn")

#region CHILDREN NODES REFERENCES
@export var password_container: VBoxContainer
#endregion

func _ready() -> void:
	# Create one password instance for each app that requires a password
	for app in GameData.passwords.keys():
		var password_instance = STORED_PASSWORD_SCENE.instantiate()
		password_container.add_child(password_instance)
		password_instance.setup({"GatedApp": app})
		password_instance.subscreen_open_requested.connect(password_change_requested.emit)

func refresh_passwords_list() -> void:
	# Clear existing password instances
	for child in password_container.get_children():
		child.queue_free()

	# Recreate password instances for each app that requires a password
	for app in GameData.passwords.keys():
		var password_instance = STORED_PASSWORD_SCENE.instantiate()
		password_container.add_child(password_instance)
		password_instance.setup({"GatedApp": app})
		password_instance.subscreen_open_requested.connect(password_change_requested.emit)