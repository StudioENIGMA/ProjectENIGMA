extends Control

signal open_real_shop
signal open_fake_shop

@export var site_name : String
@export var site_text_label : Label

func _ready() -> void:
    site_text_label.text = site_name


func _on_texture_button_pressed() -> void:
    if(site_name == "Loja"):
        open_real_shop.emit()
    else:
        open_fake_shop.emit()
