extends Control

signal update_shopping_cart(item_data: Dictionary)
signal delete_item(control_node: Control)

@export var unit_price_label: Label
@export var total_price_label: Label
@export var item_name_label: Label
@export var item_quantity_label: Label
@export var item_icon_rect: TextureRect

var item_data: Dictionary

func setup(data: Dictionary) -> void:
	item_data = data
	unit_price_label.text = GameData.format_brl(item_data["price"])
	total_price_label.text = GameData.format_brl(item_data["price"] * item_data["quantity"])
	item_name_label.text = item_data["name"]
	item_quantity_label.text = str(item_data["quantity"])
	item_icon_rect.texture = load(item_data["logo"])

func _on_remove_button_pressed() -> void:
	var previous_data = item_data
	if item_data["quantity"] > 1:
		item_data["quantity"] -= 1
		update_quantity_labels(previous_data)

func _on_add_button_pressed() -> void:
	var previous_data = item_data
	item_data["quantity"] += 1
	update_quantity_labels(previous_data)

func update_quantity_labels(previous_data: Dictionary) -> void:
	item_quantity_label.text = str(item_data["quantity"])
	total_price_label.text = GameData.format_brl(item_data["quantity"] * item_data["price"])
	update_shopping_cart.emit(previous_data, item_data)

func _on_delete_button_pressed() -> void:
	delete_item.emit(self)
