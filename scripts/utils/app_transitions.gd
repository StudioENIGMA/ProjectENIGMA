class_name AppTransitions
extends RefCounted
## Opening and closing animations for the phone window and the apps inside it
##
## Three movements, one per situation:
## - the window itself grows out of (and shrinks back into) the home screen icon that was tapped
## - an app opened while the window is already open is pushed in from the right, already at full
##   size, while the screen it replaces leaves to the left in step with it (and back on the way out)
## - an overlay that does not replace the screen under it (the hack minigames) grows in place

#region ANIMATION SETTINGS
## Duration (in seconds) of the window growing out of / shrinking back into its icon
const WINDOW_OPEN_DURATION: float = 0.42
const WINDOW_CLOSE_DURATION: float = 0.32

## Duration (in seconds)  of an app sliding in from / out to the right
const PUSH_DURATION: float = 0.36
const POP_DURATION: float = 0.32

## Duration (in seconds) of an overlay growing/shrinking in place
const OVERLAY_OPEN_DURATION: float = 0.42
const OVERLAY_CLOSE_DURATION: float = 0.32

## Scale a node starts/ends at when it has no icon or screen edge to grow out of
const IN_PLACE_START_SCALE: float = 0.85
const IN_PLACE_END_SCALE: float = 0.9

## The fade is a short accent, not the whole movement: it is over well before the scale is,
## so nothing ever lingers half transparent while it is still growing/shrinking
const FADE_DURATION: float = 0.14

## Opacity a growing node starts from
const OPEN_START_ALPHA: float = 0.0

## Corner radius (on screen, in pixels) the window has while it is still the size of its icon
const ICON_CORNER_RADIUS: float = 14.0

## Same color as the BaseBackgroundColor node, used to fill the rounded window while it animates
const WINDOW_BACKGROUND_COLOR: Color = Color(1, 1, 0.972549, 1)
#endregion ANIMATION SETTINGS

## Tells whether an app node is (still) open, so an app reopened while its closing animation was
## still playing does not get hidden by it. Set by the owner of this object
var is_node_open: Callable = Callable()

## The phone window every animation happens in (and the node the tweens are created on)
var _window: Control

## Home screen icon grid, searched for the icon the window should grow out of
var _apps_root: Control

## Running transitions, keyed by the animated node
var _tweens: Dictionary = {}

## Transitions built this frame and held back until the next one, see _begin()
var _held_tweens: Array = []

## Position each node sits at when it is not being animated, keyed by the node
var _base_positions: Dictionary = {}

## Mouse filters saved while a closing node is still on screen, keyed by the animated node
var _saved_mouse_filters: Dictionary = {}

## What to clean up once a transition ends, keyed by the animated node
##
## Each entry is {"hide": Array, "settle": Array, "guard": bool}: the nodes in "hide" are put away
## with the transition, the ones in "settle" only get their transform back, and "guard" spares a
## node that was reopened while the transition was still playing
var _pending: Dictionary = {}

## Corner radius, in screen pixels, of the window while it grows out of (or back into) its icon
var _visual_corner_radius: float = 0.0

## Rounded rect the window is clipped to while animating (only redrawn, never re-created)
var _window_style_box: StyleBoxFlat = StyleBoxFlat.new()

func _init(window:Control, apps_root:Control) -> void:
	_window = window
	_apps_root = apps_root

#region WINDOW
## Grows the whole window out of the home screen icon of main_app, fading it in on the way
##
## Apps with no icon on screen (the hack minigames) grow from the window center instead
func open_window(main_app:GameData.App) -> void:
	var origin:Rect2 = _get_icon_rect(main_app)

	_kill_transition(_window)

	_window.scale = Vector2.ONE
	_window.pivot_offset = _get_growth_pivot(_window, origin)
	_window.scale = Vector2.ONE * _get_growth_scale(_window, origin)
	_window.modulate.a = OPEN_START_ALPHA

	var tween:Tween = _window.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_window, "scale", Vector2.ONE, WINDOW_OPEN_DURATION)
	# Opaque early on, so only the scale is still easing for most of the animation
	tween.tween_property(_window, "modulate:a", 1.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	# The window starts as rounded as the icon it comes from and squares off as it grows
	_tween_corner_radius(tween, ICON_CORNER_RADIUS, 0.0, WINDOW_OPEN_DURATION)
	tween.finished.connect(_on_opening_finished.bind(_window))

	_begin(_window, tween)

## Shrinks the whole window back into the home screen icon of main_app
##
## Every node in also_hide (the apps that were on screen inside it) is hidden once it is gone
func close_window(main_app:GameData.App, also_hide:Array = []) -> void:
	var origin:Rect2 = _get_icon_rect(main_app)

	_kill_transition(_window)
	# An app reopened while the window is still shrinking must not be hidden by this animation
	_pending[_window] = {"hide": also_hide, "settle": [], "guard": true}

	if not _window.visible:
		_on_closing_finished(_window)
		return

	# The window is still on screen while it fades out, but must not react to clicks anymore
	_disable_subtree_input(_window)

	_window.scale = Vector2.ONE
	_window.pivot_offset = _get_growth_pivot(_window, origin)
	_window.modulate.a = 1.0

	var end_scale:float = _get_growth_scale(_window, origin)
	if origin.size == Vector2.ZERO:
		end_scale = IN_PLACE_END_SCALE

	var tween:Tween = _window.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_window, "scale", Vector2.ONE * end_scale, WINDOW_CLOSE_DURATION)
	# Stays solid while it shrinks and only fades on the way out
	tween.tween_property(_window, "modulate:a", 0.0, FADE_DURATION).set_trans(
		Tween.TRANS_SINE
	).set_delay(WINDOW_CLOSE_DURATION - FADE_DURATION)
	# Rounds back off on the way out, ending as rounded as the icon it shrinks into
	_tween_corner_radius(tween, 0.0, ICON_CORNER_RADIUS, WINDOW_CLOSE_DURATION)
	tween.finished.connect(_on_closing_finished.bind(_window))

	_begin(_window, tween)

## Tells whether the window itself is currently growing in or shrinking out
func is_window_animating() -> bool:
	var tween = _tweens.get(_window)
	return tween != null and tween.is_valid()
#endregion WINDOW

#region APPS
## Slides an app in from the right at full size, pushing the screens it replaces out to the left
##
## The two move in step so they never overlap: app screens are transparent and would otherwise
## show through each other. The replaced screens are hidden once they are off screen
func push_app(node:Control, replaced:Array = []) -> void:
	_kill_transition(node)
	_pending[node] = {"hide": replaced, "settle": [], "guard": false}

	# While the window itself is growing in, a screen sliding across it reads as two competing
	# movements: the window animation is the one that should carry it
	if is_window_animating():
		_settle(node)
		_flush_pending(node)
		return

	var distance:float = _get_slide_distance(node)
	var destination:Vector2 = _get_base_position(node)
	node.scale = Vector2.ONE
	node.modulate.a = 1.0
	node.position = destination + Vector2(distance, 0.0)

	var tween:Tween = node.create_tween()
	tween.set_parallel(true)
	# Sine eases in and out of the slide without the long crawling tail a cubic ease out leaves,
	# which is what made the movement look like it stepped to a halt
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position", destination, PUSH_DURATION)

	for leaving in replaced:
		if not is_instance_valid(leaving) or not leaving.visible:
			continue
		_kill_transition(leaving)
		var leaving_origin:Vector2 = _get_base_position(leaving)
		leaving.scale = Vector2.ONE
		leaving.modulate.a = 1.0
		leaving.position = leaving_origin
		tween.tween_property(
			leaving, "position", leaving_origin - Vector2(distance, 0.0), PUSH_DURATION
		)

	tween.finished.connect(_on_opening_finished.bind(node))

	_begin(node, tween)

## Slides an app back out to the right, bringing the screen it had covered back in from the left
func pop_app(node:Control, uncovered:Control = null) -> void:
	_kill_transition(node)
	_pending[node] = {"hide": [], "settle": [], "guard": false}

	if not node.visible:
		_on_closing_finished(node)
		return

	# The app is still on screen while it slides away, but must not react to clicks anymore
	_disable_subtree_input(node)

	var distance:float = _get_slide_distance(node)
	var origin:Vector2 = _get_base_position(node)
	node.scale = Vector2.ONE
	node.modulate.a = 1.0
	node.position = origin

	var tween:Tween = node.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position", origin + Vector2(distance, 0.0), POP_DURATION)

	if uncovered != null and is_instance_valid(uncovered):
		_kill_transition(uncovered)
		var uncovered_destination:Vector2 = _get_base_position(uncovered)
		uncovered.scale = Vector2.ONE
		uncovered.modulate.a = 1.0
		uncovered.position = uncovered_destination - Vector2(distance, 0.0)
		uncovered.visible = true
		tween.tween_property(uncovered, "position", uncovered_destination, POP_DURATION)
		_pending[node]["settle"].append(uncovered)

	tween.finished.connect(_on_closing_finished.bind(node))

	_begin(node, tween)

## Grows an overlay in place over the screen below, which stays where it is (the hack minigames)
func reveal_app(node:Control) -> void:
	_kill_transition(node)

	node.position = _get_base_position(node)
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE * IN_PLACE_START_SCALE
	node.modulate.a = OPEN_START_ALPHA

	var tween:Tween = node.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, OVERLAY_OPEN_DURATION)
	tween.tween_property(node, "modulate:a", 1.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_on_opening_finished.bind(node))

	_begin(node, tween)

## Shrinks an overlay away in place, uncovering the screen that was below it all along
func conceal_app(node:Control) -> void:
	_kill_transition(node)
	_pending[node] = {"hide": [], "settle": [], "guard": false}

	if not node.visible:
		_on_closing_finished(node)
		return

	_disable_subtree_input(node)

	node.position = _get_base_position(node)
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE
	node.modulate.a = 1.0

	var tween:Tween = node.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * IN_PLACE_END_SCALE, OVERLAY_CLOSE_DURATION)
	tween.tween_property(node, "modulate:a", 0.0, FADE_DURATION).set_trans(
		Tween.TRANS_SINE
	).set_delay(OVERLAY_CLOSE_DURATION - FADE_DURATION)
	tween.finished.connect(_on_closing_finished.bind(node))

	_begin(node, tween)
#endregion APPS

#region DRAWING
## Draws the rounded rect the window children are clipped to while it grows out of its icon
##
## Must be called from the window own _draw(); does nothing while no window animation is running
func draw_window() -> void:
	if _window.clip_children == CanvasItem.CLIP_CHILDREN_DISABLED:
		return

	# The radius is asked for in screen pixels, but drawing happens before the node is scaled
	var local_radius:float = _visual_corner_radius / maxf(_window.scale.x, 0.01)
	local_radius = minf(local_radius, minf(_window.size.x, _window.size.y) / 2.0)

	_window_style_box.bg_color = WINDOW_BACKGROUND_COLOR
	_window_style_box.set_corner_radius_all(int(round(local_radius)))
	_window.draw_style_box(_window_style_box, Rect2(Vector2.ZERO, _window.size))

## Clips the window to a rounded rect and animates that radius along with the given tween
func _tween_corner_radius(tween:Tween, from:float, to:float, duration:float) -> void:
	_visual_corner_radius = from
	# Clipping is only paid for while the animation runs, the window is square the rest of the time
	_window.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_window.queue_redraw()
	tween.tween_method(_set_visual_corner_radius, from, to, duration)

func _set_visual_corner_radius(radius:float) -> void:
	_visual_corner_radius = radius
	_window.queue_redraw()

## Gives the window back its square corners and stops clipping its children
func _stop_corner_clipping() -> void:
	_visual_corner_radius = 0.0
	_window.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	_window.queue_redraw()
#endregion DRAWING

#region TRANSITION BOOKKEEPING
## Registers a transition and lets it start on the next frame rather than on this one
##
## Opening an app builds its content first (list rows, whole scenes instanced into containers) and
## the containers only lay that out at the end of the frame. Started right away, the first step of
## the tween would swallow that spike and the movement would begin part way in, which is what made
## it look like it stuttered out of the gate
func _begin(node:Control, tween:Tween) -> void:
	_tweens[node] = tween

	if not _window.is_inside_tree():
		return

	tween.pause()
	_held_tweens.append(tween)

	# One connection for every transition held this frame: a per tween callable would collide with
	# itself when two of them start in the same frame, and the second one would never be resumed
	var tree:SceneTree = _window.get_tree()
	if not tree.process_frame.is_connected(_resume_held_transitions):
		tree.process_frame.connect(_resume_held_transitions, CONNECT_ONE_SHOT)

## Starts the transitions held back by _begin(), skipping the ones killed in the meantime
func _resume_held_transitions() -> void:
	var held:Array = _held_tweens
	_held_tweens = []
	for tween in held:
		if tween.is_valid():
			tween.play()

## Stops the animation currently running on the given node, if any
func _kill_transition(node:Control) -> void:
	var tween = _tweens.get(node)
	if tween != null and tween.is_valid():
		tween.kill()
	_tweens.erase(node)
	_restore_subtree_input(node)
	if node == _window:
		_stop_corner_clipping()
	# The interrupted animation will not put anything away anymore, so do it right away
	_flush_pending(node)

func _on_opening_finished(node:Control) -> void:
	_tweens.erase(node)
	_settle(node)
	_flush_pending(node)

func _on_closing_finished(node:Control) -> void:
	_tweens.erase(node)
	_restore_subtree_input(node)

	# The node may have been reopened while the animation was still playing
	if not _is_node_open(node):
		node.visible = false

	_settle(node)
	_flush_pending(node)

## Puts the node back where (and how) it sits when nothing is animating it
func _settle(node:Control) -> void:
	node.scale = Vector2.ONE
	node.modulate.a = 1.0
	node.position = _get_base_position(node)
	if node == _window:
		_stop_corner_clipping()

## Puts away (or just straightens out) the nodes that were waiting for the transition to end
func _flush_pending(node:Control) -> void:
	var pending:Dictionary = _pending.get(node, {})
	_pending.erase(node)

	for hidden_node in pending.get("hide", []):
		if not is_instance_valid(hidden_node):
			continue
		if not pending["guard"] or not _is_node_open(hidden_node):
			hidden_node.visible = false
		_settle(hidden_node)

	for settled_node in pending.get("settle", []):
		if is_instance_valid(settled_node):
			_settle(settled_node)

func _is_node_open(node:Control) -> bool:
	if not is_node_open.is_valid():
		return false
	return is_node_open.call(node)
#endregion TRANSITION BOOKKEEPING

#region GEOMETRY
## Position the node sits at while nothing animates it, remembered the first time it is touched
func _get_base_position(node:Control) -> Vector2:
	if not _base_positions.has(node):
		_base_positions[node] = node.position
	return _base_positions[node]

## How far to the right an app starts from (or ends at): its own width, so it starts off screen
func _get_slide_distance(node:Control) -> float:
	if node.size.x > 0.0:
		return node.size.x
	return _window.size.x

## Point (in node coordinates) the window grows out of: the center of origin, or its own center
func _get_growth_pivot(node:Control, origin:Rect2) -> Vector2:
	if origin.size == Vector2.ZERO:
		return node.size / 2.0
	return origin.get_center() - node.global_position

## Scale at which the window matches the size of origin, so it starts/ends as big as its icon
func _get_growth_scale(node:Control, origin:Rect2) -> float:
	if origin.size == Vector2.ZERO or node.size.x <= 0.0:
		return IN_PLACE_START_SCALE
	return clampf(origin.size.x / node.size.x, 0.05, 1.0)

## Global rect of the home screen icon of the given app, empty when it has none on screen
func _get_icon_rect(main_app:GameData.App) -> Rect2:
	for child in _apps_root.get_children():
		if child is not Control or not child.visible:
			continue

		var child_app = child.get("app")
		if child_app == null or child_app != main_app:
			continue

		var icon = child.get("app_icon")
		if icon is Control:
			return icon.get_global_rect()
		return child.get_global_rect()
	return Rect2()
#endregion GEOMETRY

#region INPUT
## Makes the whole subtree ignore the mouse, remembering each filter so it can be restored
func _disable_subtree_input(node:Control) -> void:
	if _saved_mouse_filters.has(node):
		return

	# Only one node leaves at a time, so give back any pending filter before saving new ones
	# (otherwise a subtree being disabled twice would be saved as already ignoring the mouse)
	for pending_node in _saved_mouse_filters.keys():
		_restore_subtree_input(pending_node)

	var saved:Dictionary = {}
	var pending:Array = [node]
	while not pending.is_empty():
		var current:Node = pending.pop_back()
		if current is Control:
			saved[current] = current.mouse_filter
			current.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pending.append_array(current.get_children())

	_saved_mouse_filters[node] = saved

## Gives back the mouse filters saved by _disable_subtree_input()
func _restore_subtree_input(node:Control) -> void:
	var saved:Dictionary = _saved_mouse_filters.get(node, {})
	for control in saved:
		if is_instance_valid(control):
			control.mouse_filter = saved[control]
	_saved_mouse_filters.erase(node)
#endregion INPUT
