extends PanelContainer

@onready var contact_label : Label = $HBoxContainer/VBoxContainer/name
@onready var message_label : Label = $HBoxContainer/VBoxContainer/message
@onready var avatar_texture : TextureRect = $HBoxContainer/TextureRect

func setup(contact_name : String, last_message : String, avatar_picture : String):
	contact_label.text = contact_name
	message_label.text = last_message
	avatar_texture.texture = load(avatar_picture)
