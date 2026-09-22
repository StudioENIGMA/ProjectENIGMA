extends Control

const EMAIL_MESSAGE_INSTANCE_SCENE = preload("res://scenes/apps/email/email_message_instance.tscn")

#region CHILDREN NODES REFERENCES
@export var subject_label: Label
@export var thread_size_label: Label
@export var email_messages_container: VBoxContainer
@export var scroll_container: ScrollContainer
#endregion CHILDREN NODES REFERENCES

func setup(email_data: Array) -> void:
	# Clear previous messages
	for child in email_messages_container.get_children():
		email_messages_container.remove_child(child)
		child.queue_free()

	# Set up the top bar with the first email data
	var starting_email = email_data[0]
	subject_label.text = starting_email.get("subject")
	thread_size_label.text = "Caixa de entrada · %d %s" % [
		email_data.size(), "mensagem" if email_data.size() == 1 else "mensagens"
	]

	# Iterate through emails and create email_message_instances
	for email_message_data in email_data:
		var email_message_instance = EMAIL_MESSAGE_INSTANCE_SCENE.instantiate()
		email_message_instance.setup(email_message_data)
		email_messages_container.add_child(email_message_instance)

	# Opens the thread showing the latest email, once the messages just added are
	# accounted for by the containers
	scroll_container.jump_to_bottom()
