extends Control

signal subscreen_open_requested(subscreen_name:String, payment_code:GameData.PaymentCode)

@export var code_title_label: Label
@export var code_line: LineEdit
var payment_code: GameData.PaymentCode

func setup(payment_type:GameData.PaymentType) -> void:
	code_line.text = ""

	if payment_type == GameData.PaymentType.PIX:
		code_title_label.text = "Código Pix"
	elif payment_type == GameData.PaymentType.TICKET:
		code_title_label.text = "Código Boleto"
	else:
		code_title_label.text = "Código"

	payment_code = GameData.PaymentCode.new()
	payment_code.type = payment_type

func _on_continue_button_pressed() -> void:
	payment_code.code = code_line.text
	emit_signal("subscreen_open_requested", GameData.App.PAYMENTINFORMATION, payment_code)
