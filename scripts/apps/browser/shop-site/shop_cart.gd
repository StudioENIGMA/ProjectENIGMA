extends Control

signal update_shopping_cart(shopping_cart: Array)

@export var items_v_box: VBoxContainer
@export var total_price_label: Label
const item_line_scene = preload("res://scenes/apps/browser/shops/shop_item_line.tscn")
var shopping_cart: Array
var total_price: float = 0

func setup(shopping_cart_array: Array) -> void:
	for child in items_v_box.get_children():
		child.queue_free()
	
	self.shopping_cart = shopping_cart_array
	for item in shopping_cart:
		var line_instance = item_line_scene.instantiate()
		line_instance.setup(item)
		line_instance.update_shopping_cart.connect(_on_shopping_cart_updated)
		line_instance.delete_item.connect(_on_item_deleted)
		items_v_box.add_child(line_instance)
	update_total_price()

func _on_shopping_cart_updated(previous_data : Dictionary, current_data: Dictionary) -> void:
	var index = shopping_cart.find(previous_data)
	shopping_cart[index] = current_data
	update_total_price()

func update_total_price() -> void:
	total_price = 0
	for item in shopping_cart:
		total_price += item["quantity"] * item["price"]
	total_price_label.text = "Total do Pedido: %s" % GameData.format_brl(total_price)
	update_shopping_cart.emit(shopping_cart)

func _on_item_deleted(child: Control) -> void:
	var index = shopping_cart.find(child.item_data)
	shopping_cart.remove_at(index)
	child.queue_free()
	update_total_price()
