extends MarginContainer

@onready var label = $PanelContainer/Label
@onready var panel_container = $PanelContainer
var MAX_WIDTH = 650

func setup(message : String):
	panel_container.custom_minimum_size.x = 0
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	label.text = message
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if panel_container.size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = MAX_WIDTH
