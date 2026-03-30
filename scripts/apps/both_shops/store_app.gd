extends "res://scripts/apps/both_shops/generic_store_app.gd"

signal subscreen_open_requested(subscreen_name:GameData.App)

signal app_installed(app_name:GameData.App)

func _ready() -> void:
	refresh_store()

func setup() -> void:
	# Refresh apps in store
	refresh_store()

func refresh_store() -> void:
	var available_apps = GameData.apps_in_store
	var downloaded_apps = GameData.downloaded_apps

	# Clear existing app items
	for child in available_apps_container.get_children():
		available_apps_container.remove_child(child)
		child.queue_free()

	# Populate available apps
	for app in available_apps:
		var app_item = APPLICATION_INSTANCE_SCENE.instantiate()
		app_item.setup(app, downloaded_apps.has(app), false)
		app_item.subscreen_open_requested.connect(_on_subscreen_open_requested)
		app_item.app_installed.connect(on_app_installed)
		available_apps_container.add_child(app_item)

func _on_subscreen_open_requested(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name) # Propagate signal

func on_app_installed(app:GameData.App) -> void:
	app_installed.emit(app) # Propagate signal to update UI
