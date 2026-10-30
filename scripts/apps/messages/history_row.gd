extends Control
## Row on top of the Messages list that opens the conversations of the days gone by

signal open_requested()

@export var open_button: Button
@export var summary_label: Label

func _ready() -> void:
	open_button.pressed.connect(open_requested.emit)

## Sums the history up under its title
##
## days: The days of GameData.saved_messages_history
func setup(days: Array) -> void:
	var conversation_count := 0
	for day in days:
		conversation_count += day.get("conversations", []).size()

	summary_label.text = "%d %s · %d %s" % [
		days.size(), "dia" if days.size() == 1 else "dias",
		conversation_count, "conversa" if conversation_count == 1 else "conversas",
	]
