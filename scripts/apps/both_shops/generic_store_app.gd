class_name StoreApp

extends Control

const APPLICATION_INSTANCE_SCENE = preload("res://scenes/apps/store-shop/application_instance.tscn")

@export var available_apps_container: VBoxContainer
@export var empty_state: Control


## Shows the placeholder text whenever the catalogue has nothing to list.
func update_empty_state() -> void:
	if empty_state == null:
		return

	empty_state.visible = available_apps_container.get_child_count() == 0
