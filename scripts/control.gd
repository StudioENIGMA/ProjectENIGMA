extends Control

@export var messages : Array[Resource] = []
@export var message_holder : Node

@export var settings_instance : Node
@export var browser_instance : Node
@export var mail_instance : Node
@export var fake_store_instance : Node

func day_zero() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	var timer =	$"../Timer"
	timer.start()

	print(timer.get_time_left())

	# EventBus.send_message.emit("Chefinho", "seja bem vindo a empresa enigma, uau!", 0)
	# EventBus.send_notification.emit("seja bem vindo a empresa enigma, uau!", "Chefinho")

	# await get_tree().create_timer(3).timeout
	# EventBus.send_message.emit("Jorge", "olá, baixa esse loja de vagabundo ai!", 1)
	# EventBus.send_notification.emit("olá, baixa esse loja de vagabundo ai!", "Jorge")
	# send_test_message("Jorge", "olá, baixa esse loja de vagabundo ai!", "olá, baixa esse loja de vagabundo ai!", 1, 3)


	# await get_tree().create_timer(3).timeout
	# EventBus.send_message.emit("Chefinho", "testee", 2)
	# EventBus.send_notification.emit("testee", "Chefinho")
	# send_test_message("Chefino", "testee", "testee", 2, 3)

	# var message_file = FileAccess.open("res://data/messages.json", FileAccess.READ)
	# var message = message_file.get_as_text()
	# message_file.close()

	# var message_json = JSON.new()
	# var data = message_json.parse(message)

	for message in messages:
		if message.day == GameData.data.current_day:
			var new_message_instance = load("res://scripts/control/message_instance.gd").new()
			new_message_instance.message = message
			new_message_instance.settings_instance = settings_instance
			new_message_instance.browser_instance = browser_instance
			new_message_instance.mail_instance = mail_instance
			new_message_instance.fake_store_instance = fake_store_instance
			message_holder.add_child(new_message_instance)
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func send_test_message(sender : String, message : String, notification : String, time : int, timer_time : int):
	await get_tree().create_timer(timer_time).timeout
	EventBus.send_message.emit(sender, message, time)
	EventBus.send_notification.emit(notification, sender)
