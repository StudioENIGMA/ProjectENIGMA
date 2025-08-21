# Attach this script directly to your ScrollContainer node.

extends ScrollContainer

# The duration of the scroll animation in seconds.
@export var scroll_duration: float = 0.5

# The type of easing to use for the animation.
# This makes the animation feel more natural.
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

func scroll_to_bottom() -> void:
	var v_scroll_bar = get_v_scroll_bar()
	if not v_scroll_bar:
		print("Error: Could not find the vertical scroll bar.")
		return

	var target_scroll = v_scroll_bar.max_value

	# A Tween animates a property of an object over time.
	var tween = create_tween()

	tween.tween_property(
		self,                          # The object to animate (this node)
		"scroll_vertical",             # The property to animate
		target_scroll,                 # The final value
		scroll_duration                # The duration of the animation
	).set_trans(transition_type).set_ease(ease_type)

	# The tween will start automatically and free itself when finished.
