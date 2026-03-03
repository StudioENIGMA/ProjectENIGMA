@tool
extends Control

signal open_site_requested(app: GameData.App)

const DEFAULT_LOGO =  preload("res://assets/projeto enigma.png")

@export var site: GameData.App:
	set(value):
		site = value
		_ready()

@export var logo_button: TextureButton
@export var site_label: Label

var logo_by_enum = {
	GameData.App.REVIEWSSITE: preload("res://assets/icons/shops/square_logos/elogie_la.png"),
	GameData.App.BROWSERAMAZONIASHOP: preload("res://assets/icons/shops/square_logos/amazonia.png"),
}

var sites_names_by_enum = {
	GameData.App.REVIEWSSITE: "ElogieLÁ",
	GameData.App.BROWSERAMAZONIASHOP: "Amazônia",
	GameData.App.BROWSEREMILIASHOP: "Emília Bolos",
	GameData.App.BROWSERAECSHOP: "A&C"
}

func _ready() -> void:
	update_display()

func update_display() -> void:
	if not is_inside_tree() or not site_label or not logo_button:
		return

	site_label.text = sites_names_by_enum.get(site, "Unknown")
	logo_button.texture_normal = logo_by_enum.get(site, DEFAULT_LOGO)

func _on_texture_button_pressed() -> void:
	open_site_requested.emit(site)
