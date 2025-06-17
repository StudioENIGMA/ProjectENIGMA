extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.send_message.emit("Chefinho", "seja bem vindo a empresa enigma, uau!", 0)
	EventBus.send_notification.emit("seja bem vindo a empresa enigma, uau!", "Chefinho")
	
	await get_tree().create_timer(3).timeout
	EventBus.send_message.emit("Jorge", "olá, baixa esse loja de vagabundo ai!", 1)
	EventBus.send_notification.emit("olá, baixa esse loja de vagabundo ai!", "Jorge")
	
	await get_tree().create_timer(3).timeout
	EventBus.send_message.emit("Chefinho", "testee", 2)
	EventBus.send_notification.emit("testee", "Chefinho")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
