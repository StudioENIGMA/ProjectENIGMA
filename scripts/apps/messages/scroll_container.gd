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

func scroll_to_bottom() -> void:
	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		print("Error: Could not find the vertical scroll bar.")
		return

	var target_scroll = v_scroll_bar.max_value

	# Only one animation may drive the scroll at a time
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()

	# A Tween animates a property of an object over time.
	_scroll_tween = create_tween()

	_scroll_tween.tween_property(
		self,                          # The object to animate (this node)
		"scroll_vertical",             # The property to animate
		target_scroll,                 # The final value
		scroll_duration                # The duration of the animation
	).set_trans(transition_type).set_ease(ease_type)

	# The tween will start automatically and free itself when finished.

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

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()

	scroll_vertical = int(v_scroll_bar.max_value)

## Tells whether the view is close enough to the end of the content
##
## threshold: How far from the end still counts as being at the bottom, in pixels
func is_at_bottom(threshold: float = -1.0) -> bool:
	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		return false

	var distance_to_bottom = v_scroll_bar.max_value - v_scroll_bar.page - v_scroll_bar.value
	return distance_to_bottom <= (bottom_threshold if threshold < 0.0 else threshold)
