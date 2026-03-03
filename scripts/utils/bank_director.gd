extends Node

#region SIGNALS
signal send_codes_dict(new_dict: Dictionary)
signal send_new_code(new_code: String, app: GameData.App)
#endregion SIGNALS

#region STATE
var pix_codes_static: Dictionary
var ticket_codes_static: Dictionary

var pix_codes_dynamic: Dictionary
var ticket_codes_dynamic: Dictionary
#endregion STATE

#region SETUP
func setup_from_json_file(pix_codes: Dictionary, ticket_codes: Dictionary) -> void:
	pix_codes_static = pix_codes
	ticket_codes_static = ticket_codes
	update_codes_dict()
#endregion SETUP

#region FUNCTIONS
func update_codes_dict() -> void:
	var codes_dict: Dictionary
	codes_dict.merge(pix_codes_static)
	codes_dict.merge(ticket_codes_static)
	codes_dict.merge(pix_codes_dynamic)
	codes_dict.merge(ticket_codes_dynamic)
	emit_signal.call_deferred("send_codes_dict", codes_dict.duplicate(true))

func _on_transaction_completed(payment_code: GameData.PaymentCode) -> void:
	match payment_code.type:
		GameData.PaymentType.PIX:
			pix_codes_dynamic.erase(payment_code.code)
		GameData.PaymentType.TICKET:
			ticket_codes_dynamic.erase(payment_code.code)
	update_codes_dict()

func _on_code_created(code_information, app: GameData.App) -> void:
	var code: String
	match code_information["type"]:
		GameData.PaymentType.PIX:
			code_information.erase("type")
			code = generate_code(GameData.PaymentType.PIX)
			pix_codes_dynamic[code] = code_information
		GameData.PaymentType.TICKET:
			code_information.eraser("type")
			code = generate_code(GameData.PaymentType.TICKET)
			ticket_codes_dynamic[code] = code_information
	update_codes_dict()
	send_new_code.emit(code, app)

func generate_code(type: GameData.PaymentType) -> String:
	match type:
		GameData.PaymentType.PIX:
			return generate_alphanumeric_code()
		GameData.PaymentType.TICKET:
			return generate_numeric_code()
	return ""

func generate_alphanumeric_code() -> String:
	var caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code: String = ""

	for i in range(5):
		var indice = randi() % caracteres.length()
		code += caracteres[indice]

	if pix_codes_static.has(code) or pix_codes_dynamic.has(code):
		return generate_alphanumeric_code()

	return code

func generate_numeric_code() -> String:
	var code: String = ""
	for i in range(6):
		code += str(randi_range(0,9))
	
	if ticket_codes_dynamic.has(code) or ticket_codes_static.has(code):
		return generate_numeric_code()

	return code
#endregion FUNCTIONS
