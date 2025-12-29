# res://scripts/apps/messages/message_instance.gd
extends HBoxContainer

enum Align { LEFT, RIGHT }

const MAX_BUBBLE_WIDTH := 650.0

@export var align: Align = Align.RIGHT

@export var label: Label
@export var panel_container: PanelContainer

# Optional: allow the same script to support both scenes cleanly
@export var left_margin: MarginContainer
@export var right_margin: MarginContainer
@export var annex_container: CenterContainer

var _is_reflowing := false


func _ready() -> void:
	resized.connect(_reflow)
	var vp := get_viewport()
	if vp:
		vp.size_changed.connect(_reflow)
	call_deferred("_reflow")


func setup(message: String, annex: Dictionary) -> void:
	if label:
		label.text = message
	_apply_annex(annex)
	_reflow()


func _apply_annex(annex: Dictionary) -> void:
	if annex_container:
		annex_container.visible = not annex.is_empty()


func _reflow() -> void:
	if _is_reflowing:
		return
	if not is_inside_tree() or not label or not panel_container:
		return

	_is_reflowing = true

	_apply_alignment_flags()

	var max_width := _compute_max_bubble_width()
	var padding_x := _get_panel_horizontal_padding(panel_container)

	var natural_text_width := _measure_text_width(label.text)
	var natural_bubble_width := natural_text_width + padding_x

	var should_wrap := natural_bubble_width > max_width

	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if should_wrap else TextServer.AUTOWRAP_OFF

	panel_container.custom_minimum_size.x = max_width if should_wrap else natural_bubble_width

	_is_reflowing = false


func _apply_alignment_flags() -> void:
	# Ensure the bubble shrinks instead of filling the row
	panel_container.size_flags_horizontal = (
		Control.SIZE_SHRINK_END if align == Align.RIGHT else Control.SIZE_SHRINK_BEGIN
	)

	label.size_flags_horizontal = Control.SIZE_FILL

	# Ensure the correct spacer expands (scene already does this, but this makes it robust)
	if left_margin:
		left_margin.size_flags_horizontal = (
			(Control.SIZE_EXPAND | Control.SIZE_FILL) if align == Align.RIGHT else 0
		)

	if right_margin:
		right_margin.size_flags_horizontal = (
			(Control.SIZE_EXPAND | Control.SIZE_FILL) if align == Align.LEFT else 0
		)


func _compute_max_bubble_width() -> float:
	var row_width := float(size.x)
	if row_width <= 0.0 and get_parent() is Control:
		row_width = float((get_parent() as Control).size.x)
	if row_width <= 0.0:
		return MAX_BUBBLE_WIDTH

	var reserved_edge := 32.0
	if align == Align.RIGHT and right_margin:
		reserved_edge = max(0.0, right_margin.custom_minimum_size.x)
	elif align == Align.LEFT and left_margin:
		reserved_edge = max(0.0, left_margin.custom_minimum_size.x)

	return min(MAX_BUBBLE_WIDTH, max(0.0, row_width - reserved_edge))


func _get_panel_horizontal_padding(panel: PanelContainer) -> float:
	var sb := panel.get_theme_stylebox("panel")
	if sb == null:
		return 0.0
	return sb.get_content_margin(SIDE_LEFT) + sb.get_content_margin(SIDE_RIGHT)


func _measure_text_width(text: String) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null:
		return label.get_minimum_size().x

	var max_line := 0.0
	for line in text.split("\n", false):
		var sz := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		max_line = max(max_line, sz.x)
	return max_line
