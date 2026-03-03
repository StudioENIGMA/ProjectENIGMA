extends PanelContainer

@export var phrase_label: RichTextLabel
@export var index_label: Label

func setup(phrase, phrase_index):
  phrase_label.text = " ".join(phrase)
  index_label.text = str(phrase_index + 1) + "."
