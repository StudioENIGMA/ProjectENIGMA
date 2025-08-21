extends VBoxContainer

const MAX_ITENS := 2

func add_item(new_item: Control) -> void:
	var hbox: HBoxContainer
	
	# Se não existir nenhuma HBox, cria a primeira
	if get_child_count() == 0:
		hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 565)
		add_child(hbox)
	else:
		# Pega a última HBox
		hbox = get_child(get_child_count() - 1) as HBoxContainer
		
		# Se a última já tiver 2 itens, cria uma nova
		if hbox.get_child_count() >= MAX_ITENS:
			hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 565)
			add_child(hbox)
	
	# Adiciona o item na HBox correta
	hbox.add_child(new_item)
