extends Control

signal open_chat_requested(conversation_data:Dictionary)

const MY_MESSAGE = preload("res://scenes/apps/messages/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/apps/messages/others_message.tscn")

@export var contact_label:Label
@export var message_label:Label
@export var avatar_texture:TextureRect
@export var conversation_data:Dictionary
@export var open_chat_button:Button

func _ready() -> void:
	open_chat_button.pressed.connect(_on_button_pressed)

func setup(p_conversation_data:Dictionary):
	self.conversation_data = p_conversation_data

	contact_label.text = conversation_data["name"]
	message_label.text = conversation_data["messages"].back()["message"]
	avatar_texture.texture = load(conversation_data["photo"])

func _on_button_pressed() -> void:
	open_chat_requested.emit(conversation_data)
