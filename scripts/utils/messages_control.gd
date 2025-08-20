extends Control

@onready var messages_to_deliver : Array[Dictionary] = []
@onready var timer = $"../../Timer"
@onready var clock_time = $"../ClockRichTextLabel"
func _ready() -> void:
	EventBus.receive_message.connect(on_receive_message)
	#EventBus.answer_option.connect(on_answer_option)

func on_receive_message(name : String, message : String, time : int) -> void:
	messages_to_deliver.push_front({"name" : name, "message" : message, "time" : time})
	
#func on_answer_option(name : String, message : String, title : String, reputation_points : int, time : int) -> void:
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for message in messages_to_deliver:
		if message.time <= timer.wait_time - timer.time_left:
			EventBus.create_message.emit(message.name, message.message, EventBus.Sender.OTHER, GameData.hours_minutes)
			messages_to_deliver.erase(message)
