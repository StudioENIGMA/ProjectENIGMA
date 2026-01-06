extends Control

signal subscreen_open_requested(subscreen_name:String, email_data:Dictionary)

const EMAIL_INSTANCE_SCENE = preload("res://scenes/apps/email/email_instance.tscn")

@export var list_of_emails: VBoxContainer

## Handles the request to open a specific email
##
## email_data: The data of the email to be opened
func _on_open_email(email_data:Dictionary) -> void:
	subscreen_open_requested.emit(GameData.App.EMAILREAD, email_data)