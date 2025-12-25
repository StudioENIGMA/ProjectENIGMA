extends Control

## Reference to the event handler node (emits events to be propagated to each app)
@export var event_handler:Node2D

## Reference to the base app node (propagates app management signals)
@export var base_app:Control

## Reference to the notifications node
@export var notifications_control:Control

## Setup signal connections to redirect events to each app
func _ready() -> void:
  _connect_event_handler()
  _connect_notifications()

## Connects the event handler signals to the respective app functions
func _connect_event_handler() -> void:
  # Messages app
  event_handler.npc_message_created.connect(_on_create_message)

## Connects each app to the notifications control signals
func _connect_notifications() -> void:
  # Messages app
  base_app.messages_app.request_message_notification.connect(_on_notification_request)

## When a new message is created by the event handler redirect it to the messaging app
##
## npc_name: The name of the NPC which the conversation is with
## message: The content of the message
## sender: Enum indicating who sent the message (ME or OTHER)
## time: The time the message was sent
func _on_create_message(
  npc_name:String,
  message:String,
  sender:EventBus.Sender,
  time:String
) -> void:
  base_app.messages_app.on_create_message(npc_name, message, sender, time)

## When a notification is to be sent, redirect it to the notifications control
##
## app: The application the notification is related to
## content: The content of the notification
## title: The title of the notification
## time: Duration the notification should be displayed
func _on_notification_request(
  app:EventBus.App,
  content:String,
  title:String,
  time:float
) -> void:
  notifications_control.add_notification_to_queue({
	"app": app,
	"content": content,
	"title": title,
	"time": time
  })
