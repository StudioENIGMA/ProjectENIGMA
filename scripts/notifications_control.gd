extends Control

const NOTIFICATION_POPUP = preload("res://scenes/notification_popup.tscn")
@onready var timer = $Timer
@onready var notification_array = []
@onready var notification_instance = NOTIFICATION_POPUP.instantiate()

func _ready() -> void:
	EventBus.send_notification.connect(_on_send_notification)

func _on_timer_timeout() -> void:
	notification_instance.queue_free()
	
	notification_instance = NOTIFICATION_POPUP.instantiate()
	
	var notification_data = notification_array.pop_front()
	
	if notification_data == null:
		return
	
	notification_instance.setup(notification_data.content, notification_data.title)
	
	self.add_child(notification_instance)

func _on_send_notification(content: String, title: String) -> void:
	notification_array.append({"content" : content, "title" : title})
