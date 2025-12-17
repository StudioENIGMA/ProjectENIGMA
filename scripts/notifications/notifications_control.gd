extends Control

const NOTIFICATION_POPUP = preload("res://scenes/apps/messages/notification_popup.tscn")
@onready var clock_timer = $"../../Timer"
@onready var notification_timer = $NotificationTimer
@onready var notification_array = []
@onready var notification_instance = NOTIFICATION_POPUP.instantiate()
@onready var audio_stream_player = $NotificationSoundPlayer
@onready var animation_player

func _ready() -> void:
	EventBus.send_notification.connect(_on_send_notification)

func send_notification(notification_parameter:Dictionary):
	if is_instance_valid(notification_instance):
		notification_instance.queue_free()

	if notification_parameter == null:
		return

	notification_instance = NOTIFICATION_POPUP.instantiate()

	notification_instance.setup(
		notification_parameter.app,
		notification_parameter.content,
		notification_parameter.title
	)

	self.add_child(notification_instance)
	audio_stream_player.play(1.0)
	notification_timer.start()

func _on_send_notification(app: EventBus.App, content: String, title: String, time: float) -> void:
	notification_array.append({"app": app, "content":content, "title":title, "time":time})

func _process(_delta: float) -> void:
	for current_notification in notification_array:
		if(current_notification.time <= clock_timer.get_wait_time() - clock_timer.get_time_left()):
			send_notification(current_notification)
			notification_array.erase(current_notification)

func _on_timer_timeout() -> void:
	if is_instance_valid(notification_instance):
		animation_player = notification_instance.get_child(0)
		animation_player.play("disappear")
		await animation_player.animation_finished
		notification_instance.queue_free()
