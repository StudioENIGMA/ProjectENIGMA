extends VBoxContainer

#region CHILDREN NODES REFERENCES
@export var profile_picture:Control
@export var sender_label: Label
@export var hour_received_label: Label
@export var content_label: Label
@export var attachments_container: HFlowContainer
@export var attachment_template: PanelContainer
#endregion CHILDREN NODES REFERENCES

func setup(email_data: Dictionary) -> void:
	var npc_name = email_data.get("sender")
	var photo_path = str("res://assets/avatars/", npc_name, ".png")

	profile_picture.setup(photo_path, npc_name)
	sender_label.text = email_data.get("sender")
	hour_received_label.text = GameData.hours_minutes_as_string(email_data.get("relative_due_time"))
	content_label.text = email_data.get("content")
	_show_attachments(email_data.get("attachments", []))

## Adds one chip per attachment under the content, hiding the row when there is none
##
## attachments: The attachments of the email, as names or dictionaries with a "name"
func _show_attachments(attachments: Array) -> void:
	attachments_container.visible = not attachments.is_empty()

	for attachment in attachments:
		var chip := attachment_template.duplicate() as PanelContainer
		var attachment_name = attachment.get("name", "") if attachment is Dictionary else attachment
		chip.get_node("Row/NameLabel").text = str(attachment_name)
		chip.visible = true
		attachments_container.add_child(chip)
