extends Control

#region SIGNALS
signal subscreen_open_requested(subscreen_name:String, email_data:Dictionary)
signal request_email_notification(
	app:GameData.App,
  content:String,
  title:String,
  time:int
)
#endregion SIGNALS

const EMAIL_ROW_SCENE = preload("res://scenes/apps/email/email_row.tscn")

#region CHILDREN NODES REFERENCES
@export var list_of_emails: VBoxContainer
#endregion CHILDREN NODES REFERENCES

# Emails data is an array of arrays of dictionaries
# Each array represents a conversation
# Each dictionary represents an email message
var emails_data:Array

func _ready() -> void:
	load_emails(GameData.saved_email_threads)

#region SIGNALS HANDLERS
func on_receive_email(email_data: Dictionary) -> void:
	var email_index = emails_data.find_custom(
		func(email_thread: Array): return email_thread[0]["conversation_id"] == email_data["conversation_id"]
	)

	if email_index == -1:
		emails_data.push_front([email_data])
	else:
		emails_data[email_index].append(email_data)
		emails_data.push_front(emails_data.pop_at(email_index))

	request_email_notification.emit(
		GameData.App.EMAIL,
		email_data["subject"],
		email_data["sender"],
		GameData.hours_minutes
	)
	_update_list_of_emails(email_index)
	_sync_emails_to_game_data()

## Handles the request to open a specific email
func _on_open_email(app: GameData.App, email_data:Array) -> void:
	subscreen_open_requested.emit(app, email_data)
#endregion SIGNALS HANDLERS

#region UI UPDATES
## Updates the list of emails in the UI
func _update_list_of_emails(updated_email_index: int) -> void:
	var email_row

	if updated_email_index == -1:
		email_row = EMAIL_ROW_SCENE.instantiate()
		email_row.setup(emails_data[0])
		email_row.subscreen_open_requested.connect(_on_open_email)
		list_of_emails.add_child(email_row)
	else:
		email_row = list_of_emails.get_child(updated_email_index)
		email_row.setup(emails_data[0])

	list_of_emails.move_child(email_row, 0)
#endregion UI UPDATES

func _sync_emails_to_game_data() -> void:
	GameData.saved_email_threads = emails_data.duplicate(true)

func load_emails(saved_threads: Array) -> void:
	emails_data.clear()

	for child in list_of_emails.get_children():
		child.queue_free()

	for saved_thread in saved_threads:
		var restored_thread = saved_thread.duplicate(true)
		emails_data.append(restored_thread)

		var email_row = EMAIL_ROW_SCENE.instantiate()
		email_row.setup(restored_thread)
		email_row.subscreen_open_requested.connect(_on_open_email)
		list_of_emails.add_child(email_row)
