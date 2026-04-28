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
	GameData.App.REVIEWSSITE: preload("res://assets/icons/shops/square_logos/elogie_la_logo_fundo.png"),
	GameData.App.BROWSERAMAZONIASHOP: preload("res://assets/icons/shops/square_logos/amazonia_fundo.png"),
	GameData.App.BROWSEREMPORIOBOLOSSHOP: preload("res://assets/icons/shops/square_logos/empório_dos_bolos_logo_fundo.png"),
	GameData.App.BROWSERAECSHOP: preload("res://assets/icons/shops/square_logos/a&c_fundo.png"),
	GameData.App.BROWSERLIBREMERCADOSHOP: preload("res://assets/icons/shops/square_logos/libre_mercado_logo_fundo.png"),
	GameData.App.BROWSEREMILIASHOP: preload("res://assets/icons/shops/square_logos/emilia_bolos_fundo.png"),
	GameData.App.BROWSERZORASHOP: preload("res://assets/icons/shops/square_logos/zora_logo_fundo.png"),
}

var sites_names_by_enum = {
	GameData.App.REVIEWSSITE: "ElogieLÁ",
	GameData.App.BROWSERAMAZONIASHOP: "Amazônia",
	GameData.App.BROWSERLIBREMERCADOSHOP: "Libre Mercado",
	GameData.App.BROWSEREMILIASHOP: "Emília Bolos",
	GameData.App.BROWSEREMPORIOBOLOSSHOP: "Empório dos Bolos",
	GameData.App.BROWSERAECSHOP: "A&C",
	GameData.App.BROWSERZORASHOP: "Zora",
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
