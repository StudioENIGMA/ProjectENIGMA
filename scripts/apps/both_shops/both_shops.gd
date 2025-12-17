class_name BothShops

extends Node2D

@export var is_fake:bool = false
@export var deleted:bool = false
@export var spawn_apps_instance:SpawnAppOnStore

var matches = []

@onready var uninstall:Button = $Panel/Uninstall
@onready var exit_button:Button = $Exit_shop
@onready var apps = $Panel/VBoxContainer.get_children()


func _ready() -> void:
	if !is_fake:
		uninstall.hide()

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
