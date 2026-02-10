extends PanelContainer

@export var score_label: Label
@export var name_label: Label
@export var summary_label: Label
@export var logo_texture_rect: TextureRect

func setup(company_data: Dictionary) -> void:
	logo_texture_rect.texture = load(company_data['logo'])

	name_label.text = company_data['name']
	summary_label.text = "Resumo: %s" % company_data['sumarry']
	score_label.text = str(company_data['score'])

	var current_style: StyleBoxFlat = score_label.get_theme_stylebox("normal").duplicate()
	if company_data['score'] >= 50:
		current_style.bg_color = Color("#196153")
	else:
		current_style.bg_color = Color("#660f31")

	score_label.add_theme_stylebox_override("normal", current_style)
