extends Control

signal open_chat_requested(conversation_data:Dictionary)

const ANNEX_PREVIEW = "Anexo"
const OWN_MESSAGE_PREFIX = "Você: "
const MAX_NOTIFICATION_COUNT = 99
## Tag of a conversation of a day gone by whose scam ended a certain way, see setup_archived()
const OUTCOME_TAGS = {
	"fallen": {
		"text": "Caiu no golpe",
		"color": Color(0.80784315, 0.03137255, 0.23529412),
		"background": Color(0.92156863, 0.039215688, 0.27058825, 0.12),
	},
	"reported": {
		"text": "Denunciado",
		"color": Color(0.039215688, 0.23137255, 0.19215687),
		"background": Color(0.26666668, 0.8117647, 0.69803923, 0.28),
	},
}
const OUTCOME_FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")

@export var contact_label:Label
@export var message_label:Label
@export var time_label:Label
@export var profile_picture:Control
@export var verified_badge:Panel
@export var conversation_data:Dictionary
@export var open_chat_button:Button
@export var notification_bubble:PanelContainer
@export var notification_label:Label
@export var read_preview_settings:LabelSettings
@export var unread_preview_settings:LabelSettings
@export var read_time_settings:LabelSettings
@export var unread_time_settings:LabelSettings

## A conversation of a day gone by, read-only and never unread
var _is_archived := false
var _outcome_tag:PanelContainer

func _ready() -> void:
	self.visibility_changed.connect(update_notification_bubble)
	open_chat_button.pressed.connect(_on_button_pressed)

## Fills the row with the data of a conversation
##
## p_conversation_data: The conversation the row stands for
func setup(p_conversation_data:Dictionary) -> void:
	self.conversation_data = p_conversation_data

	var last_message:Dictionary = conversation_data["messages"].back()

	contact_label.text = conversation_data["name"]
	message_label.text = _preview_of(last_message)
	time_label.text = _time_of(last_message)
	verified_badge.visible = conversation_data.get("verified", false)
	profile_picture.setup(conversation_data["photo"], conversation_data["name"])
	update_notification_bubble()

## Fills the row with a conversation of a day gone by: nothing unread, the time its last message
## came in, and a tag when it was a scam the player fell for or reported
##
## p_conversation_data: The conversation as it was archived, see messages_app_home
func setup_archived(p_conversation_data:Dictionary) -> void:
	_is_archived = true
	setup(p_conversation_data)

	var last_message:Dictionary = conversation_data["messages"].back()
	var relative_time:int = int(last_message.get("time", 0)) - GameData.starting_hours_minutes
	time_label.text = GameData.hours_minutes_as_string(relative_time)
	_show_outcome(str(conversation_data.get("outcome", "")))

## Shows the unread counter and emphasises the row while messages are unread
func update_notification_bubble() -> void:
	if conversation_data.is_empty():
		return
	if _is_archived:
		notification_bubble.visible = false
		message_label.label_settings = read_preview_settings
		time_label.label_settings = read_time_settings
		return

	var notification_count:int = int(conversation_data["notification_count"])
	var is_unread:bool = notification_count > 0

	notification_bubble.visible = is_unread
	if is_unread:
		notification_label.text = (
			str(MAX_NOTIFICATION_COUNT, "+") if notification_count > MAX_NOTIFICATION_COUNT
			else str(notification_count)
		)

	message_label.label_settings = unread_preview_settings if is_unread else read_preview_settings
	time_label.label_settings = unread_time_settings if is_unread else read_time_settings

## Builds the single line preview of the last message of the conversation
##
## message: The last message of the conversation
func _preview_of(message:Dictionary) -> String:
	var preview:String = str(message.get("message", "")).replace("\n", " ").strip_edges()

	if preview.is_empty() and not (message.get("annex", {}) as Dictionary).is_empty():
		preview = ANNEX_PREVIEW

	if int(message.get("sender", GameData.Sender.NPC)) == GameData.Sender.PLAYER:
		preview = str(OWN_MESSAGE_PREFIX, preview)

	return preview

## Formats the moment of the last message: the clock for today, the date otherwise
##
## message: The last message of the conversation
func _time_of(message:Dictionary) -> String:
	var date_dict:Dictionary = message.get("date_dict", {})

	if not date_dict.is_empty():
		var today:Dictionary = GameData.get_current_date_dict()
		if int(date_dict["day"]) != int(today["day"]):
			return "%02d/%02d" % [int(date_dict["day"]), int(date_dict["month"])]

	var relative_time:int = int(message.get("time", 0)) - GameData.starting_hours_minutes
	return GameData.hours_minutes_as_string(relative_time)

## Puts the tag of how the scam of the conversation ended where the unread counter would be
##
## outcome: "fallen", "reported", or anything else for no tag
func _show_outcome(outcome:String) -> void:
	if _outcome_tag:
		_outcome_tag.queue_free()
		_outcome_tag = null
	if not OUTCOME_TAGS.has(outcome):
		return

	var tag:Dictionary = OUTCOME_TAGS[outcome]
	var style := StyleBoxFlat.new()
	style.bg_color = tag["background"]
	style.set_corner_radius_all(9)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 3

	var label := Label.new()
	label.text = tag["text"]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", OUTCOME_FONT)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", tag["color"])

	_outcome_tag = PanelContainer.new()
	_outcome_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outcome_tag.size_flags_horizontal = Control.SIZE_SHRINK_END
	_outcome_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_outcome_tag.add_theme_stylebox_override("panel", style)
	_outcome_tag.add_child(label)
	notification_bubble.get_parent().add_child(_outcome_tag)

func _on_button_pressed() -> void:
	open_chat_requested.emit(conversation_data)
