extends Control

signal subscreen_open_requested(subscreen_name:String, payment_type:GameData.PaymentType)

@export var balance_value_label: Label
@export var hide_value_button: Button
@export var pix_button: Button
@export var ticket_button: Button
@export var visible_balance_icon: Texture2D
@export var hidden_balance_icon: Texture2D

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
		hide_value_button.icon = hidden_balance_icon
		hide_value_button.tooltip_text = "Mostrar saldo"
	else:
		balance_value_label.text = GameData.format_brl(GameData.bank_balance)
		hide_value_button.icon = visible_balance_icon
		hide_value_button.tooltip_text = "Ocultar saldo"

func _on_sub_app_pressed(payment_type:GameData.PaymentType) -> void:
	emit_signal("subscreen_open_requested", GameData.App.PAYMENTCODE, payment_type)

func _on_visibility_changed() -> void:
	if balance_value_label.text != "******":
		balance_value_label.text = GameData.format_brl(GameData.bank_balance)
