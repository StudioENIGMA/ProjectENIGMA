## Base application script that handles common functionality for all apps
## This script should redirect all events received to the respective app scripts
## Also, buttons from the top bar should be handled here

extends Node2D

## Reference to the event handler node (emits events to be propagated to each app)
@export var event_handler:Node2D

## Reference to the messaging app node (propagates message creation events)
@export var messages_app:Node2D

## Setup signal connections to redirect events to each app
func _ready() -> void:
  _connect_event_handler()

## Connects the event handler signals to the respective app functions
func _connect_event_handler() -> void:
  event_handler.npc_message_created.connect(_on_create_message)

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
  messages_app.on_create_message(npc_name, message, sender, time)
