@tool
extends Button

signal open_site_requested(app: GameData.App)

const DEFAULT_LOGO =  preload("res://assets/projeto enigma.png")
## Address written on the browser search bar when the site is picked
const SITE_ADDRESSES = {
	GameData.App.REVIEWSSITE: "elogiela.com.br",
	GameData.App.BROWSERAMAZONIASHOP: "amazonia.com.br",
	GameData.App.BROWSERLIBREMERCADOSHOP: "libremercado.com.br",
	GameData.App.BROWSEREMILIASHOP: "emiliabolos.com.br",
	GameData.App.BROWSEREMPORIOBOLOSSHOP: "emporiodosbolos.com.br",
	GameData.App.BROWSERAECSHOP: "aec.com.br",
	GameData.App.BROWSERZORASHOP: "zora.com.br",
}

@export var site: GameData.App:
	set(value):
		site = value
		_ready()

@export var logo_rect: TextureRect
@export var site_label: Label
@export var address_label: Label
## Round badge on the right: an arrow into the search bar, a check once picked
@export var badge: Panel
@export var badge_icon: TextureRect
## Line under the row, hidden on the last row of the list
@export var divider: Control
@export var fill_icon: Texture2D
@export var picked_icon: Texture2D
@export var idle_badge_style: StyleBox
@export var picked_badge_style: StyleBox

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
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)

func update_display() -> void:
	if not is_inside_tree() or not site_label or not logo_rect:
		return

	site_label.text = sites_names_by_enum.get(site, "Unknown")
	logo_rect.texture = logo_by_enum.get(site, DEFAULT_LOGO)
	if address_label:
		address_label.text = SITE_ADDRESSES.get(site, "")

func _on_toggled(picked: bool) -> void:
	if not badge or not badge_icon:
		return
	badge.add_theme_stylebox_override("panel", picked_badge_style if picked else idle_badge_style)
	badge_icon.texture = picked_icon if picked else fill_icon
	badge_icon.modulate = Color(0.101960786, 0.1254902, 0.2) if picked \
			else Color(0.13333334, 0.28235295, 0.38431373)

func _on_texture_button_pressed() -> void:
	open_site_requested.emit(site)
