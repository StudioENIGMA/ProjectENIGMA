extends Control
## Conversations of the days gone by, grouped by day with the latest one first
##
## Every day starts with an empty Messages list and the conversations of the day that ended
## come here (see messages_app_home._archive_conversations()). They are read-only: opening one
## shows it the way it was when its day ended, so a scam can still be compared to the real
## contact it was imitating.

signal subscreen_open_requested(subscreen_name: GameData.App, conversation_data: Dictionary)

const CONVERSATION_ROW_SCENE = preload("res://scenes/apps/messages/conversation_row.tscn")
const SEMI_FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const REGULAR_FONT = preload("res://assets/fonts/IBMPlexSans-Regular.ttf")
const MEDIUM_FONT = preload("res://assets/fonts/IBMPlexSans-Medium.ttf")
## Same green as the time of an unread conversation
const DAY_COLOR := Color(0.05490196, 0.41960785, 0.34509805)
const MUTED_COLOR := Color(0.43137255, 0.44313726, 0.5019608)
const HEADER_FONT_SIZE := 11

@export var days_list: VBoxContainer
@export var empty_state: CenterContainer

## Rebuilds the list every time it opens, the history only grows from one day to the next
func setup(_data = null) -> void:
	for child in days_list.get_children():
		days_list.remove_child(child)
		child.queue_free()

	var days: Array = GameData.saved_messages_history
	empty_state.visible = days.is_empty()

	for day_index in range(days.size() - 1, -1, -1):
		var day_entry: Dictionary = days[day_index]
		var day := int(day_entry.get("day", 0))
		var conversations: Array = day_entry.get("conversations", [])

		days_list.add_child(_day_header(day_entry, conversations.size()))
		for conversation in conversations:
			var conversation_row = CONVERSATION_ROW_SCENE.instantiate()
			days_list.add_child(conversation_row)
			conversation_row.setup_archived(conversation)
			conversation_row.open_chat_requested.connect(_on_open_chat.bind(day))

## Opens a conversation of a day gone by, read-only
##
## conversation_data: The conversation as it was archived
## day: The day it belongs to
func _on_open_chat(conversation_data: Dictionary, day: int) -> void:
	var archived_conversation: Dictionary = conversation_data.duplicate(true)
	archived_conversation["archived_day"] = day
	subscreen_open_requested.emit(GameData.App.MESSAGESCHAT, archived_conversation)

## Header of the conversations of a day: "DIA 3", its date and how many there are
func _day_header(day_entry: Dictionary, conversation_count: int) -> MarginContainer:
	var day := int(day_entry.get("day", 0))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 4)

	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 8)
	margin.add_child(line)

	line.add_child(_header_label("TUTORIAL" if day == 0 else "DIA %d" % day, SEMI_FONT, DAY_COLOR))
	var date_text := _date_text(day_entry.get("date_dict", {}))
	var date_label := _header_label(date_text, REGULAR_FONT, MUTED_COLOR)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_label.clip_text = true
	date_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(date_label)
	line.add_child(_header_label(
		"%d %s" % [conversation_count, "conversa" if conversation_count == 1 else "conversas"],
		MEDIUM_FONT, MUTED_COLOR
	))
	return margin

func _header_label(text: String, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label

## "Quarta, 22 de outubro", empty for saves that kept no date
func _date_text(date_dict: Dictionary) -> String:
	if date_dict.is_empty():
		return ""
	return "%s, %d de %s" % [
		GameData.weekday_name(date_dict),
		int(date_dict.get("day", 1)),
		GameData.month_name(date_dict),
	]
