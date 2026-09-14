extends HBoxContainer

const POSITIVE_TEXT_COLOR = Color(0.13333334, 0.28235295, 0.38431373)
const POSITIVE_PILL_COLOR = Color(0.30980393, 0.79607844, 0.68235296, 0.18)
const NEGATIVE_TEXT_COLOR = Color(0.5686275, 0.101960786, 0.21960784)
const NEGATIVE_PILL_COLOR = Color(0.92156863, 0.039215688, 0.27058825, 0.14)

@export var description_label: Label
@export var rp_pill: PanelContainer
@export var rp_label: Label

func setup(description: String, rep_points: int) -> void:
	description_label.text = description
	var math_signal = "+" if rep_points >= 0 else ""
	rp_label.text = math_signal + str(rep_points)

	var text_color: Color
	var pill_color: Color
	if rep_points >= 0:
		text_color = POSITIVE_TEXT_COLOR
		pill_color = POSITIVE_PILL_COLOR
	else:
		text_color = NEGATIVE_TEXT_COLOR
		pill_color = NEGATIVE_PILL_COLOR

	rp_label.add_theme_color_override("font_color", text_color)

	var pill_style = StyleBoxFlat.new()
	pill_style.bg_color = pill_color
	pill_style.content_margin_left = 10.0
	pill_style.content_margin_right = 10.0
	pill_style.content_margin_top = 3.0
	pill_style.content_margin_bottom = 3.0
	pill_style.corner_radius_top_left = 100
	pill_style.corner_radius_top_right = 100
	pill_style.corner_radius_bottom_right = 100
	pill_style.corner_radius_bottom_left = 100
	rp_pill.add_theme_stylebox_override("panel", pill_style)
