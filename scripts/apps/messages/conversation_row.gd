extends Control

signal open_chat_requested(conversation_data:Dictionary)

const ANNEX_PREVIEW = "Anexo"
const OWN_MESSAGE_PREFIX = "Você: "
const MAX_NOTIFICATION_COUNT = 99

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

## Shows the unread counter and emphasises the row while messages are unread
func update_notification_bubble() -> void:
	if conversation_data.is_empty():
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

func _on_button_pressed() -> void:
	open_chat_requested.emit(conversation_data)
