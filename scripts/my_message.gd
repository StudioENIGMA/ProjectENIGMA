extends MarginContainer

@onready var label = $PanelContainer/Label

func setup(message : String):
	label.text = message
