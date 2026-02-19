extends Control

signal settings_gui_pressed()

@export var button: TextureButton

func setup(default_texture: Resource, hover_texture: Resource) -> void:
	button.texture_normal = default_texture
	button.texture_hover = hover_texture
	button.texture_pressed = hover_texture
	
func change_gui_lock_texture(lock_texture: Resource):
	button.texture_disabled = lock_texture
	button.disabled = true

func _on_texture_button_pressed() -> void:
	settings_gui_pressed.emit()
