extends Control

signal dismissed
signal drag_started
signal drag_cancelled
signal tapped

const SWIPE_THRESHOLD: float = 100.0
const SLIDE_DURATION: float = 0.4
## Drag distance (px) under which a release counts as a tap
const TAP_SLOP: float = 8.0

@export var notification_content_label: Label
@export var notification_title_label: Label
@export var app_icon: TextureRect
@export var background: Panel

var initial_content:String
var initial_title:String
var initial_icon:String

var _is_dragging: bool = false
var _drag_start_x: float = 0.0
var _tween: Tween

func setup(app_enum:GameData.App, content:String, title:String):
	self.initial_content = content
	self.initial_title = title

	var app_data = GameData.apps_data[app_enum]
	initial_icon = app_data.icon_path

	# Check if is a bad app
	var is_bad = app_data.has("is_bad") and app_data.is_bad
	if is_bad:
		# If it's a bad app, set color schema to red
		notification_content_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1))
		notification_title_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1))
		app_icon.modulate = Color(1, 0.5, 0.5)

		# Update background color to a red tone
		var styleBox = background.get_theme_stylebox("panel").duplicate()
		styleBox.set("bg_color", Color(1, 0.2, 0.2, 0.8))
		background.add_theme_stylebox_override("panel", styleBox)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	notification_content_label.text = initial_content
	notification_title_label.text = initial_title
	app_icon.texture = load(initial_icon)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_is_dragging = true
			_drag_start_x = event.global_position.x
			_kill_tween()
			drag_started.emit()
		elif _is_dragging:
			_is_dragging = false
			_check_swipe(event.global_position.x - _drag_start_x)
		accept_event()
	elif event is InputEventMouse and _is_dragging:
		position.x = maxf(0.0, event.global_position.x - _drag_start_x)
		accept_event()

func _check_swipe(total_drag: float) -> void:
	if absf(total_drag) < TAP_SLOP:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		tapped.emit()  # parent frees us
	elif total_drag >= SWIPE_THRESHOLD:
		_slide_out()
	else:
		_reset_position()

func _slide_out() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", get_viewport_rect().size.x, SLIDE_DURATION)
	_tween.tween_callback(dismissed.emit)  # parent frees us

func _reset_position() -> void:
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", 0.0, 0.2)
	drag_cancelled.emit()
	
func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
