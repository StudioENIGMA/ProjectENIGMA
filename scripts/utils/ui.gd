extends Control

signal message_answered(answer_id:int)

## Reference to the base app node (propagates app management signals)
@export var base_app:Control
## Reference to the day over UI node
@export var day_over_ui:Control

## Reference to the notifications node
@export var notifications_control:Control

## Setup signal connections to redirect events to each app
func _ready() -> void:
  base_app.messages_app_chat.request_message_notification.connect(
		notifications_control.add_notification_to_queue
  )

  base_app.messages_app_chat.message_answered.connect(message_answered.emit)
