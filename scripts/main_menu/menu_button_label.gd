extends Label

## Feeds the label size to menu_button_text.gdshader so its diagonal stays lined
## up with the plate drawn behind the button.

func _ready() -> void:
	resized.connect(_update_shader_size)
	_update_shader_size()

func _update_shader_size() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("rect_size", size)
