extends Control

signal subscreen_open_requested(app: GameData.App, optional_data: Variant)
## Emitted when the player, inspecting, points at the store as a scam discrepancy
##
## section: "source" ("shop"), "section" ("store"), "store" (its id in
## GameData.shop_string_to_enum) and "excerpt"
signal discrepancy_picked(section: Dictionary)

const SHOP_ITEM_SCENE = preload("res://scenes/apps/browser/shops/shop_item.tscn")

@export var items_grid_container: GridContainer
@export var cart_circle_label: Panel
@export var cart_quantity_label: Label
@export var shopping_cart_enum: GameData.App
## Brand colours of the product cards' add to cart buttons
@export var accent_color: Color
@export var accent_pressed_color: Color
@export var accent_text_color: Color
## Header showing the store, which can be pointed at as a badly reviewed store
@export var header_panel: PanelContainer

var shopping_cart_quantity: int = 0
var shopping_info: GameData.ShoppingInfo = GameData.ShoppingInfo.new()

## Keeps the store header, the section that can be pointed at, in step
var _inspector := DiscrepancyInspector.new()

func _ready() -> void:
	shopping_info.shop_enum = GameData.cart_enum_to_shop_enum.get(shopping_cart_enum)
	_add_store_target()
	_inspector.picked.connect(discrepancy_picked.emit) # Propagate signal to base app

## Lets the header be pointed at as the store the scam is about
func _add_store_target() -> void:
	if header_panel == null:
		return
	var store_id := ""
	for store_name in GameData.shop_string_to_enum:
		if GameData.shop_string_to_enum[store_name] == shopping_info.shop_enum:
			store_id = store_name

	var target := DiscrepancyTarget.new()
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_panel.add_child(target)
	target.section = {
		"source": "shop",
		"section": "store",
		"store": store_id,
		"excerpt": GameData.shops_names.get(shopping_info.shop_enum, store_id),
	}
	_inspector.add(target)

## Rules group the sections of this screen are checked against, see data/rules/rules.json
func get_rules_app() -> String:
	return "browser"

## Arms the store header so the player can point at it
func set_inspection_mode(is_on: bool) -> void:
	_inspector.set_armed(is_on)

## Sections that can be pointed at, lit while the rest of the phone is dimmed
func get_discrepancy_targets() -> Array[DiscrepancyTarget]:
	return _inspector.get_targets()

## Unmarks the store header
func clear_discrepancy_selection() -> void:
	_inspector.clear_selection()

func setup(shop_items_array: Array):
	for child in items_grid_container.get_children():
		child.queue_free()

	for item_data in shop_items_array:
		var shop_item_instance = SHOP_ITEM_SCENE.instantiate()
		items_grid_container.add_child(shop_item_instance)
		shop_item_instance.setup(item_data)
		shop_item_instance.set_accent(accent_color, accent_pressed_color, accent_text_color)
		shop_item_instance.add_to_cart.connect(_on_added_to_cart)

func _on_added_to_cart(item_data: Dictionary) -> void:
	if !shopping_info.is_order_opened:
		shopping_cart_quantity += item_data["quantity"]
		add_item_to_cart(item_data)
		update_cart_circle()

func add_item_to_cart(item_data: Dictionary) -> void:
	var is_already_in_cart: bool = false

	for item in shopping_info.shopping_cart:
		if item["id"] == item_data["id"]:
			is_already_in_cart = true
			item["quantity"] += item_data["quantity"]

	if !is_already_in_cart:
		shopping_info.shopping_cart.append(item_data)

func update_cart_circle() -> void:
	if shopping_cart_quantity > 0:
		cart_circle_label.visible = true
		cart_quantity_label.text = str(shopping_cart_quantity)
	else:
		cart_circle_label.visible = false

func _on_cart_button_pressed() -> void:
	if shopping_info.is_order_opened:
		subscreen_open_requested.emit(GameData.App.BROWSERPAYMENTSCREEN, shopping_info)
		return
	subscreen_open_requested.emit(
		shopping_cart_enum, shopping_info
	)

func _on_visibility_changed() -> void:
	shopping_cart_quantity = 0
	for item in shopping_info.shopping_cart:
		shopping_cart_quantity += item["quantity"]
	update_cart_circle()
