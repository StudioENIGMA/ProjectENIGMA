extends Control

var quantity_btn

func _ready() -> void:
	quantity_btn = $Panel/Panel/item_quantity

func _on_add_item_pressed() -> void:
	var quantity = int(quantity_btn.text)
	quantity += 1
	quantity_btn.text = str(quantity)


func _on_remove_item_pressed() -> void:
	var quantity = int(quantity_btn.text)
	if quantity > 0:
		quantity -= 1
		quantity_btn.text = str(quantity)
