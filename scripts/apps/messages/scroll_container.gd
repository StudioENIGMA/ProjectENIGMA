# Attach this script directly to your ScrollContainer node.
@tool
extends "res://scripts/tools/thin_scroll.gd"

# The duration of the scroll animation in seconds.
@export var scroll_duration: float = 0.5

# The type of easing to use for the animation.
# This makes the animation feel more natural.
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

# How far from the end the view still counts as "following the conversation", in pixels.
@export var bottom_threshold: float = 24.0

var _scroll_tween: Tween
## Whether an animation is currently carrying the view to the end of the content
var _is_following: bool = false

func _ready() -> void:
	super()

	# Listening to the signal keeps the scrolling the container does on its own
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)

## Animates the view to the end of the content
##
## Waits a couple of frames so the containers already account for the content
## added, and follows the end of the content while it animates, so a bubble that
## only reaches its final height later is still fully shown.
func scroll_to_bottom() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		print("Error: Could not find the vertical scroll bar.")
		return

	# Only one animation may drive the scroll at a time
	_stop_following()

	_is_following = true

	# A Tween animates a value over time, here the progress of the trip to the end
	_scroll_tween = create_tween()

	_scroll_tween.tween_method(
		_scroll_towards_bottom.bind(float(scroll_vertical)), # Where the trip started
		0.0,                                                 # Progress at the start
		1.0,                                                 # Progress at the end
		scroll_duration                                      # Duration of the animation
	).set_trans(transition_type).set_ease(ease_type)

	_scroll_tween.finished.connect(func() -> void: _is_following = false)

## Moves straight to the end of the content, without animating
##
## Waits a couple of frames so the containers already account for the content
## added, and for the bars that may have taken room from the view.
func jump_to_bottom() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		return

	_stop_following()

	scroll_vertical = int(v_scroll_bar.max_value)

## Tells whether the view is close enough to the end of the content
##
## A view being carried to the end by an animation counts as being there, so
## content that arrives while it runs keeps being followed.
##
## threshold: How far from the end still counts as being at the bottom, in pixels
func is_at_bottom(threshold: float = -1.0) -> bool:
	if _is_following:
		return true

	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		return false

	var distance_to_bottom = v_scroll_bar.max_value - v_scroll_bar.page - v_scroll_bar.value
	return distance_to_bottom <= (bottom_threshold if threshold < 0.0 else threshold)

## Places the view along the trip to the end of the content
##
## The end is read on every step instead of when the animation starts, so
## content that grows meanwhile does not leave the view short of the end.
##
## weight: How far along the trip the view is, from 0.0 to 1.0
## start_scroll: The position the view had when the trip started
func _scroll_towards_bottom(weight: float, start_scroll: float) -> void:
	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		return

	var target_scroll = maxf(v_scroll_bar.max_value - v_scroll_bar.page, 0.0)
	scroll_vertical = int(lerpf(start_scroll, target_scroll, weight))

## Cancels the animation that follows the end of the content when the reader
## takes the view over
##
## event: The input the container received
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventPanGesture:
		_stop_following()
		return

	# Taps and clicks on the messages leave the view alone, only the wheel moves it
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_stop_following()

## Drops the animation that follows the end of the content, if there is one
func _stop_following() -> void:
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()

	_is_following = false
