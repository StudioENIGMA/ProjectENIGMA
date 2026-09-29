extends VBoxContainer

#region CHILDREN NODES REFERENCES
@export var profile_picture:Control
@export var sender_label: Label
@export var hour_received_label: Label
@export var content_label: Label
@export var attachments_container: HFlowContainer
@export var attachment_template: PanelContainer
## Let the sender and the content be pointed at as a scam discrepancy
@export var sender_target: DiscrepancyTarget
@export var content_target: DiscrepancyTarget
#endregion CHILDREN NODES REFERENCES

## Targets of this email that can be pointed at as a discrepancy, attachments included
var discrepancy_targets: Array[DiscrepancyTarget] = []

func setup(email_data: Dictionary) -> void:
	var npc_name = email_data.get("sender")
	var photo_path = str("res://assets/avatars/", npc_name, ".png")

	profile_picture.setup(photo_path, npc_name)
	sender_label.text = email_data.get("sender")
	hour_received_label.text = GameData.hours_minutes_as_string(email_data.get("relative_due_time"))
	content_label.text = email_data.get("content")

	var email_id := str(email_data.get("email_id", ""))
	sender_target.section = _section(email_id, "sender", str(npc_name))
	content_target.section = _section(email_id, "content", str(email_data.get("content")))
	discrepancy_targets = [sender_target, content_target]

	_show_attachments(email_id, email_data.get("attachments", []))

## Adds one chip per attachment under the content, hiding the row when there is none
##
## email_id: The email the attachments belong to, for the section each chip reports
## attachments: The attachments of the email, as names or dictionaries with a "name"
func _show_attachments(email_id: String, attachments: Array) -> void:
	attachments_container.visible = not attachments.is_empty()

	for attachment in attachments:
		var chip := attachment_template.duplicate() as PanelContainer
		var attachment_name = attachment.get("name", "") if attachment is Dictionary else attachment
		chip.get_node("Row/NameLabel").text = str(attachment_name)
		chip.visible = true
		attachments_container.add_child(chip)

		var chip_target: DiscrepancyTarget = chip.get_node("AttachmentTarget")
		chip_target.section = _section(email_id, "attachment", str(attachment_name))
		discrepancy_targets.append(chip_target)

## Describes a section of this email for the discrepancy report
func _section(email_id: String, section: String, excerpt: String) -> Dictionary:
	return {"source": "email", "email_id": email_id, "section": section, "excerpt": excerpt}
