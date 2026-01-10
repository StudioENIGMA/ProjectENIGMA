extends Control

#region SIGNALS
signal subscreen_open_requested(subscreen_name:String, email_data:Dictionary)
#endregion SIGNALS

const EMAIL_ROW_SCENE = preload("res://scenes/apps/email/email_row.tscn")

#region CHILDREN NODES REFERENCES
@export var list_of_emails: VBoxContainer
#endregion CHILDREN NODES REFERENCES

#region SIGNALS HANDLERS
func on_receive_email(email_data:Dictionary) -> void:
	var email_row: Control = EMAIL_ROW_SCENE.instantiate()
	email_row.setup(email_data)
	email_row.subscreen_open_requested.connect(_on_open_email)
	list_of_emails.add_child(email_row)

## Handles the request to open a specific email
##
## email_data: The data of the email to be opened
func _on_open_email(app: GameData.App, email_data:Dictionary,) -> void:
	subscreen_open_requested.emit(app, email_data)
#endregion SIGNALS HANDLERS
