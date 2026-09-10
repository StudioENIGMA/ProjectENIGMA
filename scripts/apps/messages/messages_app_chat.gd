extends Control

## Request the UI main node to send a notification
##
## app: The application the notification is related to (Messages)
## content: The content of the notification
## title: The title of the notification
## time: Duration the notification should be displayed
signal request_message_notification(
	app:GameData.App,
  content:String,
  title:String,
  time:int
)

signal message_answered(answer_id:int)

signal request_message_creation_on_answer(
	name:String,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
)

signal storage_answer(
	name:String,
	message:String,
	title:String,
	reputation_points:int,
	answer_id:int
)

signal apk_installation_requested(app: GameData.App)

signal delete_answers(npc_name:String)

const MY_MESSAGE = preload("res://scenes/apps/messages/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/apps/messages/others_message.tscn")
const TIME_INDICATOR = preload("res://scenes/apps/messages/time_indicator.tscn")
const UNREAD_INDICATOR = preload("res://scenes/apps/messages/unread_indicator.tscn")

## Extra breathing room inserted whenever the speaker changes
const GROUP_GAP = 10
## Sender value that stands for "no message rendered yet"
const NO_SENDER = -1
## Message index that stands for "the whole conversation was already read"
const NO_UNREAD = -1

@export var messages_list:VBoxContainer
@export var answers_panel:PanelContainer
@export var scroll_container:ScrollContainer

@export var profile_picture: Control
@export var name_label: Label
@export var verified_badge: Panel

var conversation_dict: Dictionary
var conversation_name:String = ""
var messages_typing: Dictionary = {}

var _last_sender:int = NO_SENDER

func _ready() -> void:
	answers_panel.message_answered.connect(message_answered.emit) # Propagate signal to base app
	answers_panel.request_message_creation_on_answer.connect(
		request_message_creation_on_answer.emit # Propagate signal to base app
	)
	answers_panel.request_message_creation_on_answer.connect(
		on_send_message # Handle message creation in current chat
	)
	answers_panel.storage_answer.connect(
		storage_answer.emit # Propagate signal to base app
	)
	answers_panel.delete_answers.connect(delete_answers.emit) # Propagate signal to base app
	answers_panel.options_changed.connect(_on_answer_options_changed)

func setup(conversation_data:Dictionary) -> void:
	# Read before clearing the counter, it is what tells the unread messages apart
	var first_unread:int = _first_unread_index(conversation_data)
	conversation_data["notification_count"] = 0

	conversation_dict = conversation_data
	conversation_name = conversation_data["name"]
	set_header_panel(conversation_data["verified"])

	answers_panel.set_active_conversation(conversation_name)
	answers_panel.clear_ui()

	for child_node in messages_list.get_children():
		messages_list.remove_child(child_node)
		child_node.queue_free()

	_last_sender = NO_SENDER

	var current_date_dict = conversation_data["messages"][0].date_dict
	_add_time_indicator(current_date_dict)

	for message_index in conversation_data["messages"].size():
		var message = conversation_data["messages"][message_index]
		if message.date_dict != current_date_dict:
			current_date_dict = message.date_dict
			_add_time_indicator(current_date_dict)

		if message_index == first_unread:
			_add_unread_indicator()

		_add_message(
			int(message.sender),
			message.message,
			message.get("annex", {}),
			message.time
		)

	if messages_typing.get(conversation_name, false) == true:
		_add_typing_indicator()

	for option in conversation_data["options"]:
		answers_panel.create_answer_option(
			conversation_data["name"],
			option["message"],
			option["title"],
			option["reputation_points"],
			-2,
			option["answer_id"]
		)

	scroll_container.jump_to_bottom()

func on_create_message(
	npc_name:String,
) -> void:
	messages_typing[npc_name] = true
	if npc_name != conversation_name:
		return

	_add_typing_indicator()

func on_send_message(
	npc_name:String,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
) -> void:
	# Check if the message belongs to the currently open conversation
	if npc_name != conversation_name:
		# Notify new message received
		if sender == GameData.Sender.NPC:
			request_message_notification.emit(
				GameData.App.MESSAGESHOME,
				message,
				npc_name,
				time
			)
		messages_typing[npc_name] = false
		return

	conversation_dict["notification_count"] = 0

	# Remember whether the reader was already following the conversation
	var was_at_bottom:bool = scroll_container.is_at_bottom()

	if messages_typing.get(conversation_name, false):
		# Free message typing instance
		var typing_instance = messages_list.get_child(messages_list.get_child_count() - 1)
		messages_list.remove_child(typing_instance)
		typing_instance.queue_free()
		messages_typing[npc_name] = false

	_add_message(int(sender), message, annex, time)

	# Scroll to the bottom to show the new message if it's from the player or if already in the bottom
	if sender == GameData.Sender.PLAYER or was_at_bottom:
		scroll_container.call_deferred("scroll_to_bottom")

func on_request_answer_option(
	npc_name:String,
	message:String,
	title:String,
	reputation_points:int,
	time:int,
	answer_id:int
) -> void:
	answers_panel.create_answer_option(
		npc_name,
		message,
		title,
		reputation_points,
		time,
		answer_id
	)

func set_header_panel(is_verified: bool) -> void:
	var photo_path = str("res://assets/avatars/", conversation_name, ".png")
	profile_picture.setup(photo_path, conversation_name)
	name_label.text = conversation_name
	verified_badge.visible = is_verified

## Renders a message bubble at the end of the conversation
##
## sender: Who wrote the message, a GameData.Sender value
## message: The text of the message
## annex: The attachment carried by the message, empty when there is none
## time: The moment the message was sent, in minutes
func _add_message(sender:int, message:String, annex:Dictionary, time:int) -> void:
	if _last_sender != NO_SENDER and sender != _last_sender:
		_add_group_gap()

	var message_instance:HBoxContainer
	if sender == GameData.Sender.PLAYER:
		message_instance = MY_MESSAGE.instantiate()
	else:
		message_instance = OTHERS_MESSAGE.instantiate()

	messages_list.add_child(message_instance)
	message_instance.setup(message, annex, time)
	message_instance.apk_installation_requested.connect(
		apk_installation_requested.emit # Propagate signal to base app
	)

	_last_sender = sender

## Renders the bubble with the animation shown while an NPC types
func _add_typing_indicator() -> void:
	var typing_instance = OTHERS_MESSAGE.instantiate()
	messages_list.add_child(typing_instance)
	typing_instance.setup("", {}, 0, true)

## Renders the pill that opens the messages of a new day
##
## date_dict: The date the following messages belong to
func _add_time_indicator(date_dict:Dictionary) -> void:
	var time_indicator_instance = TIME_INDICATOR.instantiate()
	messages_list.add_child(time_indicator_instance)
	time_indicator_instance.setup(date_dict)

	# The pill already separates the messages, so the next one needs no extra gap
	_last_sender = NO_SENDER

## Renders the marker that opens the messages that arrived while the chat was closed
func _add_unread_indicator() -> void:
	messages_list.add_child(UNREAD_INDICATOR.instantiate())

	# The marker already separates the messages, so the next one needs no extra gap
	_last_sender = NO_SENDER

## Position of the first message the reader has not seen yet
##
## Only the messages that arrived while the conversation was closed are counted,
## so a message received with the chat already open never gets a marker. Returns
## NO_UNREAD when there is nothing to mark, including a conversation being opened
## for the first time, where every message would be below the marker.
##
## conversation_data: The conversation about to be rendered, counter still untouched
func _first_unread_index(conversation_data:Dictionary) -> int:
	var unread_count:int = int(conversation_data["notification_count"])
	if unread_count <= 0:
		return NO_UNREAD

	var first_unread:int = conversation_data["messages"].size() - unread_count
	if first_unread <= 0:
		return NO_UNREAD

	return first_unread

## Separates two consecutive blocks of messages of different senders
func _add_group_gap() -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = GROUP_GAP
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	messages_list.add_child(gap)

## Keeps the last message in sight when the answers bar changes height
##
## The bar is always on screen, but the reply cards and the reply picked take
## room from the conversation, so a reader that was following it keeps seeing
## the last message.
##
## _has_options: Whether the bar holds at least one answer option
func _on_answer_options_changed(_has_options:bool) -> void:
	if not scroll_container.is_at_bottom():
		return

	scroll_container.jump_to_bottom()
