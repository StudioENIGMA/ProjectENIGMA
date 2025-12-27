extends Control

const NOTIFICATION_POPUP = preload("res://scenes/apps/messages/notification_popup.tscn")

@export var notification_timer:Timer
@export var audio_stream_player:AudioStreamPlayer2D

var notification_array = []
var notification_instance = NOTIFICATION_POPUP.instantiate()
var animation_player

## Adds a notification to the queue and sends it if it's the only one
##
## notification_parameter: Dictionary containing the notification parameters
func add_notification_to_queue(
	app:EventBus.App,
  content:String,
  title:String,
  time:int
) -> void:
	# Append the notification to the queue
	notification_array.append({
		"app": app,
		"content": content,
		"title": title,
		"time": time
	})

	# If it's the only notification in the queue, send it immediately
	if notification_array.size() == 1:
		send_notification(notification_array[0])

## Sends a notification popup based on the provided parameters
##
## notification_parameter: Dictionary containing the notification parameters
func send_notification(notification_parameter:Dictionary) -> void:
	# Setup the notification popup scene
	notification_instance = NOTIFICATION_POPUP.instantiate()
	notification_instance.setup(
		notification_parameter.app,
		notification_parameter.content,
		notification_parameter.title
	)

	# Add the notification to the scene tree and play sound & animation
	self.add_child(notification_instance)
	audio_stream_player.play(1.0)
	animation_player = notification_instance.get_child(0)
	animation_player.play("appear")

	# Start the timer for notification duration
	notification_timer.start()

## Handles the timeout of the notification timer
##
## Plays the disappear animation and removes the notification from the queue
## Also, sends the next notification if available
func _on_notification_timer_timeout() -> void:
	# Play disappear animation and remove the notification from the queue
	animation_player = notification_instance.get_child(0)
	animation_player.play("disappear")
	await animation_player.animation_finished
	notification_instance.queue_free()
	notification_array.erase(notification_array[0])

	# If other notifications are in the queue, send the next one
	if notification_array.size() > 0:
		send_notification(notification_array[0])
