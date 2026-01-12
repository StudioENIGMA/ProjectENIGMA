extends Control

@export var informations_container : VBoxContainer
var information_field_scene = preload("res://scenes/apps/bank/information_field.tscn")

func setup(payment_code:GameData.PaymentCode) -> void:

	var children = informations_container.get_children()

	# Iterate through the list and free each child
	for child in children:
		child.queue_free()

	if payment_code.type == GameData.PaymentType.PIX:
		var name_field = information_field_scene.instantiate()
		name_field.setup("Nome", "XXXXX")
		informations_container.add_child(name_field)
		informations_container.move_child(name_field, 0)

		var cpf_field = information_field_scene.instantiate()
		cpf_field.setup("CPF", "XXXXXX")
		informations_container.add_child(cpf_field)
		informations_container.move_child(cpf_field, 1)

		var email_field = information_field_scene.instantiate()
		email_field.setup("Email", "XXXXXX")
		informations_container.add_child(email_field)
		informations_container.move_child(email_field, 2)

		var transaction_value_field = information_field_scene.instantiate()
		transaction_value_field.setup("Valor", "XXXXXX")
		informations_container.add_child(transaction_value_field)
		informations_container.move_child(transaction_value_field, 3)

	elif payment_code.type == GameData.PaymentType.TICKET:
		var transaction_value_field = information_field_scene.instantiate()
		transaction_value_field.setup("Valor", "XXXXX")
		informations_container.add_child(transaction_value_field)
		informations_container.move_child(transaction_value_field, 0)

		var institution_field = information_field_scene.instantiate()
		institution_field.setup("Instituição Pagadora", "XXXXXX")
		informations_container.add_child(institution_field)
		informations_container.move_child(institution_field, 1)
