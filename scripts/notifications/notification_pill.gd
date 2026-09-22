extends PanelContainer

## One notification inside the home-screen notification widget
##
## Shows the app icon and the notification title in a single pill, tapping it emits pressed.

signal pressed

const CRIMSON = Color(0.92156863, 0.039215688, 0.27058825)
const CREAM = Color(1, 1, 0.972549)
const PRESSED_TINT = Color(1, 1, 1, 0.7)

@export var app_icon: TextureRect
@export var title_label: Label

## Fills the pill with one entry of the notification center
func setup(entry: Dictionary) -> void:
	var app_data: Dictionary = GameData.apps_data.get(entry.app, {})
	app_icon.texture = load(app_data.get("icon_path", "res://assets/icons/default-app.png"))
	title_label.text = entry.title

	# Alerts (hacks, bad apps) get the crimson treatment
	if app_data.get("is_bad", false):
		var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
		style.bg_color = CRIMSON
		add_theme_stylebox_override("panel", style)
		title_label.add_theme_color_override("font_color", CREAM)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Dim while held, like a pressed button. Accepting the press too keeps the widget from dimming
		modulate = PRESSED_TINT if event.pressed else Color.WHITE
		accept_event()
		if not event.pressed:
			pressed.emit()
