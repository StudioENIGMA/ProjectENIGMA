extends PanelContainer

@onready var contact_label : Label = $HBoxContainer/VBoxContainer/name
@onready var message_label : Label = $HBoxContainer/VBoxContainer/message
@onready var avatar_texture : TextureRect = $HBoxContainer/TextureRect
@onready var conversation_data : Dictionary

func setup(conversation_data : Dictionary):
	self.conversation_data = conversation_data

	contact_label.text = conversation_data["name"]
	message_label.text = conversation_data["messages"].back()["message"]
	avatar_texture.texture = load(conversation_data["photo"])

func _on_button_pressed() -> void:
	OpenChatSingleton.open_chat.emit(conversation_data)
