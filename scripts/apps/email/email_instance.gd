extends Control

signal subscreen_open_requested(subscreen_name:GameData.App)

@export var open_email_button: Button
@export var email_sender_icon: TextureRect
@export var email_sender_label: Label
@export var email_subject_label: Label
@export var email_content_label: Label
@export var email_date_label: Label

@export var annex_section: HBoxContainer
@export var annex_icon: TextureRect
@export var annex_name_label: Label

var email_data: Dictionary

func _ready():
  open_email_button.pressed.connect(_on_open_email_button_pressed)

func setup(p_email_data: Dictionary) -> void:
  email_data = p_email_data

func _on_open_email_button_pressed() -> void:
  subscreen_open_requested.emit(GameData.App.EMAILREAD)
