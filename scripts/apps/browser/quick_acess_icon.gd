extends Control

signal open_site_requested(app: GameData.App)

@export var site_name: String
@export var logo_url: String
@export var app: GameData.App

@export var logo_button: TextureButton
@export var site_label: Label

func _ready() -> void:
	site_label.text = site_name
	logo_button.texture_normal = load(logo_url)

func _on_texture_button_pressed() -> void:
	open_site_requested.emit(app)
