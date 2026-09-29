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

## Asks the top bar to show the contact of the conversation being opened
##
## npc_name: The name of the contact
## photo: The path of the contact's avatar
## is_verified: Whether the contact carries the verified badge
signal header_changed(npc_name: String, photo: String, is_verified: bool)

## contact: The conversation the message belongs to ("id", "name", "photo", "verified")
signal request_message_creation_on_answer(
	contact:Dictionary,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
)

signal storage_answer(
	conversation_id:String,
	message:String,
	title:String,
	reputation_points:int,
	answer_id:int
)

signal apk_installation_requested(app: GameData.App)

signal delete_answers(conversation_id:String)

## Emitted when the player, inspecting, points at a message or annex as a scam discrepancy
##
## section: "source", "section" ("message" or "annex"), "conversation" and "excerpt"
signal discrepancy_picked(section: Dictionary)

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

var conversation_dict: Dictionary
## The conversation_id of the open chat, empty while no chat is open
var conversation_id:String = ""
## conversation_id -> whether the NPC of that conversation is typing
var messages_typing: Dictionary = {}

var _last_sender:int = NO_SENDER
## Keeps the NPC messages that can be pointed at as a discrepancy in step
var _inspector := DiscrepancyInspector.new()

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
	_inspector.picked.connect(discrepancy_picked.emit) # Propagate signal to base app

func setup(conversation_data:Dictionary) -> void:
	# Read before clearing the counter, it is what tells the unread messages apart
	var first_unread:int = _first_unread_index(conversation_data)
	conversation_data["notification_count"] = 0

	conversation_dict = conversation_data
	conversation_id = conversation_data["id"]
	header_changed.emit(
		conversation_data["name"], conversation_data["photo"], conversation_data["verified"]
	)

	answers_panel.set_active_conversation(conversation_id)
	answers_panel.clear_ui()

	for child_node in messages_list.get_children():
		messages_list.remove_child(child_node)
		child_node.queue_free()
	_inspector.forget_all()

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

	if messages_typing.get(conversation_id, false) == true:
		_add_typing_indicator()

	var contact := _contact_of(conversation_data)
	for option in conversation_data["options"]:
		answers_panel.create_answer_option(
			contact,
			option["message"],
			option["title"],
			option["reputation_points"],
			-2,
			option["answer_id"]
		)

	scroll_container.jump_to_bottom()

func on_create_message(contact:Dictionary) -> void:
	messages_typing[contact["id"]] = true
	if contact["id"] != conversation_id:
		return

	# Remember whether the reader was already following the conversation
	var was_at_bottom:bool = scroll_container.is_at_bottom()

	_add_typing_indicator()

	# The indicator takes room at the end, so a reader that was following the
	# conversation keeps seeing it, and still counts as being at the bottom when
	# the message it announces arrives
	if was_at_bottom:
		scroll_container.scroll_to_bottom()

func on_send_message(
	contact:Dictionary,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
) -> void:
	# Check if the message belongs to the currently open conversation
	if contact["id"] != conversation_id:
		# Notify new message received
		if sender == GameData.Sender.NPC:
			request_message_notification.emit(
				GameData.App.MESSAGESHOME,
				message,
				contact["name"],
				time
			)
		messages_typing[contact["id"]] = false
		return

	conversation_dict["notification_count"] = 0

	# Remember whether the reader was already following the conversation
	var was_at_bottom:bool = scroll_container.is_at_bottom()

	if messages_typing.get(conversation_id, false):
		# Free message typing instance
		var typing_instance = messages_list.get_child(messages_list.get_child_count() - 1)
		messages_list.remove_child(typing_instance)
		typing_instance.queue_free()
		messages_typing[conversation_id] = false

	_add_message(int(sender), message, annex, time)

	# Scroll to the bottom to show the new message if it's from the player or if already in the bottom
	if sender == GameData.Sender.PLAYER or was_at_bottom:
		scroll_container.scroll_to_bottom()

func on_request_answer_option(
	contact:Dictionary,
	message:String,
	title:String,
	reputation_points:int,
	time:int,
	answer_id:int
) -> void:
	answers_panel.create_answer_option(
		contact,
		message,
		title,
		reputation_points,
		time,
		answer_id
	)

## Arms every NPC message and annex so the player can point at the one giving the scam away
##
## The answers bar is put away meanwhile, so no reply is sent by accident
func set_inspection_mode(is_on: bool) -> void:
	var was_at_bottom: bool = scroll_container.is_at_bottom()
	_inspector.set_armed(is_on)
	answers_panel.visible = not is_on
	if was_at_bottom:
		scroll_container.jump_to_bottom()

## Sections that can be pointed at, lit while the rest of the phone is dimmed
func get_discrepancy_targets() -> Array[DiscrepancyTarget]:
	return _inspector.get_targets()

## Unmarks the message picked, the others stay armed
func clear_discrepancy_selection() -> void:
	_inspector.clear_selection()

## The contact a stored conversation stands for, in the shape the story directors send it
##
## conversation_data: A conversation of messages_app_home
func _contact_of(conversation_data:Dictionary) -> Dictionary:
	return {
		"id": conversation_data["id"],
		"name": conversation_data["name"],
		"photo": conversation_data["photo"],
		"verified": conversation_data["verified"],
	}

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
	if sender == GameData.Sender.NPC:
		_add_discrepancy_targets(message_instance, message, annex, time)

	_last_sender = sender

## Lets the player point at an NPC message, and at its annex if it carries one
func _add_discrepancy_targets(
	message_instance:HBoxContainer,
	message:String,
	annex:Dictionary,
	time:int
) -> void:
	message_instance.message_target.section = {
		"source": "messages",
		"section": "message",
		"conversation": conversation_id,
		"excerpt": message,
		"time": GameData.hours_minutes_as_string(time - GameData.starting_hours_minutes),
	}
	_inspector.add(message_instance.message_target)

	if annex.is_empty():
		return
	message_instance.annex_target.section = {
		"source": "messages",
		"section": "annex",
		"conversation": conversation_id,
		"excerpt": str(annex.get("caption", "")),
	}
	_inspector.add(message_instance.annex_target)

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
