extends Control

signal subscreen_open_requested(app: GameData.App, shopping_cart: Array)

const SHOP_ITEM_SCENE = preload("res://scenes/apps/browser/shops/shop_item.tscn")

@export var items_grid_container: GridContainer
@export var cart_circle_label: Panel
@export var cart_quantity_label: Label
@export var shopping_cart_enum: GameData.App

var shopping_cart: Array = []
var shopping_cart_quantity: int = 0

func setup(shop_items_array: Array):
	for child in items_grid_container.get_children():
		child.queue_free()

	for item_data in shop_items_array:
		var shop_item_instance = SHOP_ITEM_SCENE.instantiate()
		items_grid_container.add_child(shop_item_instance)
		shop_item_instance.setup(item_data)
		shop_item_instance.add_to_cart.connect(_on_added_to_cart)

func _on_added_to_cart(item_data: Dictionary) -> void:
	shopping_cart_quantity += item_data["quantity"]
	shopping_cart.append(item_data)
	print(shopping_cart)
	update_cart_circle()

func update_cart_circle() -> void:
	if shopping_cart_quantity > 0:
		cart_circle_label.visible = true
		cart_quantity_label.text = str(shopping_cart_quantity)
	else:
		cart_circle_label.visible = false

func _on_cart_button_pressed() -> void:
	subscreen_open_requested.emit(shopping_cart_enum, shopping_cart)

func _on_visibility_changed() -> void:
	shopping_cart_quantity = 0
	for item in shopping_cart:
		shopping_cart_quantity += item["quantity"]
	update_cart_circle()
