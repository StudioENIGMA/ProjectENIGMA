extends Control

signal add_to_cart(item_data: Dictionary)

@export var item_quantity_label: Label
var item_quantity: int = 1
var item_data: Dictionary

# FUNCTION BEING USED FOR MOCK VALUES
func _ready() -> void:
	item_data["name"] = "Nome do Produto"
	item_data["price"] = 130
	item_data["logo"] = "res://assets/icons/shops/products/camiseta-placeholder.png"

func setup(shop_item_data: Dictionary) -> void:
	item_data = shop_item_data

func update_quantity_label() -> void:
	item_quantity_label.text = str(item_quantity) 

func _on_add_item_pressed() -> void:
	item_quantity += 1
	update_quantity_label()

func _on_remove_item_pressed() -> void:
	if(item_quantity > 1):
		item_quantity -= 1
		update_quantity_label()

func _on_add_to_cart_pressed() -> void:
	item_data["quantity"] = item_quantity
	add_to_cart.emit(item_data)
	item_quantity = 1
	update_quantity_label()
