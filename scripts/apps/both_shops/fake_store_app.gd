extends "res://scripts/apps/both_shops/generic_store_app.gd"

signal app_uninstalled(app_name:String)

@export var uninstall_button: Button

func _ready() -> void:
	uninstall_button.pressed.connect(_on_uninstall_pressed)

func setup(apps_data) -> void:
	# Get available and downloaded apps from GameData
	var available_apps = apps_data.available_apps
	var downloaded_apps = apps_data.downloaded_apps

	# Clear existing app items
	for child in available_apps_container.get_children():
		available_apps_container.remove_child(child)
		child.queue_free()

	# Populate available apps
	for app in available_apps:
		var app_item = APPLICATION_INSTANCE_SCENE.instantiate()
		app_item.setup(app, downloaded_apps.has(app), true)
		available_apps_container.add_child(app_item)

func _on_uninstall_pressed() -> void:
	uninstall_button.text = "正在卸載..."
	await get_tree().create_timer(3.0).timeout
	emit_signal("app_uninstalled", "FakeStore")
