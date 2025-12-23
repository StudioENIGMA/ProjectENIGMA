extends Control

@export var sender_label: Label
@export var content_label: Label
@export var attachments_button: Button

func setup(email_content: EmailData) -> void:
	var sender = email_content.sender
	var content = email_content.content

  # Attachments for now just store one dictionary (one file)
	var file_attachments = email_content.attachments

  # Cap content to first 45 characters plus "..." if longer
	if content.length() > 45:
		content = content.substr(0, 45) + "..."

	content_label.text = content
	sender_label.text = sender

	# Check for attachments
	if not file_attachments.is_empty():
			attachments_button.visible = true
			attachments_button.text = file_attachments.get("filename", "")
