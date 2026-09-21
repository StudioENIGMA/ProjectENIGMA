extends Control

## Notification center: a pull-down list of every notification received
##
## Keeps every notification the phone received until the player clears it or opens its app.
## Pull the mint tab at the top edge down to open it. The tab rides along the sheet's bottom edge,
## flipping on the way, and ends upside down at the bottom of the screen, where pushing it up (or
## tapping it) closes the center. Notifications are listed one card each, newest on top.

## Emitted when the player taps a notification to jump into its app
signal app_open_requested(app: GameData.App)

const NOTIFICATION_CARD = preload("res://scenes/notifications/notification_card.tscn")

const SLIDE_DURATION: float = 0.35
## Fraction of the screen the sheet must be dragged before a release commits to opening/closing
const COMMIT_FRACTION: float = 0.2
## Drag speed (px/s) that commits regardless of the distance
const FLICK_SPEED: float = 700.0
const TAP_SLOP: float = 8.0
## Height of the tab's touch strip when the center is closed (top edge) and open (bottom edge).
## The open strip is taller since nothing sits under it
const HANDLE_HEIGHT_CLOSED: float = 22.0
const HANDLE_HEIGHT_OPEN: float = 48.0

#region CHILDREN NODES REFERENCES
@export var pull_handle: Control
@export var pull_tab: Control
@export var sheet: Control
@export var cards_container: VBoxContainer
@export var count_label: Label
@export var empty_state: Control
@export var clear_all_button: Button
#endregion CHILDREN NODES REFERENCES

var is_open: bool = false

## Every notification in the center, newest first
var _entries: Array = []

var _is_dragging: bool = false
var _was_open_on_press: bool = false
var _press_y: float = 0.0
var _press_sheet_y: float = 0.0
var _drag_velocity: float = 0.0
var _tween: Tween

func _ready() -> void:
	sheet.visible = false
	pull_handle.gui_input.connect(_on_handle_gui_input)
	clear_all_button.pressed.connect(clear_all)
	resized.connect(_on_resized)
	_rebuild()
	_sync_handle()

#region PUBLIC API
## Stores a notification the phone just received
func add_notification(app: GameData.App, content: String, title: String) -> void:
	_entries.push_front({
		"app": app,
		"content": content,
		"title": title,
	})
	_rebuild()

## Clears the notifications of an app once the player opens it
func on_app_opened(main_app: GameData.App) -> void:
	var had_entries: bool = _entries.any(func(entry): return _belongs_to(entry, main_app))
	if not had_entries:
		return
	_entries = _entries.filter(func(entry): return not _belongs_to(entry, main_app))
	_rebuild()

func clear_all() -> void:
	_entries.clear()
	_rebuild()

## Allows or blocks pulling the center down (e.g. blocked during hack minigames)
func set_enabled(enabled: bool) -> void:
	pull_handle.visible = enabled
	if not enabled and (is_open or sheet.visible):
		_kill_tween()
		_finish_close()

func open() -> void:
	_slide_to(0.0)
	is_open = true

func close() -> void:
	if not sheet.visible:
		return
	_slide_to(-size.y)
	is_open = false

#endregion PUBLIC API

#region GESTURES
func _on_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.global_position.y)
		elif _is_dragging:
			_end_drag(event.global_position.y)
		accept_event()
	elif event is InputEventMouseMotion and _is_dragging:
		_drag_velocity = event.velocity.y
		_set_sheet_y(clampf(_press_sheet_y + event.global_position.y - _press_y, -size.y, 0.0))
		accept_event()

func _begin_drag(pointer_y: float) -> void:
	_kill_tween()
	_is_dragging = true
	_was_open_on_press = is_open
	_press_y = pointer_y
	_drag_velocity = 0.0
	if not sheet.visible:
		sheet.visible = true
		_set_sheet_y(-size.y)
	_press_sheet_y = sheet.position.y

func _end_drag(pointer_y: float) -> void:
	_is_dragging = false
	var distance: float = pointer_y - _press_y

	# A tap on the open tab closes, a tap on the closed one just peeks and falls back
	if absf(distance) < TAP_SLOP:
		close()
		return

	var should_open: bool
	if _drag_velocity > FLICK_SPEED:
		should_open = true
	elif _drag_velocity < -FLICK_SPEED:
		should_open = false
	elif _was_open_on_press:
		should_open = sheet.position.y > -size.y * COMMIT_FRACTION
	else:
		should_open = sheet.position.y > -size.y * (1.0 - COMMIT_FRACTION)

	if should_open:
		open()
	else:
		close()
#endregion GESTURES

#region LIST
func _rebuild() -> void:
	for child in cards_container.get_children():
		cards_container.remove_child(child)
		child.queue_free()

	for entry in _entries:
		var card = NOTIFICATION_CARD.instantiate()
		cards_container.add_child(card)
		card.setup(entry)
		card.pressed.connect(_on_entry_pressed.bind(entry))
		card.dismissed.connect(_on_entry_dismissed.bind(entry))

	empty_state.visible = _entries.is_empty()
	clear_all_button.visible = not _entries.is_empty()
	match _entries.size():
		0:
			count_label.text = "Tudo em dia"
		1:
			count_label.text = "1 notificação"
		_:
			count_label.text = "%d notificações" % _entries.size()

func _on_entry_pressed(entry: Dictionary) -> void:
	close()
	app_open_requested.emit(entry.app)

func _on_entry_dismissed(entry: Dictionary) -> void:
	_entries.erase(entry)
	_rebuild()

## Hack alerts tell the player to run the scanner, so opening Settings clears them too
func _belongs_to(entry: Dictionary, main_app: GameData.App) -> bool:
	if entry.app == GameData.App.HACK:
		return main_app == GameData.App.SETTINGS
	return entry.app == main_app
#endregion LIST

#region ANIMATION
func _slide_to(target_y: float) -> void:
	_kill_tween()
	sheet.visible = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_sheet_y, sheet.position.y, target_y, SLIDE_DURATION)
	if target_y < 0.0:
		_tween.tween_callback(_finish_close)

func _finish_close() -> void:
	is_open = false
	sheet.visible = false
	_set_sheet_y(-size.y)

## Moves the sheet and brings the tab along, every sheet move must go through here
func _set_sheet_y(sheet_y: float) -> void:
	sheet.position.y = sheet_y
	_sync_handle()

## Keeps the tab glued to the sheet's bottom edge, flipping it as the sheet slides down
func _sync_handle() -> void:
	# 0 = closed, 1 = fully open
	var progress: float = 0.0
	if sheet.visible and size.y > 0.0:
		progress = clampf(1.0 + sheet.position.y / size.y, 0.0, 1.0)

	var handle_height: float = lerpf(HANDLE_HEIGHT_CLOSED, HANDLE_HEIGHT_OPEN, progress)
	# The strip is anchored to the top edge, so its offsets are its top and bottom in pixels
	pull_handle.offset_top = progress * (size.y - handle_height)
	pull_handle.offset_bottom = pull_handle.offset_top + handle_height

	pull_tab.pivot_offset = pull_tab.size / 2.0
	pull_tab.position.y = progress * (handle_height - pull_tab.size.y)
	pull_tab.scale.y = cos(progress * PI)

func _on_resized() -> void:
	if sheet.visible:
		_sync_handle()
	else:
		_set_sheet_y(-size.y)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
#endregion ANIMATION
