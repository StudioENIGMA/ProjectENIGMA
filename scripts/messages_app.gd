extends Node2D

const ANSWER_OPTION = preload("res://scenes/answer_option.tscn")
const MY_MESSAGE = preload("res://scenes/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/others_message.tscn")
@onready var home = $messages_home
@onready var chat = $messages_chat
@onready var chat_box = $messages_chat/ScrollContainer/VBoxContainer2
@onready var options_container = $messages_chat/HBoxContainer
@onready var scroll_container = $messages_chat/ScrollContainer
@onready var return_button : Button = $messages_chat/Button
@onready var current_contact : String

func _ready() -> void:
	OpenChatSingleton.open_chat.connect(_on_open_chat)
	EventBus.create_message.connect(_on_create_message)
	return_button.pressed.connect(_on_return_button_pressed)
	EventBus.create_answer.connect(_on_create_answer_option)

func _on_return_button_pressed():
	home.visible = true
	return_button.z_index = 0

func _on_open_chat(conversation_data : Dictionary):
	current_contact = conversation_data["name"]
	
	# update chat data
	for node in chat_box.get_children():
		node.queue_free()
	
	EventBus.clean_answers.emit()
	return_button.z_index = 2
		
	for message in conversation_data["messages"]:
		var message_instance = MY_MESSAGE.instantiate() if message.sender == EventBus.Sender.ME else OTHERS_MESSAGE.instantiate()

		chat_box.add_child(message_instance)
		message_instance.setup(message.message)
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value		
	
	for option in conversation_data["options"]:
		EventBus.answer_option.emit(conversation_data.name, option.message, option.title, option.reputation_points, -2, option.answer_id)
	
	# Hide Home
	home.visible = false

func _on_create_answer_option(name : String, title : String, message : String, answer_id : int) -> void:
	if name != current_contact:
		return
	
	var answer_option_instance = ANSWER_OPTION.instantiate()
	options_container.add_child(answer_option_instance)
	answer_option_instance.setup(name, title, message, answer_id)

func _on_create_message(name : String, message : String, sender : EventBus.Sender, time : String):
	if name != current_contact:
		return
	
	var message_instance = MY_MESSAGE.instantiate() if sender == EventBus.Sender.ME else OTHERS_MESSAGE.instantiate()
	chat_box.add_child(message_instance)
	message_instance.setup(message)
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

	
