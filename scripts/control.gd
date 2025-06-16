extends Control

signal send_notification(content : String, title : String)
@onready var timer = $Timer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emit_signal("send_notification", "seja bem vindo a empresa enigma, uau!", "Chefinho")
	timer.start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	emit_signal("send_notification", "olá, baixa esse loja de vagabundo ai!", "Jorge")
