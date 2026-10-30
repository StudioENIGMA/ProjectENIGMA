extends VBoxContainer

@export var title_label : Label
@export var information_label : Label
## Lets the value be pointed at as a scam discrepancy
@export var section_target: DiscrepancyTarget

func setup(title : String, information : String) -> void:
	title_label.text = title
	information_label.text = information
