extends Control

@export var items_grid_container: GridContainer
@export var cart_circle_label: Panel
@export var cart_quantity_label: Label
var shopping_cart: Array
var shopping_cart_quantity: int = 0

func _ready():
	for item in items_grid_container.get_children():
		item.add_to_cart.connect(_on_added_to_cart)

func _on_added_to_cart(item_data: Dictionary) -> void:
	shopping_cart_quantity += item_data["quantity"]
	shopping_cart.append(item_data)
	update_cart_circle()

func update_cart_circle() -> void:
	if shopping_cart_quantity > 0:
		cart_circle_label.visible = true
		cart_quantity_label.text = str(shopping_cart_quantity)
