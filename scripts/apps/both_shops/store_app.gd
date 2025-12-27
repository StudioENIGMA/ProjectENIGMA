extends "res://scripts/apps/both_shops/generic_store_app.gd"

func setup(apps_data) -> void:
	var available_apps = apps_data.available_apps
	var downloaded_apps = apps_data.downloaded_apps

	# Clear existing app items
	for child in available_apps_container.get_children():
		available_apps_container.remove_child(child)
		child.queue_free()

	# Populate available apps
	for app in available_apps:
		var app_item = APPLICATION_INSTANCE_SCENE.instantiate()
		app_item.setup(app, downloaded_apps.has(app), false)
		available_apps_container.add_child(app_item)
