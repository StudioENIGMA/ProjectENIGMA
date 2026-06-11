extends HBoxContainer

@export var description_label: Label
@export var rp_label: Label

func setup(description: String, rep_points: int) -> void:
	description_label.text = description
	var math_signal = "+" if rep_points >= 0 else ""
	rp_label.text = math_signal + str(rep_points)

	var description_label_settings = description_label.label_settings.duplicate(true)
	var rp_label_settings = rp_label.label_settings.duplicate(true)
	var fcolor: Color
	if rep_points >= 0:
		fcolor = Color("#44cfb2")
	else:
		fcolor = Color("#ff0447")
	description_label_settings.font_color = fcolor
	rp_label_settings.font_color = fcolor

	description_label.label_settings = description_label_settings
	rp_label.label_settings = rp_label_settings
