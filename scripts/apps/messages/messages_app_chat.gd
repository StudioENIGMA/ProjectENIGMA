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

@export var messages_list:VBoxContainer
@export var answers_bar:HBoxContainer
@export var scroll_container:ScrollContainer

@export var avatar_rect: TextureRect
@export var name_label: Label
@export var verified_rect: TextureRect

var conversation_name:String = ""
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
	conversation_name = conversation_data["name"]
	set_header_panel(conversation_data["verified"])

	answers_bar.set_active_conversation(conversation_name)
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

	if messages_typing[conversation_name] == true:
		var message_typing_instance = OTHERS_MESSAGE.instantiate()
		messages_list.add_child(message_typing_instance)
		message_typing_instance.setup("", {}, 0, true)

	for option in conversation_data["options"]:
		answers_bar.create_answer_option(
			conversation_data["name"],
			option["message"],
			option["title"],
			option["reputation_points"],
			-2,
			option["answer_id"]
		)

	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
	scroll_container.call_deferred("scroll_to_bottom")

func on_create_message(
	npc_name:String,
	_message:String,
	_annex:Dictionary,
	_sender:GameData.Sender,
	_time:int
) -> void:
	messages_typing[npc_name] = true
	if npc_name != conversation_name:
		return

	var message_typing_instance = OTHERS_MESSAGE.instantiate()
	messages_list.add_child(message_typing_instance)
	message_typing_instance.setup("", {}, 0, true)

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

	if messages_typing[conversation_name]:
		# Free message typing instance
		var typing_instance = messages_list.get_child(messages_list.get_child_count() - 1)
		messages_list.remove_child(typing_instance)
		typing_instance.queue_free()
		messages_typing[npc_name] = false

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
	npc_name:String,
	message:String,
	title:String,
	reputation_points:int,
	time:int,
	answer_id:int
) -> void:
	answers_bar.create_answer_option(
		npc_name,
		message,
		title,
		reputation_points,
		time,
		answer_id
	)

func set_header_panel(is_verified: bool) -> void:
	var photo_path = str("res://assets/avatars/", conversation_name, ".png")
	avatar_rect.texture = load(photo_path)
	name_label.text = conversation_name
	verified_rect.visible = true if is_verified else false
