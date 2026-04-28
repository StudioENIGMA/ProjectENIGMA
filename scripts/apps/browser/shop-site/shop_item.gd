extends Control

signal add_to_cart(item_data: Dictionary)

@export var item_name_label: Label
@export var item_price_label: Label
@export var item_icon_rect: TextureRect
@export var item_quantity_label: Label
@export var add_button: Button
var item_quantity: int = 1
var item_data: Dictionary

func setup(shop_item_data: Dictionary, shop_enum: GameData.App) -> void:
	item_data = shop_item_data
	item_name_label.text = item_data["name"]
	item_price_label.text = GameData.format_brl(item_data["price"])
	item_icon_rect.texture = load(item_data["logo"])
	update_ui(shop_enum)

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

func update_ui(shop_enum: GameData.App) -> void:
	var quantity_hex = Color("444444")
	var button_normal_hex = Color("888888")
	var button_hover_hex = Color("666666")

	match shop_enum:
		GameData.App.BROWSERAMAZONIASHOP:
			quantity_hex = Color("146eb4")
			button_normal_hex = Color("ff9900")
			button_hover_hex = Color("ce7a00")
		GameData.App.BROWSERLIBREMERCADOSHOP:
			quantity_hex = Color("ff9900")
			button_normal_hex = Color("ff9900")
			button_hover_hex = Color("ce7a00")
		GameData.App.BROWSEREMILIASHOP:
			quantity_hex = Color("55ddff")
			button_normal_hex = Color("bf1240")
			button_hover_hex = Color("66041eff")
		GameData.App.BROWSEREMPORIOBOLOSSHOP:
			quantity_hex = Color("2f86c5")
			button_normal_hex = Color("2f86c5")
			button_hover_hex = Color("1e679b")
		GameData.App.BROWSERAECSHOP:
			quantity_hex = Color("565656")
			button_normal_hex = Color("6b1331")
			button_hover_hex = Color("ae2855ff")
		GameData.App.BROWSERZORASHOP:
			quantity_hex = Color("303646")
			button_normal_hex = Color("303646")
			button_hover_hex = Color("272d3b")

	var quantity_style_box = item_quantity_label.get_theme_stylebox("normal").duplicate(true)
	quantity_style_box.bg_color = quantity_hex
	item_quantity_label.add_theme_stylebox_override("normal", quantity_style_box)

	var button_normal_box = add_button.get_theme_stylebox("normal").duplicate(true)
	button_normal_box.bg_color = button_normal_hex
	add_button.add_theme_stylebox_override("normal", button_normal_box)
	add_button.add_theme_stylebox_override("pressed", button_normal_box)

	var button_hover_box = button_normal_box.duplicate(true)
	button_hover_box.bg_color = button_hover_hex
	add_button.add_theme_stylebox_override("hover", button_hover_box)
