extends VBoxContainer

const MAX_ITENS := 4

func add_item(new_item: Control) -> void:
	var hbox: HBoxContainer
	
	# Se não existir nenhuma HBox, cria a primeira
	if get_child_count() == 0:
		hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 270)
		add_child(hbox)
	else:
		# Pega a última HBox
		hbox = get_child(get_child_count() - 1) as HBoxContainer
		
		# Se a última já tiver 4 itens, cria uma nova
		if hbox.get_child_count() >= MAX_ITENS:
			hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 270)
			add_child(hbox)
	
	# Adiciona o item na HBox correta
	hbox.add_child(new_item)


func _on_button_pressed() -> void:
	var new_scene = preload("res://scenes/quick_acess_sites_icons.tscn").instantiate()
	add_item(new_scene)
