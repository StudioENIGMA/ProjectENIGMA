extends Control

signal transaction_completed(payment_code: GameData.PaymentCode)
signal request_transaction_notification(app:GameData.App, content:String, title:String, time:int)
## Emitted when the player, inspecting, points at a field as a scam discrepancy
##
## section: "source" ("bank"), "section" ("pix_code", "qr_read", "recipient", "reason",
## "value", "ticket_payee" or "ticket_bank"), "payment_code" and "excerpt"
signal discrepancy_picked(section: Dictionary)

@export var informations_container : VBoxContainer
@export var not_found_container: VBoxContainer
@export var confirm_button: Button
var information_field_scene = preload("res://scenes/apps/bank/information_field.tscn")
var payment_code: GameData.PaymentCode
var codes_dict: Dictionary

## Keeps the fields that can be pointed at as a discrepancy in step
var _inspector := DiscrepancyInspector.new()

func _ready() -> void:
	_inspector.picked.connect(discrepancy_picked.emit) # Propagate signal to base app

func setup(code:GameData.PaymentCode) -> void:
	payment_code = code
	var children = informations_container.get_children()

	# Iterate through the list and free each child
	for child in children:
		informations_container.remove_child(child)
		child.queue_free()
	_inspector.forget_all()

	# A payment of a scam the player reported is refused
	if GameData.blocked_payment_codes.has(payment_code.code):
		not_found_container.setup_blocked(payment_code.code)
		not_found_container.visible = true
		confirm_button.visible = false
		return

	var code_informations = codes_dict.get(payment_code.code)

	if code_informations == null or not _is_valid_information_for_payment_type(code_informations):
		not_found_container.setup(payment_code.code);
		not_found_container.visible = true;
		confirm_button.visible = false;
		return
	not_found_container.visible = false;
	confirm_button.visible = true;

	var reason := str(code_informations.get("reason", "—"))
	var value := GameData.format_brl(code_informations["value"])

	if payment_code.type == GameData.PaymentType.PIX:
		if payment_code.from_qr:
			_add_field("Código lido do QR", payment_code.code, "qr_read")
		else:
			_add_field("Código Pix", payment_code.code, "pix_code")
		_add_field("Nome", code_informations["name"], "recipient")
		_add_field("CPF/CNPJ", code_informations["cpf"], "recipient")
		_add_field("Email", code_informations["email"], "recipient")
		_add_field("Motivo", reason, "reason")
		_add_field("Valor", value, "value")

	elif payment_code.type == GameData.PaymentType.TICKET:
		_add_field("Cedente", code_informations["institution"], "ticket_payee")
		_add_field("Banco", str(code_informations.get("bank", "—")), "ticket_bank")
		_add_field("Motivo", reason, "reason")
		_add_field("Valor", value, "value")

## Adds a field of the payment, which the player can point at as a discrepancy
##
## title: What the field is, shown over it
## information: The value of the field
## section: The section of the discrepancy report it stands for
func _add_field(title: String, information: String, section: String) -> void:
	var field = information_field_scene.instantiate()
	field.setup(title, information)
	informations_container.add_child(field)
	field.section_target.section = {
		"source": "bank",
		"section": section,
		"payment_code": payment_code.code,
		"excerpt": information,
	}
	_inspector.add(field.section_target)

## Rules group the sections of this screen are checked against, see data/rules/rules.json
func get_rules_app() -> String:
	return "Bank"

## Arms every field so the player can point at the one giving the scam away
##
## The confirm button is put away meanwhile, so nothing is paid by accident
func set_inspection_mode(is_on: bool) -> void:
	_inspector.set_armed(is_on)
	confirm_button.disabled = is_on

## Sections that can be pointed at, lit while the rest of the phone is dimmed
func get_discrepancy_targets() -> Array[DiscrepancyTarget]:
	return _inspector.get_targets()

## Unmarks the field picked, the others stay armed
func clear_discrepancy_selection() -> void:
	_inspector.clear_selection()

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
	# Reported while the screen was open
	if GameData.blocked_payment_codes.has(payment_code.code):
		setup(payment_code)
		return

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
