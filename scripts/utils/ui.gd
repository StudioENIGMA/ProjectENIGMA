extends Control

signal message_answered(answer_id:int)

## Reference to the event handler node (emits events to be propagated to each app)
@export var event_handler:Node2D
@export var story_director:Node2D

## Reference to the base app node (propagates app management signals)
@export var base_app:Control
## Reference to the day over UI node
@export var day_over_ui:Control

## Reference to the notifications node
@export var notifications_control:Control

## Setup signal connections to redirect events to each app
func _ready() -> void:
  _connect_siblings_to_children()
  _connect_children_to_siblings()

## Connects the event handler signals to the respective app functions
func _connect_siblings_to_children() -> void:
  # Messages app
  story_director.npc_message_created.connect(base_app.messages_app_home.on_create_message)
  story_director.npc_message_created.connect(base_app.messages_app_chat.on_create_message)
  story_director.request_answer_option.connect(base_app.messages_app_chat.on_request_answer_option)

  # End day event
  event_handler.day_ended.connect(day_over_ui.show_day_over)
  event_handler.start_new_day.connect(day_over_ui.hide_day_over)

## Connects each app to the notifications control signals
func _connect_children_to_siblings() -> void:
  # Messages app
  base_app.messages_app_chat.request_message_notification.connect(
		notifications_control.add_notification_to_queue
  )

  base_app.messages_app_chat.message_answered.connect(message_answered.emit)
