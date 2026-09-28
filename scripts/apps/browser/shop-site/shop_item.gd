extends Control

signal add_to_cart(item_data: Dictionary)

@export var item_name_label: Label
@export var item_price_label: Label
@export var item_icon_rect: TextureRect
@export var item_quantity_label: Label
@export var add_button: Button
var item_quantity: int = 1
var item_data: Dictionary

func setup(shop_item_data: Dictionary) -> void:
	item_data = shop_item_data
	item_name_label.text = item_data["name"]
	item_price_label.text = GameData.format_brl(item_data["price"])
	item_icon_rect.texture = load(item_data["logo"])

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
	add_to_cart.emit(item_data.duplicate(true))
	item_quantity = 1
	update_quantity_label()

## Paints the add to cart button with the shop's brand colours
func set_accent(normal_color: Color, pressed_color: Color, text_color: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style: StyleBoxFlat = add_button.get_theme_stylebox(state).duplicate()
		style.bg_color = pressed_color if state == "pressed" else normal_color
		add_button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		add_button.add_theme_color_override(state, text_color)
