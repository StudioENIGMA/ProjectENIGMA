extends PanelContainer

@export var contact_label:Label
@export var message_label:Label
@export var avatar_texture:TextureRect
@export var conversation_data:Dictionary

func setup(p_conversation_data:Dictionary):
	self.conversation_data = p_conversation_data

	contact_label.text = conversation_data["name"]
	message_label.text = conversation_data["messages"].back()["message"]
	avatar_texture.texture = load(conversation_data["photo"])

func _on_button_pressed() -> void:
	OpenChatSingleton.open_chat.emit(conversation_data)
