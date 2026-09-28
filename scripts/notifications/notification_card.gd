extends PanelContainer

## One notification inside the notification center
##
## A tap emits pressed, a horizontal swipe past SWIPE_THRESHOLD slides the card away and emits
## dismissed. Vertical drags are left alone so the ScrollContainer above can scroll the list.

signal pressed
signal dismissed

## Drag distance (px) after which a press stops being a tap
const TAP_SLOP: float = 8.0
const SWIPE_THRESHOLD: float = 110.0
const SLIDE_DURATION: float = 0.25

@export var app_icon: TextureRect
@export var title_label: Label
@export var content_label: Label

var _is_pressing: bool = false
var _is_swiping: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _tween: Tween

## Fills the card with one notification entry of the center, styled like the banner popup
func setup(entry: Dictionary) -> void:
	var app_data: Dictionary = GameData.apps_data.get(entry.app, {})
	app_icon.texture = load(app_data.get("icon_path", "res://assets/icons/default-app.png"))
	title_label.text = entry.title
	content_label.text = entry.content

	# Same red treatment the banner gives bad apps
	if app_data.get("is_bad", false):
		title_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1))
		content_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1))
		app_icon.modulate = Color(1, 0.5, 0.5)
		var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(1, 0.2, 0.2, 0.8)
		add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressing = true
			_is_swiping = false
			_press_position = event.global_position
			return

		if not _is_pressing:
			return
		_is_pressing = false
		var drag: Vector2 = event.global_position - _press_position

		if _is_swiping:
			accept_event()
			if absf(drag.x) >= SWIPE_THRESHOLD:
				_slide_out(signf(drag.x))
			else:
				_snap_back()
		elif drag.length() < TAP_SLOP:
			accept_event()
			pressed.emit()
		return

	if event is InputEventMouseMotion and _is_pressing:
		var drag: Vector2 = event.global_position - _press_position
		if not _is_swiping and absf(drag.x) > TAP_SLOP and absf(drag.x) > absf(drag.y):
			_is_swiping = true
		if _is_swiping:
			accept_event()
			_kill_tween()
			position.x = drag.x
			modulate.a = 1.0 - clampf(absf(drag.x) / size.x, 0.0, 0.6)

func _slide_out(direction: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", direction * size.x * 1.2, SLIDE_DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, SLIDE_DURATION)
	_tween.chain().tween_callback(dismissed.emit)

func _snap_back() -> void:
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", 0.0, 0.2)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
