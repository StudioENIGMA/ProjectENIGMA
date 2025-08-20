extends Control

class_name Controller

@export var messages : Array[Message] = []
@export var message_holder : Node
@export var apps_holder : Node
@export var next_day_button : Button

@export var day_over_overlay : Node2D

var messages_to_instance : Array[Message] = []
var answers_to_instance : Array[Message] = []
var messages_waiting_answers : Dictionary[Message, Array] = {}

var message_delay_timer : Timer

var day_over : bool = false

func day_zero() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_control()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if day_over:
		return

	if answers_to_instance.size() == 0:
		return

	var new_answer_instance = load("res://scripts/control/message_instance.gd").new()
	new_answer_instance.control_instance = self
	new_answer_instance.message = answers_to_instance.pop_front()
	message_holder.add_child(new_answer_instance)
	# process_messages()


func setup_control():
	print("current day: ", GameData.data.current_day)

	day_over_overlay.visible = false
	day_over = false
	self.visible = true

	EventBus.message_answered.connect(process_waiting_messages)

	var timer =	$"../Timer"
	timer.wait_time = GameData.data.max_game_time
	timer.start()
	timer.timeout.connect(end_day)

	message_delay_timer = Timer.new()
	message_delay_timer.one_shot = false
	message_delay_timer.wait_time = 1.0
	self.add_child(message_delay_timer)
	message_delay_timer.timeout.connect(process_messages)
	message_delay_timer.start()

	messages_to_instance.clear()
	answers_to_instance.clear()
	messages_waiting_answers.clear()

	for message in messages:
		if message.day == GameData.data.current_day and not message.is_answer and not message.is_next:
			messages_to_instance.append(message)
		pass

	messages_to_instance.sort_custom(custom_sort_messages)


func process_messages():
	# await get_tree().create_timer(1.0).timeout
	if messages_to_instance.size() == 0:
		return

	var new_message_instance = load("res://scripts/control/message_instance.gd").new()
	new_message_instance.control_instance = self
	new_message_instance.message = messages_to_instance.pop_front()
	message_holder.add_child(new_message_instance)


func process_waiting_messages(id : int):
	for message in messages_waiting_answers.keys():
		if messages_waiting_answers[message].has(id):
			add_message_to_send(message)

	pass


func add_message_to_send(message: Message) -> void:
	messages_to_instance.append(message)
	messages_to_instance.sort_custom(custom_sort_messages)

func add_answers_to_send(message: Message) -> void:
	answers_to_instance.append(message)
	# answers_to_instance.sort_custom(custom_sort_messages)


func add_message_to_waiting(message: Message, ids: Array[int]) -> void:
	messages_waiting_answers[message] = ids


func custom_sort_messages(a, b) -> bool:
	if a.priority < b.priority:
		return true
	return false


func end_day():
	next_day_button.text = "Iniciar Dia " + str(GameData.data.current_day + 1)
	day_over_overlay.visible = true
	day_over = true
	message_delay_timer.stop()
	self.visible = false
	for app in apps_holder.get_children():
		app.visible = false


func _on_next_day_button_pressed() -> void:
	GameData.data.current_day += 1
	setup_control()
