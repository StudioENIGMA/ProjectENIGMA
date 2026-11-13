extends Control

#region SIGNALS
signal subscreen_open_requested(subscreen_name: GameData.App, email_data: Array)
#endregion SIGNALS

const CRIMSON := Color(0.92156863, 0.039215688, 0.27058825)
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-Bold.ttf")

#region CHILDREN NODES REFERENCES
@export var profile_picture:Control
@export var email_sender_label: Label
@export var email_subject_label: Label
@export var email_content_label: Label
@export var email_date_label: Label
@export var annex_icon: TextureRect
@export var to_read_bubble: Panel
@export var open_email_button: Button
@export var read_subject_settings: LabelSettings
@export var unread_subject_settings: LabelSettings
@export var read_time_settings: LabelSettings
@export var unread_time_settings: LabelSettings
#endregion CHILDREN NODES REFERENCES

# The data of the email is an array os individual email messages
var email_data: Array
## Tag of a blocked scam, made the first time the thread is blocked
var _blocked_tag: PanelContainer

func _ready() -> void:
	open_email_button.pressed.connect(_on_open_email_button_pressed)

#region SETUP
## Sets up the email instance with the provided email data
func setup(p_email_data, is_to_read: bool) -> void:
	email_data = p_email_data

	# Setup UI content using most recent email (last in the array)
	var last_email = email_data[email_data.size() - 1]

	var npc_name := str(last_email.get("sender", ""))
	var photo_path := "res://assets/avatars/%s.png" % npc_name

	profile_picture.setup(photo_path, npc_name)
	email_sender_label.text = npc_name
	email_subject_label.text = last_email.get("subject", "")
	email_content_label.text = str(last_email.get("content", "")).replace("\n", " ").strip_edges()
	email_date_label.text = GameData.hours_minutes_as_string(last_email.get("relative_due_time"))

	# The clip shows up when any message of the thread carries an attachment
	annex_icon.visible = email_data.any(_has_attachment)
	_set_blocked_tag(bool(email_data[0].get("blocked", false)))

	to_read_bubble.visible = is_to_read
	email_subject_label.label_settings = unread_subject_settings if is_to_read else read_subject_settings
	email_date_label.label_settings = unread_time_settings if is_to_read else read_time_settings

## Tells whether an email message carries an attachment
##
## email_message: One message of the thread
func _has_attachment(email_message: Dictionary) -> bool:
	var attachments: Array = email_message.get("attachments", [])
	var annex: Dictionary = email_message.get("annex", {})
	return not attachments.is_empty() or not annex.is_empty()

## Shows the "Golpe bloqueado" tag next to the subject of a blocked scam, waiting to be deleted
func _set_blocked_tag(is_blocked: bool) -> void:
	if _blocked_tag == null:
		if not is_blocked:
			return
		_blocked_tag = _new_blocked_tag()
		email_subject_label.get_parent().add_child(_blocked_tag)
	_blocked_tag.visible = is_blocked

func _new_blocked_tag() -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(CRIMSON, 0.12)
	style.set_corner_radius_all(100)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 1
	style.content_margin_bottom = 1

	var tag := PanelContainer.new()
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "Golpe bloqueado"
	label.add_theme_font_override("font", FONT_BOLD)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", CRIMSON)
	tag.add_child(label)
	return tag
#endregion SETUP

func _on_open_email_button_pressed() -> void:
	subscreen_open_requested.emit(GameData.App.EMAILREAD, email_data)
