extends VBoxContainer

@export var not_found_label: Label

func setup(code: String) -> void:
	var label_text = "O código digitado \"%s\" não foi encontrado." % code;
	not_found_label.text = label_text;
