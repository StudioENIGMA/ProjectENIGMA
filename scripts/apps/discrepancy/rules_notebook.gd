class_name RulesNotebook
extends PanelContainer
## The old notepad the rules of the day are written on
##
## Draws a spiral notepad page behind the rules list: ruled lines locked to the list, so they
## scroll with it, the red margin and a rusty binding along the top. The aged_paper shader in
## the material yellows and stains the page. The rule rows space their text with
## fit_to_ruling(), so every line of text sits on a ruling.

## Distance between two rulings, the height of a line of text
const LINE_PITCH := 24
## Where the text of a line sits, from the top of its line
const BASELINE := 17
## Width of the column left of the margin line, holding the rule numbers
const MARGIN_WIDTH := 30.0
## Distance between two rings of the binding
const RING_SPACING := 24.0
## Height of the binding band, where the page has no rulings
const BINDING_HEIGHT := 20.0
## Always the same rust on the same ring
const RUST_SEED := 1997

@export var rules_scroll: ScrollContainer
@export var rules_list: Control
## The page itself, drawn here so the pages under it can be drawn first
@export var paper_style: StyleBox
@export var ruling_color := Color(0.22352941, 0.5647059, 0.62352943, 0.24)
@export var margin_color := Color(0.92156863, 0.039215688, 0.27058825, 0.3)
## Body of the rusty wire rings, and the light catching them
@export var ring_color := Color(0.42, 0.22, 0.11, 1)
@export var ring_shine_color := Color(0.78, 0.47, 0.24, 0.9)
## Rust bleeding into the paper around each punched hole
@export var rust_color := Color(0.6, 0.3, 0.12, 0.22)
## Colour of the punched holes the rings go through
@export var hole_color := Color(0.28, 0.18, 0.1, 0.35)


## Spaces a label so each of its lines takes one ruling, with its text sitting on it
##
## The font is swapped for a variation of itself trimmed to LINE_PITCH, so a font with a tall
## line height, like a handwriting one, fits the rulings too.
##
## label: A label of the rules list, with its font and font size already set
static func fit_to_ruling(label: Label) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")

	var trimmed := FontVariation.new()
	trimmed.base_font = font
	trimmed.spacing_top = BASELINE - roundi(font.get_ascent(font_size))
	trimmed.spacing_bottom = (LINE_PITCH - BASELINE) - roundi(font.get_descent(font_size))
	label.add_theme_font_override("font", trimmed)
	label.add_theme_constant_override("line_spacing", 0)


func _ready() -> void:
	rules_scroll.get_v_scroll_bar().value_changed.connect(
		func(_value: float) -> void: queue_redraw()
	)
	rules_list.resized.connect(queue_redraw)
	resized.connect(_on_resized)
	_on_resized()


func _draw() -> void:
	# Two pages peeking out under the one on top
	draw_style_box(paper_style, Rect2(8, 6, size.x - 16, size.y))
	draw_style_box(paper_style, Rect2(4, 3, size.x - 8, size.y))
	draw_style_box(paper_style, Rect2(Vector2.ZERO, size))

	_draw_rulings()
	_draw_binding()


## Horizontal rulings under every line of the list, and the margin line
func _draw_rulings() -> void:
	var list_origin := rules_list.global_position - global_position
	var top := BINDING_HEIGHT
	var bottom := size.y - 4.0

	var first_line := list_origin.y + BASELINE + 1.5
	var y := first_line + ceilf((top - first_line) / LINE_PITCH) * LINE_PITCH
	while y < bottom:
		draw_line(Vector2(1, y), Vector2(size.x - 1, y), ruling_color, 1.0)
		y += LINE_PITCH

	var margin_x := roundf(list_origin.x + MARGIN_WIDTH) + 0.5
	draw_line(Vector2(margin_x, top), Vector2(margin_x, size.y - 1), margin_color, 1.0)


## Punched holes along the top of the page, a rusty wire ring through each
func _draw_binding() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RUST_SEED

	var count := floori((size.x - RING_SPACING) / RING_SPACING)
	var start := (size.x - (count - 1) * RING_SPACING) / 2.0
	for index in count:
		var x := start + index * RING_SPACING
		var hole := Vector2(x, 10)

		# Rust bled into the paper around the hole, more on some rings than others
		for stain in rng.randi_range(1, 3):
			var offset := Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(0.0, 5.0))
			draw_circle(hole + offset, rng.randf_range(3.0, 6.5), rust_color)
		draw_circle(hole, 4.0, hole_color)

		# The wire, a lighter streak where the light catches it and a few flakes of rust
		var lean := rng.randf_range(-0.6, 0.6)
		var wire_top := Vector2(x + lean, -6)
		draw_line(hole, wire_top, ring_color, 2.75, true)
		draw_line(hole + Vector2(-0.6, -2), wire_top + Vector2(-0.6, 2), ring_shine_color, 0.9, true)
		draw_circle(wire_top, 1.4, ring_color)
		for flake in rng.randi_range(0, 2):
			var along := rng.randf_range(0.2, 0.9)
			draw_circle(hole.lerp(wire_top, along), rng.randf_range(0.8, 1.4), ring_color.darkened(0.3))


func _on_resized() -> void:
	var paper_material := material as ShaderMaterial
	if paper_material:
		paper_material.set_shader_parameter("page_size", size)
	queue_redraw()
