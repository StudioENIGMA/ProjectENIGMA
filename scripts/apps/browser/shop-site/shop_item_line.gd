extends Control

signal update_shopping_cart(item_data: Dictionary)
signal delete_item(control_node: Control)

@export var unit_price_label: Label
@export var total_price_label: Label
@export var item_name_label: Label
@export var item_quantity_label: Label
@export var item_icon_rect: TextureRect
@export var delete_button: Button

var item_data: Dictionary

func setup(data: Dictionary, shop_enum: GameData.App) -> void:
	item_data = data
	unit_price_label.text = GameData.format_brl(item_data["price"])
	total_price_label.text = GameData.format_brl(item_data["price"] * item_data["quantity"])
	item_name_label.text = item_data["name"]
	item_quantity_label.text = str(item_data["quantity"])
	item_icon_rect.texture = load(item_data["logo"])
	update_ui(shop_enum)

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

func update_ui(shop_enum: GameData.App) -> void:
	var quantity_hex = Color("444444")
	var button_normal_hex = Color("888888")
	var button_hover_hex = Color("666666")

	match shop_enum:
		GameData.App.BROWSERAMAZONIASHOP:
			quantity_hex = Color("146eb4")
			button_normal_hex = Color("ff9900")
			button_hover_hex = Color("ce7a00")
		GameData.App.BROWSEREMILIASHOP:
			quantity_hex = Color("55ddff")
			button_normal_hex = Color("bf1240")
			button_hover_hex = Color("66041eff")
		GameData.App.BROWSERAECSHOP:
			quantity_hex = Color("565656")
			button_normal_hex = Color("6b1331")
			button_hover_hex = Color("ae2855ff")

	var quantity_style_box = item_quantity_label.get_theme_stylebox("normal").duplicate(true)
	quantity_style_box.bg_color = quantity_hex
	item_quantity_label.add_theme_stylebox_override("normal", quantity_style_box)

	var button_normal_box = delete_button.get_theme_stylebox("normal").duplicate(true)
	button_normal_box.bg_color = button_normal_hex
	delete_button.add_theme_stylebox_override("normal", button_normal_box)
	delete_button.add_theme_stylebox_override("pressed", button_normal_box)

	var button_hover_box = button_normal_box.duplicate(true)
	button_hover_box.bg_color = button_hover_hex
	delete_button.add_theme_stylebox_override("hover", button_hover_box)
