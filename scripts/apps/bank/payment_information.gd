extends Control

@export var informations_container : VBoxContainer
var information_field_scene = preload("res://scenes/apps/bank/information_field.tscn")
var code_informations: Dictionary = {}

func setup(payment_code:GameData.PaymentCode) -> void:

	var children = informations_container.get_children()

	# Iterate through the list and free each child
	for child in children:
		child.queue_free()

	code_informations = get_code_information(payment_code)

	#TODO - MAKE A ERROR MESSAGE IF CODE NOT FOUND
	if code_informations == {}:
		return

	if payment_code.type == GameData.PaymentType.PIX:
		var name_field = information_field_scene.instantiate()
		name_field.setup("Nome", code_informations["name"])
		informations_container.add_child(name_field)
		informations_container.move_child(name_field, 0)

		var cpf_field = information_field_scene.instantiate()
		cpf_field.setup("CPF", code_informations["cpf"])
		informations_container.add_child(cpf_field)
		informations_container.move_child(cpf_field, 1)

		var email_field = information_field_scene.instantiate()
		email_field.setup("Email", code_informations["email"])
		informations_container.add_child(email_field)
		informations_container.move_child(email_field, 2)

		var transaction_value_field = information_field_scene.instantiate()
		transaction_value_field.setup("Valor", GameData.format_brl(code_informations["value"]))
		informations_container.add_child(transaction_value_field)
		informations_container.move_child(transaction_value_field, 3)

	elif payment_code.type == GameData.PaymentType.TICKET:
		var institution_field = information_field_scene.instantiate()
		institution_field.setup("Instituição Pagadora", code_informations["institution"])
		informations_container.add_child(institution_field)
		informations_container.move_child(institution_field, 0)

		var transaction_value_field = information_field_scene.instantiate()
		transaction_value_field.setup("Valor", GameData.format_brl(code_informations["value"]))
		informations_container.add_child(transaction_value_field)
		informations_container.move_child(transaction_value_field, 1)


func get_code_information(payment_code: GameData.PaymentCode) -> Dictionary:
	var file_path = ""

	match payment_code.type:
		GameData.PaymentType.PIX:
			file_path = "res://data/bank/pix_codes_data.json"
		GameData.PaymentType.TICKET:
			file_path = "res://data/bank/ticket_codes_data.json"

	var information_file = FileAccess.open(file_path, FileAccess.READ)

	if !information_file:
		return {}

	var json_string = information_file.get_as_text()
	information_file.close()

	var information_json = JSON.new()
	var parse_result = information_json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", information_json.get_error_message())
		return {}

	if information_json.data.get(payment_code.code) == null:
		return {}

	return information_json.data[payment_code.code]


func _on_confirm_button_pressed() -> void:
	if code_informations != {}:
		GameData.data.bank_balance -= code_informations["value"]
