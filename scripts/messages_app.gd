extends Node2D

const MY_MESSAGE = preload("res://scenes/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/others_message.tscn")

@onready var home = $messages_home
@onready var chat = $messages_chat
@onready var chat_box = $messages_chat/ScrollContainer/VBoxContainer2
@onready var return_button : Button = $messages_chat/Button
@onready var current_contact : String

func _ready() -> void:
	OpenChatSingleton.open_chat.connect(_on_open_chat)
	EventBus.send_message.connect(_on_send_message)
	return_button.pressed.connect(_on_return_button_pressed)

func _on_return_button_pressed():
	home.visible = true

func _on_open_chat(conversation_data : Dictionary):
	current_contact = conversation_data["name"]
	
	# update chat data
	for node in chat_box.get_children():
		node.queue_free()
		
	for message in conversation_data["messages"]:
		var message_instance
		
		if message.sender == "me":
			message_instance = MY_MESSAGE.instantiate()
		else:
			message_instance = OTHERS_MESSAGE.instantiate()
			
		chat_box.add_child(message_instance)
		message_instance.setup(message.message)
	
	# Hide Home
	home.visible = false

func _on_send_message(name : String, message : String, time : int):
	if name != current_contact:
		return
	
	var message_instance = OTHERS_MESSAGE.instantiate()
	chat_box.add_child(message_instance)
	message_instance.setup(message)
	

	
