extends Node

var message : Message
var control_instance : Controller

var random_send_amplitude_max : float = 10.0
var block_process : bool = false

func _ready():
	random_send_amplitude_max = GameData.data.random_send_amplitude_max

	if not check_conditions():
		pass
	elif message.priority <= 0:
		send_message()
		block_process = true
	else:
		var message_time = randf_range(control_instance.timer.wait_time - control_instance.timer.time_left, random_send_amplitude_max)
		send_message(message_time)
		block_process = true


func _process(delta: float) -> void:
	if block_process:
		return

	random_send_amplitude_max -= delta
	if random_send_amplitude_max <= 0.0:
		random_send_amplitude_max = 0.0

	if not check_conditions():
		pass
	elif message.priority <= 0:
		send_message()
		block_process = true
	else:
		var message_time = randf_range(control_instance.timer.wait_time - control_instance.timer.time_left, random_send_amplitude_max)
		send_message(message_time)
		block_process = true


func send_message(time : int = -1):
	print(message.text)
	if message.is_answer:
		# print(message.text, " ", message.sender, " ", message.id)
		EventBus.answer_option.emit(message.sender, message.text, message.text, 1000, time, message.id)
	else:
		EventBus.receive_message.emit(message.sender, message.text, time)
		EventBus.send_notification.emit("messages", message.text, message.sender, time)

	await get_tree().create_timer(0.1).timeout

	add_depedencies_to_queue()

	# self.queue_free()

func add_depedencies_to_queue():
	var has_answerables : bool = not message.answers.is_empty()
	var answer_ids : Array[int] = []

	if has_answerables:
		for answer in message.answers:
			var uid = ResourceUID.create_id()
			ResourceUID.add_id(uid, answer.resource_path)
			answer.id = uid
			message.answers[answer] = uid
			answer_ids.push_back(uid)
			answer.priority = message.priority
			control_instance.add_answers_to_send(answer)

	if message.next_message != null:
		message.next_message.priority = message.priority

		if has_answerables:
			control_instance.add_message_to_waiting(message.next_message, answer_ids)
		elif message.is_answer:
			message.next_message.priority = -1000
			control_instance.add_message_to_waiting(message.next_message, [message.id])
		else:
			control_instance.add_message_to_send(message.next_message)


func check_conditions() -> bool:
	var result : int = 0

	if message.conditions.has("settings") and GameData.data.has_settings == message.conditions["settings"]:
		result += 1

	if message.conditions.has("browser") and GameData.data.has_browser == message.conditions["browser"]:
		result += 1

	if message.conditions.has("mail") and GameData.data.has_mail == message.conditions["mail"]:
		result += 1

	if message.conditions.has("fake_store") and GameData.data.has_fake_store == message.conditions["fake_store"]:
		result += 1

	if message.conditions.has("store") and GameData.data.has_store == message.conditions["store"]:
		result += 1

	return result == message.conditions.size()
