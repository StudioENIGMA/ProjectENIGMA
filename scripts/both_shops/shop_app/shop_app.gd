extends Control

var buttons = []

func _ready() -> void:
	var container = $Button_Container
	for button in container.get_children():
		buttons.append(button)
	var numero = randi() % 3
	for i in range(3):
		if i == numero:
			buttons[i].visible = true
		else:
			buttons[i].visible = false

func _on_open_pressed() -> void:
	pass

func _on_update_pressed() -> void:
	buttons[1].text = "Atualizando..."
	await get_tree().create_timer(2.0).timeout
	buttons[1].text = "Atualizar"
	buttons[0].visible = true
	buttons[1].visible = false
	buttons[2].visible = false
	


func _on_install_pressed() -> void:
	buttons[2].text = "Instalando..."
	await get_tree().create_timer(3.0).timeout
	buttons[2].text = "Instalar"
	buttons[0].visible = true
	buttons[1].visible = false
	buttons[2].visible = false
	
