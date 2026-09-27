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

const MY_MESSAGE = preload("res://scenes/apps/messages/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/apps/messages/others_message.tscn")
const TIME_INDICATOR = preload("res://scenes/apps/messages/time_indicator.tscn")

@export var messages_list:VBoxContainer
@export var answers_bar:HBoxContainer
@export var scroll_container:ScrollContainer

@export var profile_picture: Control
@export var name_label: Label
@export var verified_rect: TextureRect

var conversation_dict: Dictionary
## The conversation_id of the open chat, empty while no chat is open
var conversation_id:String = ""
## conversation_id -> whether the NPC of that conversation is typing
var messages_typing: Dictionary = {}

func _ready() -> void:
	answers_bar.message_answered.connect(message_answered.emit) # Propagate signal to base app
	answers_bar.request_message_creation_on_answer.connect(
		request_message_creation_on_answer.emit # Propagate signal to base app
	)
	answers_bar.request_message_creation_on_answer.connect(
		on_send_message # Handle message creation in current chat
	)
	answers_bar.storage_answer.connect(
		storage_answer.emit # Propagate signal to base app
	)
	answers_bar.delete_answers.connect(delete_answers.emit) # Propagate signal to base app

func setup(conversation_data:Dictionary) -> void:
	if conversation_data["notification_count"] > 0:
		conversation_data["notification_count"] = 0

	conversation_dict = conversation_data
	conversation_id = conversation_data["id"]
	set_header_panel(
		conversation_data["name"], conversation_data["photo"], conversation_data["verified"]
	)

	answers_bar.set_active_conversation(conversation_id)
	answers_bar.clear_ui()

	for child_node in messages_list.get_children():
		messages_list.remove_child(child_node)
		child_node.queue_free()

	var current_date_dict = conversation_data["messages"][0].date_dict

	var time_indicator_instance = TIME_INDICATOR.instantiate()
	messages_list.add_child(time_indicator_instance)
	time_indicator_instance.setup(current_date_dict)

	for message in conversation_data["messages"]:
		if message.date_dict != current_date_dict:
			current_date_dict = message.date_dict
			var time_instance = TIME_INDICATOR.instantiate()
			messages_list.add_child(time_instance)
			time_instance.setup(current_date_dict)

		var message_instance:HBoxContainer;
		if message.sender == GameData.Sender.PLAYER:
			message_instance = MY_MESSAGE.instantiate()
		else:
			message_instance = OTHERS_MESSAGE.instantiate()

		messages_list.add_child(message_instance)
		message_instance.setup(message.message, message.get("annex", {}), message.time)
		message_instance.apk_installation_requested.connect(
			apk_installation_requested.emit # Propagate signal to base app
		)

	if messages_typing.get(conversation_id, false) == true:
		var message_typing_instance = OTHERS_MESSAGE.instantiate()
		messages_list.add_child(message_typing_instance)
		message_typing_instance.setup("", {}, 0, true)

	var contact := _contact_of(conversation_data)
	for option in conversation_data["options"]:
		answers_bar.create_answer_option(
			contact,
			option["message"],
			option["title"],
			option["reputation_points"],
			-2,
			option["answer_id"]
		)

	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
	scroll_container.call_deferred("scroll_to_bottom")

func on_create_message(contact:Dictionary) -> void:
	messages_typing[contact["id"]] = true
	if contact["id"] != conversation_id:
		return

	var message_typing_instance = OTHERS_MESSAGE.instantiate()
	messages_list.add_child(message_typing_instance)
	message_typing_instance.setup("", {}, 0, true)

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

	if messages_typing.get(conversation_id, false):
		# Free message typing instance
		var typing_instance = messages_list.get_child(messages_list.get_child_count() - 1)
		messages_list.remove_child(typing_instance)
		typing_instance.queue_free()
		messages_typing[conversation_id] = false

	# Add the new message to the messages list
	var message_instance:HBoxContainer;
	if sender == GameData.Sender.PLAYER:
		message_instance = MY_MESSAGE.instantiate()
	else:
		message_instance = OTHERS_MESSAGE.instantiate()

	messages_list.add_child(message_instance)
	message_instance.setup(message, annex, time)
	message_instance.apk_installation_requested.connect(
		apk_installation_requested.emit # Propagate signal to base app
	)

	# Scroll to the bottom to show the new message if it's from the player or if already in the bottom
	if sender == GameData.Sender.PLAYER or scroll_container.call_deferred("check_scroll_to_bottom"):
		scroll_container.call_deferred("scroll_to_bottom")

func on_request_answer_option(
	contact:Dictionary,
	message:String,
	title:String,
	reputation_points:int,
	time:int,
	answer_id:int
) -> void:
	answers_bar.create_answer_option(
		contact,
		message,
		title,
		reputation_points,
		time,
		answer_id
	)

func set_header_panel(npc_name: String, photo: String, is_verified: bool) -> void:
	profile_picture.setup(photo, npc_name)
	name_label.text = npc_name
	verified_rect.visible = true if is_verified else false

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
