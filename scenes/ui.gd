extends Control

## Reference to the event handler node (emits events to be propagated to each app)
@export var event_handler:Node2D

## Reference to the base app node (propagates app management signals)
@export var base_app:Control
## Reference to the day over UI node
@export var day_over_ui:Control

## Reference to the notifications node
@export var notifications_control:Control

## Setup signal connections to redirect events to each app
func _ready() -> void:
  _connect_event_handler()
  _connect_notifications()

## Connects the event handler signals to the respective app functions
func _connect_event_handler() -> void:
  # Messages app
  event_handler.npc_message_created.connect(base_app.messages_app.on_create_message)
  EventBus.create_message.connect(base_app.messages_app.on_create_message)

  # End day event
  event_handler.day_ended.connect(day_over_ui.show_day_over)
  event_handler.start_new_day.connect(day_over_ui.hide_day_over)

## Connects each app to the notifications control signals
func _connect_notifications() -> void:
  # Messages app
  base_app.messages_app.request_message_notification.connect(
	  notifications_control.add_notification_to_queue
  )
