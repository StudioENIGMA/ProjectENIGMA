extends Node2D

const NEW_EMAIL = preload("res://scenes/apps/email/email_instance.tscn")

@export var email_container: VBoxContainer

var unread_email_count: int = 0

func _ready() -> void:
	# test receiving an email after 2 seconds
	await get_tree().create_timer(2.0).timeout

	var test_email = {
		"sender": "Lucas",
		"content": "Hey! Just wanted to check in and see how you're doing. Let me know when you have a chance to catch up!",
		"attachments": {"filename": "photo.png", "data": PackedByteArray([0,1,2,3])}
	}

	var email_data = EmailData.new(test_email.sender, test_email.content, test_email.attachments)

	_receive_email(email_data)

func _receive_email(email_content: EmailData) -> void:
	unread_email_count += 1
	var email_instance = NEW_EMAIL.instantiate()

	email_container.add_child(email_instance)
	email_instance.setup(email_content)