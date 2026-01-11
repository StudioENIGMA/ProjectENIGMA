extends Control

const EMAIL_MESSAGE_INSTANCE_SCENE = preload("res://scenes/apps/email/email_message_instance.tscn")

#region CHILDREN NODES REFERENCES
@export var subject_label: Label
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

	# Iterate through emails and create email_message_instances
	for email_message_data in email_data:
		var email_message_instance = EMAIL_MESSAGE_INSTANCE_SCENE.instantiate()
		email_message_instance.setup(email_message_data)
		email_messages_container.add_child(email_message_instance)

	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
	scroll_container.call_deferred("scroll_to_bottom")
