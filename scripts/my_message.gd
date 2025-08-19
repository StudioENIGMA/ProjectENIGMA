extends MarginContainer

@onready var label = $PanelContainer/Label
@onready var panel_container = $PanelContainer
var MAX_WIDTH = 650

func setup(message : String):
	# 1. Reset properties to measure the "natural" width of the new text
	panel_container.custom_minimum_size.x = 0
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	label.text = message
	
	# 2. Wait for the next frame so the container resizes
	await get_tree().process_frame
	
	# 3. Now check the new size and apply constraints if needed
	if panel_container.size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel_container.custom_minimum_size.x = MAX_WIDTH
