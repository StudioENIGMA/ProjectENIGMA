extends Node2D
class_name both_shops

var matches = []
var apps
var is_fake : bool = false
var deleted : bool

@export var uninstall : Button
@export var exit_button : Button
@export var vbox_apps :VBoxContainer
@export var spawn_apps_instance : SpawnAppOnStore

func _ready() -> void:
	if !is_fake:
		uninstall.hide()
	apps = vbox_apps.get_children()

func _on_exit_shop_pressed() -> void:
	invisible()

func invisible() -> void:
	visible = not visible

func _on_uninstall_pressed() -> void:
	uninstall.text = "正在卸載..."
	deleted = true
	await get_tree().create_timer(3.0).timeout
	invisible()


func _on_draw() -> void:
	spawn_apps_instance.remove_apps_from_list()
	spawn_apps_instance.spawn_apps()
	pass # Replace with function body.
