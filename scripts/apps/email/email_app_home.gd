extends Control

#region SIGNALS
signal subscreen_open_requested(subscreen_name:String, email_data:Dictionary)
#endregion SIGNALS

const EMAIL_ROW_SCENE = preload("res://scenes/apps/email/email_row.tscn")

#region CHILDREN NODES REFERENCES
@export var list_of_emails: VBoxContainer
#endregion CHILDREN NODES REFERENCES

#region INITIALIZATION
## Instantiates test emails in the email list for demonstration purposes
func _ready() -> void:
	var test_mail_1 = {
		"sender_name": "Chefinho",
		"subject": "Meeting Reminder",
		"content": "Don't forget about our meeting tomorrow at 10 AM.",
		"date_string": "2024-06-15",
	}

	var test_mail_2 = {
		"sender_name": "Financeiro",
		"subject": "Invoice Attached",
		"content": "Please find the attached invoice for your recent purchase.",
		"date_string": "2024-06-14",
		"annex": {
			"name": "Invoice_12345.pdf",
		}
	}

	var email_row: Control = EMAIL_ROW_SCENE.instantiate()
	email_row.setup(test_mail_1)
	email_row.subscreen_open_requested.connect(_on_open_email)
	list_of_emails.add_child(email_row)

	email_row = EMAIL_ROW_SCENE.instantiate()
	email_row.setup(test_mail_2)
	email_row.subscreen_open_requested.connect(_on_open_email)
	list_of_emails.add_child(email_row)
#endregion INITIALIZATION

#region SIGNALS HANDLERS
## Handles the request to open a specific email
##
## email_data: The data of the email to be opened
func _on_open_email(app: GameData.App, email_data:Dictionary,) -> void:
	subscreen_open_requested.emit(app, email_data)
#endregion SIGNALS HANDLERS
