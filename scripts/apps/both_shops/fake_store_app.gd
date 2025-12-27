extends "res://scripts/apps/both_shops/generic_store_app.gd"

signal app_uninstalled(app_name:String)

@export var uninstall_button: Button

func _ready():
	uninstall_button.pressed.connect(_on_uninstall_pressed)

func _on_uninstall_pressed() -> void:
	uninstall_button.text = "正在卸載..."
	await get_tree().create_timer(3.0).timeout
	emit_signal("app_uninstalled", "FakeStore")
