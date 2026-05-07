extends Control

@export var default_panel: Panel
@export var panel_label: Label
@export var photo_rect: TextureRect

var bg_color: Color
var label_color: Color

func setup(photo_path: String, npc_name: String) -> void:
	var photo_resource = load(photo_path)

	if (photo_resource):
		photo_rect.visible = true
		default_panel.visible = false
		photo_rect.texture = photo_resource
	else:
		photo_rect.visible = false
		default_panel.visible = true

		panel_label.text = npc_name[0].to_upper()
		set_color_values(npc_name)
		update_ui()

func set_color_values(npc_name: String) -> void:
	var name_seed := hash(npc_name)
	var rng := RandomNumberGenerator.new()
	rng.seed = name_seed
	var random_int = rng.randi_range(0, 2)

	match random_int:
		0:
			bg_color = Color("#000924")
			label_color = Color("#003079")
		1:
			bg_color = Color("#540a27")
			label_color = Color("961c4cff")
		2:
			bg_color = Color("#11463b")
			label_color = Color("#2d937e")

	var new_stylebox = default_panel.get_theme_stylebox("panel").duplicate()
	new_stylebox.bg_color = bg_color

	default_panel.add_theme_stylebox_override("panel", new_stylebox)
	panel_label.add_theme_color_override("font_color", label_color)
	
func update_ui() -> void:
	var font_size
	if self.custom_minimum_size.x >= 64:
		font_size = 45
	else:
		font_size = 30
	panel_label.add_theme_font_size_override("font_size", font_size)
