class_name DiscrepancyTarget
extends Control
## Lets the player point at the section it covers as the one that gives a scam away
##
## Placed as the last child of a PanelContainer or MarginContainer, it is fitted over the
## section and drawn on top of it. Inside a PanelContainer its outline grows past the panel's
## content margins, so it hugs the panel itself and follows its rounded corners. The screen
## that owns it arms it while the player points at a section and marks it selected once it is
## picked. While armed, the dimmed screen is lit over it only when it is lit (hovered, pressed
## or selected); the discrepancy overlay draws the discreet outline of the others.

## Emitted when the player taps the section while it is armed
signal picked(target: DiscrepancyTarget)

## How far the pointer may travel between press and release to count as a tap, in pixels
const TAP_SLOP := 10.0
const BADGE_RADIUS := 9.0
## Room left around the outline when the section is lit through the dimmed screen
const SPOTLIGHT_MARGIN := 4.0

## Color of the outline and of the badge of the selected section
@export var accent := Color(0.92156863, 0.039215688, 0.27058825)
## Color of the "!" drawn in the badge of the selected section
@export var badge_ink := Color(1, 1, 0.972549)
## Room left around the section, past the parent panel's content margins (x: sides, y: top/bottom)
@export var padding := Vector2.ZERO
## Corner radius used when the parent is not a rounded panel
@export var corner_radius := 12

## What was pointed at (source, section, excerpt...), handed over with the report
var section: Dictionary = {}
var armed := false: set = set_armed
var selected := false: set = set_selected

var _style := StyleBoxFlat.new()
var _is_hovered := false
## Where the pointer went down, in viewport coordinates, or null while nothing is pressed
var _press_position = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_style.corner_detail = 8
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


## Makes the section tappable, or puts it back to normal
func set_armed(is_armed: bool) -> void:
	armed = is_armed
	# Taps pass through to the scroll container, so the player can still scroll while inspecting
	mouse_filter = MOUSE_FILTER_PASS if armed else MOUSE_FILTER_IGNORE
	_press_position = null
	_is_hovered = false
	if not armed:
		selected = false
	queue_redraw()


## Marks the section as the one the player is reporting
func set_selected(is_selected: bool) -> void:
	selected = is_selected
	queue_redraw()


## Whether the section is shown bright through the dimmed screen: hovered, pressed or selected
func is_lit() -> bool:
	return armed and (selected or _is_hovered or _press_position != null)


## Where the section is lit while the rest of the screen is dimmed, in canvas coordinates
##
## The outline grown a little, cut to what the scroll containers holding it let be seen.
## Empty when the section is scrolled out of sight.
func get_spotlight_rect() -> Rect2:
	var outline := _outline_rect().grow(SPOTLIGHT_MARGIN)
	var xform := get_global_transform()
	var rect := Rect2(xform * outline.position, xform.basis_xform(outline.size))

	var ancestor := get_parent()
	while ancestor:
		if ancestor is Control and ancestor.clip_contents:
			rect = rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return rect


## Corner radius of the lit area, following the outline's corners
func get_spotlight_corner_radius() -> float:
	_apply_corners()
	return _style.corner_radius_top_left + SPOTLIGHT_MARGIN


func _gui_input(event: InputEvent) -> void:
	if not armed:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		_press_position = event.global_position
		queue_redraw()
		return

	if _press_position == null:
		return

	# Compared in viewport coordinates, a drag that scrolled the section along is not a tap
	var is_tap: bool = event.global_position.distance_to(_press_position) <= TAP_SLOP
	_press_position = null
	queue_redraw()
	if is_tap:
		accept_event()
		picked.emit(self)


func _has_point(point: Vector2) -> bool:
	return _outline_rect().has_point(point)


func _draw() -> void:
	if not is_lit():
		return

	var rect := _outline_rect()
	_apply_corners()

	if selected:
		_style.bg_color = Color(accent, 0.1)
		_style.border_color = accent
	else:
		_style.bg_color = Color(accent, 0.05)
		_style.border_color = Color(accent, 0.55)
	_style.set_border_width_all(2)
	draw_style_box(_style, rect)

	if selected:
		_draw_badge(Vector2(rect.end.x - 5.0, rect.position.y + 5.0))


## Draws the "!" badge pinned to the top right corner of the selected section
func _draw_badge(center: Vector2) -> void:
	draw_circle(center, BADGE_RADIUS + 1.5, badge_ink)
	draw_circle(center, BADGE_RADIUS, accent)
	draw_line(center + Vector2(0, -4.5), center + Vector2(0, 1.5), badge_ink, 2.2, true)
	draw_circle(center + Vector2(0, 4.5), 1.3, badge_ink)


## Rect of the outline, in local coordinates: the section plus the parent panel's content margins
func _outline_rect() -> Rect2:
	var margins := Vector4.ZERO
	var parent_style := _parent_style()
	if parent_style:
		margins = Vector4(
			parent_style.get_margin(SIDE_LEFT),
			parent_style.get_margin(SIDE_TOP),
			parent_style.get_margin(SIDE_RIGHT),
			parent_style.get_margin(SIDE_BOTTOM)
		)

	return Rect2(Vector2.ZERO, size).grow_individual(
		margins.x + padding.x,
		margins.y + padding.y,
		margins.z + padding.x,
		margins.w + padding.y
	)


## Rounds the outline like the parent panel, or with corner_radius when it is not rounded
func _apply_corners() -> void:
	var parent_style := _parent_style() as StyleBoxFlat
	if parent_style == null:
		_style.set_corner_radius_all(corner_radius)
		return

	var grow := int(maxf(padding.x, padding.y))
	_style.corner_radius_top_left = parent_style.corner_radius_top_left + grow
	_style.corner_radius_top_right = parent_style.corner_radius_top_right + grow
	_style.corner_radius_bottom_right = parent_style.corner_radius_bottom_right + grow
	_style.corner_radius_bottom_left = parent_style.corner_radius_bottom_left + grow


## Style of the parent panel, or null when the target does not sit in a PanelContainer
func _parent_style() -> StyleBox:
	var parent := get_parent()
	if parent is PanelContainer:
		return parent.get_theme_stylebox("panel")
	return null


func _set_hovered(is_hovered: bool) -> void:
	_is_hovered = is_hovered and armed
	queue_redraw()
