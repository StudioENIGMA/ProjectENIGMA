extends PanelContainer

## Score bands, from the lowest score each one starts at: verdict text, score circle colour,
## verdict chip text colour and verdict chip fill
const VERDICTS = [
	[70, "Confiável", Color("224862"), Color("224862"), Color(0.30980393, 0.79607844, 0.68235296, 0.22)],
	[50, "Regular", Color("39909f"), Color("224862"), Color(0.22352941, 0.5647059, 0.62352943, 0.14)],
	[0, "Alto risco", Color("911a38"), Color("911a38"), Color(0.92156863, 0.039215688, 0.27058825, 0.12)],
]

@export var score_label: Label
@export var name_label: Label
@export var summary_label: Label
@export var logo_texture_rect: TextureRect
@export var verdict_label: Label

func setup(company_data: Dictionary) -> void:
	logo_texture_rect.texture = load(company_data['logo'])

	name_label.text = company_data['name']
	summary_label.text = company_data['summary']
	score_label.text = "%d" % company_data['score']

	var verdict: Array = VERDICTS.filter(func(band): return company_data['score'] >= band[0])[0]

	var score_style: StyleBoxFlat = score_label.get_theme_stylebox("normal").duplicate()
	score_style.bg_color = verdict[2]
	score_label.add_theme_stylebox_override("normal", score_style)

	verdict_label.text = verdict[1]
	verdict_label.add_theme_color_override("font_color", verdict[3])
	var verdict_style: StyleBoxFlat = verdict_label.get_theme_stylebox("normal").duplicate()
	verdict_style.bg_color = verdict[4]
	verdict_label.add_theme_stylebox_override("normal", verdict_style)
