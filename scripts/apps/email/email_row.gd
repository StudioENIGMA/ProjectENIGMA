extends MarginContainer

#region SIGNALS
signal subscreen_open_requested(subscreen_name: GameData.App, email_data: Array)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var email_sender_icon: TextureRect
@export var email_sender_label: Label
@export var email_subject_label: Label
@export var email_content_label: Label
@export var email_date_label: Label
@export var annex_section: HBoxContainer
@export var annex_name_label: Label
#endregion CHILDREN NODES REFERENCES

# The data of the email is an array os individual email messages
var email_data: Array

#region SETUP
## Sets up the email instance with the provided email data
func setup(p_email_data) -> void:
	email_data = p_email_data

	# Setup UI content using most recent email (last in the array)
	var last_email = email_data[email_data.size() - 1]

	var npc_name := str(last_email.get("sender", ""))
	var photo_path := "res://assets/avatars/%s.png" % npc_name

	email_sender_icon.texture = load(photo_path)
	email_sender_label.text = npc_name
	email_subject_label.text = last_email.get("subject", "")
	email_content_label.text = last_email.get("content", "")
	email_date_label.text = GameData.hours_minutes_as_string(last_email.get("relative_due_time"))

	# If any annex exists, show annex section
	for email_message in email_data:
		var annex: Dictionary = last_email.get("annex", {})
		var message_has_annex = not annex.is_empty()
		if message_has_annex:
			annex_section.visible = true
			annex_name_label.text = str(annex.get("name", ""))
			break
#endregion SETUP

#region INPUT
## Handles GUI input events for the email instance
##
## event: The input event to be processed
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		subscreen_open_requested.emit(GameData.App.EMAILREAD, email_data)
#endregion INPUT
