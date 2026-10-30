class_name DiscrepancyLink
extends Control
## The line tying the rule picked to the section pointed at, like the inspector of Papers, Please
##
## Once a section is picked, a line shoots from the rule's number badge to the section, the
## section is boxed with a punch and a "DISCREPÂNCIA" tag pops over the line. The ends are handed
## over every frame, so the link follows the section while the screen scrolls.

const SHOOT_SECONDS := 0.2
const PUNCH_SECONDS := 0.35
const LINE_WIDTH := 2.5
const TAG_TEXT := "DISCREPÂNCIA"
const TAG_FONT_SIZE := 10
const TAG_PADDING := Vector2(8, 3)

@export var accent := Color(0.92156863, 0.039215688, 0.27058825)
@export var ink := Color(1, 1, 0.972549)
@export var tag_font: Font

## How much of the line is drawn, from the badge to the section (0 to 1)
var _shoot := 0.0
## How far the punch on the section and the tag has gone (0 to 1)
var _punch := 0.0
## Where the line starts and the box of the section, in local coordinates
var _from_rect := Rect2()
var _to_rect := Rect2()
var _to_radius := 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false


## Shoots the line again from the badge to the section, for a section just picked
func play() -> void:
	visible = true
	if _tween:
		_tween.kill()
	_shoot = 0.0
	_punch = 0.0
	_tween = create_tween()
	_tween.tween_method(_set_shoot, 0.0, 1.0, SHOOT_SECONDS).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_punch, 0.0, 1.0, PUNCH_SECONDS)


## Takes the link away at once
func clear() -> void:
	if _tween:
		_tween.kill()
	visible = false


## Moves the ends of the link, in canvas coordinates
##
## from_rect: The rule's number badge
## to_rect: The section lit, empty when it is scrolled out of sight
## to_radius: Corner radius of the section's box
func set_ends(from_rect: Rect2, to_rect: Rect2, to_radius: float) -> void:
	var origin := get_global_rect().position
	_from_rect = Rect2(from_rect.position - origin, from_rect.size)
	_to_rect = Rect2(to_rect.position - origin, to_rect.size)
	_to_radius = to_radius
	queue_redraw()


func _draw() -> void:
	if _to_rect.size.x <= 0.0 or _to_rect.size.y <= 0.0:
		return

	var start := _from_rect.get_center()
	var box := _to_rect
	var end := _closest_point(box, start)
	var tip := start.lerp(end, _shoot)

	# The badge circled, then the line, with a light edge so it reads over the dim
	var badge_radius := _from_rect.size.x / 2.0 + 3.0
	draw_arc(start, badge_radius, 0.0, TAU, 32, accent, LINE_WIDTH, true)
	var line_start := start + (tip - start).limit_length(badge_radius)
	if tip.distance_to(start) > badge_radius:
		draw_line(line_start, tip, Color(ink, 0.7), LINE_WIDTH + 2.0, true)
		draw_line(line_start, tip, accent, LINE_WIDTH, true)
	if _shoot < 1.0:
		return

	# The section boxed with a punch: the box shrinks onto it as it fades in
	var punch_ease := 1.0 - pow(1.0 - _punch, 3.0)
	var grow := (1.0 - punch_ease) * 10.0
	var style := StyleBoxFlat.new()
	# A crimson flash over the section, fading as the box lands
	style.bg_color = Color(accent, 0.18 * (1.0 - punch_ease))
	style.draw_center = true
	style.set_border_width_all(int(LINE_WIDTH + 0.5))
	style.border_color = Color(accent, punch_ease)
	style.set_corner_radius_all(int(_to_radius))
	style.corner_detail = 8
	draw_style_box(style, box.grow(grow))
	draw_circle(end, 3.5, accent)

	_draw_tag(start.lerp(end, 0.5), punch_ease)


## Draws the "DISCREPÂNCIA" tag over the middle of the line, popping in with an overshoot
func _draw_tag(center: Vector2, amount: float) -> void:
	if tag_font == null:
		return
	var pop := amount * (1.0 + sin(amount * PI) * 0.25)
	if pop <= 0.0:
		return
	var text_size := tag_font.get_string_size(
		TAG_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT_SIZE
	)
	var tag_size := text_size + TAG_PADDING * 2.0
	# Kept inside the overlay so a line running along an edge does not cut it off
	var half := tag_size / 2.0
	center = center.clamp(half, (size - half).max(half))

	var style := StyleBoxFlat.new()
	style.bg_color = accent
	style.set_corner_radius_all(100)
	style.corner_detail = 8
	draw_set_transform(center, -0.06, Vector2.ONE * pop)
	draw_style_box(style, Rect2(-half, tag_size))
	draw_string(
		tag_font,
		Vector2(-text_size.x / 2.0, tag_font.get_ascent(TAG_FONT_SIZE) - text_size.y / 2.0),
		TAG_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT_SIZE, ink
	)
	draw_set_transform(Vector2.ZERO)


## Point on the edge of the rect closest to the point, for the line to stop at the box
func _closest_point(rect: Rect2, point: Vector2) -> Vector2:
	var inside := point.clamp(rect.position, rect.end)
	if inside != point:
		return inside
	# The point is inside the rect: go out through the nearest edge
	var to_top := point.y - rect.position.y
	var to_bottom := rect.end.y - point.y
	return Vector2(point.x, rect.position.y if to_top < to_bottom else rect.end.y)


func _set_shoot(value: float) -> void:
	_shoot = value
	queue_redraw()


func _set_punch(value: float) -> void:
	_punch = value
	queue_redraw()
