extends Control

signal subscreen_open_requested(subscreen_name:String, payment_type:GameData.PaymentType)

@export var balance_value_label: Label
@export var hide_value_button: TextureButton
@export var pix_button: TextureButton
@export var ticket_button: TextureButton

func _ready() -> void:
	hide_value_button.pressed.connect(_on_hide_button_pressed)
	balance_value_label.text = "******"
	pix_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.PaymentType.PIX])
	)
	ticket_button.pressed.connect(
		_on_sub_app_pressed.bindv([GameData.PaymentType.TICKET])
	)

func _on_hide_button_pressed() -> void:
	if balance_value_label.text != "******":
		balance_value_label.text = "******"
	else:
		var formatted_value = "R$%.2f" % GameData.data.bank_balance
		balance_value_label.text = formatted_value

func _on_sub_app_pressed(payment_type:GameData.PaymentType) -> void:
	emit_signal("subscreen_open_requested", GameData.App.PAYMENTCODE, payment_type)
