extends Node

var message : Resource

var settings_instance : Node
var browser_instance : Node
var mail_instance : Node
var fake_store_instance : Node

var random_send_amplitude_max : float = 10.0

var timer : Timer

var block_process : bool = false

func _ready():
	# random_send_amplitude_max = GameData.data.random_send_amplitude_max

	if not check_conditions():
		pass
	elif message.priority <= 0:
		send_message()
		block_process = true
	else:
		timer = Timer.new()
		timer.wait_time = randf_range(1.0, random_send_amplitude_max)
		timer.connect("timeout", send_message)
		add_child(timer)
		timer.start()
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


func send_message(time : int = 0):
	EventBus.send_message.emit(message.sender, message.text, time)
	EventBus.send_notification.emit(message.sender, message.text)
	self.queue_free()


func check_conditions() -> bool:
	var result : int = 0

	if message.conditions.has("settings") and settings_instance.visible == message.conditions["settings"]:
		result += 1

	if message.conditions.has("browser") and browser_instance.visible == message.conditions["browser"]:
		result += 1

	if message.conditions.has("mail") and mail_instance.visible == message.conditions["mail"]:
		result += 1

	if message.conditions.has("fake_store") and fake_store_instance.visible == message.conditions["fake_store"]:
		result += 1

	return result == message.conditions.size()
