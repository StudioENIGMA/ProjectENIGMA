extends MarginContainer

#region SIGNALS
signal subscreen_open_requested(subscreen_name: GameData.App, email_data: Dictionary)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var email_sender_icon: TextureRect
@export var email_sender_label: Label
@export var email_subject_label: Label
@export var email_content_label: Label
@export var email_date_label: Label
@export var annex_section: HBoxContainer
@export var annex_name_label: Label
#endregion CHILDREN NODES REFERENCES

var email_data: Dictionary = {}

#region INITIALIZATION
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
#endregion INITIALIZATION

#region SETUP
func setup(p_email_data: Dictionary) -> void:
	email_data = p_email_data

	var npc_name := str(email_data.get("sender_name", ""))
	var photo_path := "res://assets/avatars/%s.png" % npc_name

	email_sender_icon.texture = load(photo_path)
	email_sender_label.text = npc_name
	email_subject_label.text = str(email_data.get("subject", ""))
	email_content_label.text = str(email_data.get("content", ""))
	email_date_label.text = str(email_data.get("date_string", ""))

	var annex: Dictionary = email_data.get("annex", {})
	var has_annex := (typeof(annex) == TYPE_DICTIONARY and not annex.is_empty())

	annex_section.visible = has_annex
	if has_annex:
		annex_name_label.text = str(annex.get("name", ""))
#endregion SETUP

#region INPUT
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		subscreen_open_requested.emit(GameData.App.EMAILREAD, email_data)
#endregion INPUT
