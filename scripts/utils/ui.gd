extends Control

#region SIGNALS
signal message_answered(answer_id:int)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var base_app:Control
@export var day_over_ui:Control
@export var notifications_control:Control
@export var desktop_ui:Control
#endregion CHILDREN NODES REFERENCES

#region INITIALIZATION
## Setup signal connections to redirect events to each app
func _ready() -> void:
  base_app.messages_app_chat.request_message_notification.connect(
		notifications_control.add_notification_to_queue
  )

  base_app.messages_app_chat.message_answered.connect(message_answered.emit)
  base_app.apk_installation_requested.connect(desktop_ui._on_app_installed)
#endregion INITIALIZATION
