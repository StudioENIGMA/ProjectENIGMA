extends Control

signal transaction_completed(payment_code: GameData.PaymentCode)
signal request_transaction_notification(app:GameData.App, content:String, title:String, time:int)

@export var informations_container : VBoxContainer
@export var not_found_container: VBoxContainer
@export var confirm_button: Button
var information_field_scene = preload("res://scenes/apps/bank/information_field.tscn")
var payment_code: GameData.PaymentCode
var codes_dict: Dictionary

func setup(code:GameData.PaymentCode) -> void:
	payment_code = code
	var children = informations_container.get_children()

	# Iterate through the list and free each child
	for child in children:
		informations_container.remove_child(child)
		child.queue_free()

	var code_informations = codes_dict.get(payment_code.code)

	if code_informations == null or not _is_valid_information_for_payment_type(code_informations):
		not_found_container.setup(payment_code.code);
		not_found_container.visible = true;
		confirm_button.visible = false;
		return
	not_found_container.visible = false;
	confirm_button.visible = true;

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

func _is_valid_information_for_payment_type(code_informations: Dictionary) -> bool:
	if payment_code.type == GameData.PaymentType.PIX:
		return (
			code_informations.has("name")
			and code_informations.has("cpf")
			and code_informations.has("email")
			and code_informations.has("value")
		)

	if payment_code.type == GameData.PaymentType.TICKET:
		return (
			code_informations.has("institution")
			and code_informations.has("value")
		)

	return false

func _on_codes_dict_updated(new_dict: Dictionary) -> void:
	codes_dict = new_dict

func _on_confirm_button_pressed() -> void:
	var code_informations = codes_dict.get(payment_code.code)
	if code_informations != null:
		GameData.bank_balance -= code_informations["value"]
		emit_signal("transaction_completed", payment_code);

		var receiver: String
		if(code_informations.has("name")):
			receiver = code_informations["name"]
		elif(code_informations.has("institution")):
			receiver = code_informations["institution"]

		var formatted_value = GameData.format_brl(code_informations["value"])
		var content = "Uma transação foi realizada para %s no valor de %s" % [receiver, formatted_value]
		var time: int = GameData.hours_minutes
		request_transaction_notification.emit(
			GameData.App.BANK, content, "Transação realizada com sucesso", time
		);
