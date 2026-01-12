extends VBoxContainer

@export var title_label : Label
@export var information_label : Label

func setup(title : String, information : String) -> void:
	title_label.text = title
	information_label.text = information
