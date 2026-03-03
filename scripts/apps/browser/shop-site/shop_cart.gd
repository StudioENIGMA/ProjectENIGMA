extends Control

signal subscreen_open_requested(app: GameData.App, optional_data: Variant)
signal update_shopping_cart(shopping_cart: Array)

const ITEM_LINE_SCENE = preload("res://scenes/apps/browser/shops/shop_item_line.tscn")

@export var items_v_box: VBoxContainer
@export var total_price_label: Label
@export var finish_button: Button
var shopping_info: GameData.ShoppingInfo

func setup(shopping_info_instance: GameData.ShoppingInfo) -> void:
	self.shopping_info = shopping_info_instance
	update_cart_items()

func _on_shopping_cart_updated(previous_data : Dictionary, current_data: Dictionary) -> void:
	var index = shopping_info.shopping_cart.find(previous_data)
	shopping_info.shopping_cart[index] = current_data
	update_total_price()

func update_cart_items() -> void:
	for child in items_v_box.get_children():
		child.queue_free()

	if shopping_info == null || shopping_info.shopping_cart.is_empty():
		finish_button.visible = false
		return

	finish_button.visible = true
	for item in shopping_info.shopping_cart:
		var line_instance = ITEM_LINE_SCENE.instantiate()
		line_instance.setup(item, shopping_info.shop_enum)
		line_instance.update_shopping_cart.connect(_on_shopping_cart_updated)
		line_instance.delete_item.connect(_on_item_deleted)
		items_v_box.add_child(line_instance)
	update_total_price()

func update_total_price() -> void:
	shopping_info.total_price = 0
	for item in shopping_info.shopping_cart:
		shopping_info.total_price += item["quantity"] * item["price"]
	total_price_label.text = "Total do Pedido: %s" % GameData.format_brl(shopping_info.total_price)
	update_shopping_cart.emit(shopping_info.shopping_cart)

func _on_item_deleted(child: Control) -> void:
	var index = shopping_info.shopping_cart.find(child.item_data)
	shopping_info.shopping_cart.remove_at(index)
	child.queue_free()
	update_total_price()

func _on_finish_button_pressed() -> void:
	shopping_info.is_order_opened = true
	shopping_info.shopping_cart.clear()
	subscreen_open_requested.emit(
		GameData.App.BROWSERPAYMENTSCREEN, shopping_info
	)

func _on_visibility_changed() -> void:
	update_cart_items()
