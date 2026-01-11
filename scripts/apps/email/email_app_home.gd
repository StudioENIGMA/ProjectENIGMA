extends Control

#region SIGNALS
signal subscreen_open_requested(subscreen_name:String, email_data:Dictionary)
#endregion SIGNALS

const EMAIL_ROW_SCENE = preload("res://scenes/apps/email/email_row.tscn")

#region CHILDREN NODES REFERENCES
@export var list_of_emails: VBoxContainer
#endregion CHILDREN NODES REFERENCES

# Emails data is an array of arrays of dictionaries
# Each array represents a conversation
# Each dictionary represents an email message
var emails_data:Array

#region SIGNALS HANDLERS
func on_receive_email(email_data:Dictionary) -> void:
	# Find if email with same subject already exists
	var email_index = emails_data.find_custom(
		# Email is an array of messages, consider only the first one (all have same subjects)
		func(email:Array):return email[0]["subject"] == email_data["subject"]
	)

	# If email doesn't exist, add it to the list
	if email_index == -1:
		# Append as an array to represent a new conversation
		emails_data.append([email_data])

		# Move email to the top of the list
		emails_data.push_front(emails_data.pop_at(email_index))
	else: # Append new email data to existing email
		emails_data[email_index].append(email_data)

		# Move email to the top of the list
		emails_data.push_front(emails_data.pop_at(email_index))

	# Refresh the list of emails in the UI
	_update_list_of_emails(email_index)

## Handles the request to open a specific email
func _on_open_email(app: GameData.App, email_data:Array) -> void:
	subscreen_open_requested.emit(app, email_data)
#endregion SIGNALS HANDLERS

#region UI UPDATES
## Updates the list of emails in the UI
func _update_list_of_emails(updated_email_index) -> void:
	var email_row

	if updated_email_index == -1:
		email_row = EMAIL_ROW_SCENE.instantiate()
		print(emails_data[0])
		email_row.setup(emails_data[0])
		email_row.subscreen_open_requested.connect(_on_open_email)
		list_of_emails.add_child(email_row)
	else:
		email_row = list_of_emails.get_child(updated_email_index)
		email_row.setup(emails_data[0])

	list_of_emails.move_child(email_row, 0)


#endregion UI UPDATES
