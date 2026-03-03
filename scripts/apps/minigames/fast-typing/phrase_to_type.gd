extends PanelContainer

@export var phrase_label: RichTextLabel
@export var index_label: Label

func setup(phrase, phrase_index, is_completed, is_current):
	phrase_label.text = " ".join(phrase)
	index_label.text = str(phrase_index + 1) + "."
	if is_completed:
		phrase_label.add_theme_color_override("default_color", Color.LIME_GREEN)
		index_label.add_theme_color_override("font_color", Color.LIME_GREEN)
	if is_current:
		phrase_label.add_theme_color_override("default_color", Color.YELLOW)
		index_label.add_theme_color_override("font_color", Color.YELLOW)
