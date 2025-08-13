extends VBoxContainer

# Quantidade máxima de itens por linha (HBox)
const MAX_ITENS = 4

# Adiciona um item automaticamente na HBox correta
func add_item(new_item: Control) -> void:
	var hbox: HBoxContainer
	
	# Se não existir nenhuma HBox, cria a primeira
	if get_child_count() == 0:
		hbox = HBoxContainer.new()
		add_child(hbox)
	else:
		# Pega a última HBox
		hbox = get_child(get_child_count() - 1) as HBoxContainer
		
		# Se a última já tiver 4 itens, cria uma nova
		if hbox.get_child_count() >= MAX_ITENS:
			hbox = HBoxContainer.new()
			add_child(hbox)
	
	# Adiciona o item na HBox correta
	hbox.add_child(new_item)
