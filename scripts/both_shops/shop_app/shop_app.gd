extends Control

var buttons = []

func _ready() -> void:
	var container = $Button_Container
	for button in container.get_children():
		buttons.append(button)
	var numero = randi() % 3
	print(numero)
	for i in range(3):
		if i == numero:
			buttons[i].visible = true
		else:
			buttons[i].visible = false

func _on_open_pressed() -> void:
	pass

func _on_update_pressed() -> void:
	buttons[1].text = "Updating..."
	await get_tree().create_timer(2.0).timeout
	buttons[1].text = "Update"
	buttons[0].visible = true
	buttons[1].visible = false
	buttons[2].visible = false
	


func _on_install_pressed() -> void:
	buttons[2].text = "Installing..."
	await get_tree().create_timer(3.0).timeout
	buttons[2].text = "Install"
	buttons[0].visible = true
	buttons[1].visible = false
	buttons[2].visible = false
	
