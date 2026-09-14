extends HBoxContainer

const POSITIVE_COLOR = Color(0.30980393, 0.79607844, 0.68235296)
const NEGATIVE_COLOR = Color(0.92156863, 0.039215688, 0.27058825)

@export var description_label: Label
@export var rp_label: Label

func setup(description: String, rep_points: int) -> void:
	description_label.text = description
	var math_signal = "+" if rep_points >= 0 else ""
	rp_label.text = math_signal + str(rep_points)
	rp_label.add_theme_color_override("font_color", POSITIVE_COLOR if rep_points >= 0 else NEGATIVE_COLOR)
