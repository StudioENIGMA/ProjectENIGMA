extends Control

signal create_code(code_information: Dictionary, shop_enum: GameData.App)
signal cancel_order()

@export var price_label: Label
@export var code_label: Label
var code_by_enum: Dictionary
var info_by_enum: Dictionary
var cart_by_enum: Dictionary
var current_shop_enum: GameData.App

func setup(shopping_info: GameData.ShoppingInfo) -> void:
	current_shop_enum = shopping_info.shop_enum
	info_by_enum[current_shop_enum] = shopping_info
	price_label.text = "Valor total do Pedido: %s" % GameData.format_brl(shopping_info.total_price)
	cart_by_enum[current_shop_enum] = shopping_info.shopping_cart.duplicate(true)
	shopping_info.shopping_cart.clear()

	if !code_by_enum.has(current_shop_enum):
		print(current_shop_enum)
		var code_information = {
			"type": GameData.PaymentType.TICKET,
			"institution": GameData.shops_names[current_shop_enum],
			"value": shopping_info.total_price
		}
		create_code.emit(code_information, current_shop_enum)
		return
	update_code_label()

func _on_code_received(new_code: String, shop_enum: GameData.App) -> void:
	code_by_enum[shop_enum] = new_code
	update_code_label()

func update_code_label() -> void:
	code_label.text = code_by_enum[current_shop_enum]

func remove_code(shop_enum: GameData.App) -> void:
	info_by_enum[shop_enum].reset()
	info_by_enum.erase(shop_enum)
	code_by_enum.erase(shop_enum)
	cart_by_enum.erase(shop_enum)

func _on_cancel_button_pressed() -> void:
	remove_code(current_shop_enum)
	cancel_order.emit()

func _on_transaction_completed(payment_code: GameData.PaymentCode) -> void:
	var key = code_by_enum.find_key(payment_code.code)
	if key != null:
		create_purchase_log(key)
		remove_code(key)

func create_purchase_log(shop_enum: GameData.App) -> void:
	var purchased_items = {}
	for item in cart_by_enum[shop_enum]:
		purchased_items[item.id] = item.quantity

	GameData.purchased_items[shop_enum] = purchased_items
