extends Control
## Everything drawn over an app while the player reports a discrepancy
##
## First the rules notepad, to pick the rule of the day the scam breaks. Then the phone is
## dimmed, the sections that can be pointed at only outlined, the one hovered or picked lit,
## with a bar at the bottom naming the rule picked, a line tying that rule to the section
## picked, and a stamp once it is reported. It only shows things: base_app decides when.

## Emitted when the player picks a rule in the notepad and goes on to point at the section
signal rule_chosen(rule: Dictionary)
## Emitted when the player puts the notepad away without picking a rule
signal rules_cancelled()
## Emitted when the player, pointing at the section, goes back to pick another rule
signal rule_change_requested()
## Emitted when the player confirms the report, with a rule and a section picked
signal report_confirmed()

const RULE_ROW = preload("res://scenes/apps/discrepancy/discrepancy_rule_row.tscn")
const RULES_PATH := "res://data/rules/rules.json"
const GROUP_FONT = preload("res://assets/fonts/GloriaHallelujah-Regular.ttf")
## Rules groups of the notepad, in the order they are listed: the "apps" of the rules
const RULES_GROUPS := {
	"MessagesHome": "Mensagens",
	"Email": "Email",
	"Bank": "Banco",
	"browser": "Navegador e lojas",
}
## Stamp colours: a scam found, a report that changed nothing and a wrong report
const STAMP_FOUND_COLOR := Color(0.92156863, 0.039215688, 0.27058825)
const STAMP_NEUTRAL_COLOR := Color(0.13333334, 0.28235295, 0.38431373)
const STAMP_WRONG_COLOR := Color(0.101960786, 0.1254902, 0.2)
## Stamp titles longer than this are written smaller, so they fit the phone
const STAMP_LONG_TITLE := 12
## Height of the bar shown at the bottom while pointing, the screen under it is shrunk by this
const POINT_BAR_HEIGHT := 132.0
const SHEET_SECONDS := 0.28
const DIM_SECONDS := 0.22
const STAMP_HOLD_SECONDS := 0.9

@export var scrim: ColorRect
@export var sheet: Control
@export var rules_scroll: ScrollContainer
@export var rules_list: VBoxContainer
@export var cancel_button: Button
@export var next_button: Button
## Dims the phone, lit only over the section hovered or picked (spotlight shader)
@export var dim: ColorRect
@export var point_bar: Control
@export var point_rule_number: Label
@export var point_rule_badge: Control
@export var point_rule_title: Label
@export var change_rule_button: Button
@export var report_button: Button
## Line from the rule's badge to the section picked
@export var link: DiscrepancyLink
@export var stamp: Control
@export var stamp_label: Label
@export var stamp_sub_label: Label

var _chosen_row: PanelContainer = null
## Id of the rule picked, kept so the notepad opens on it again when the player goes back
var _chosen_rule_id := ""
## Rules group of the screen being reported, the only one whose rules can be picked
var _rules_app := ""
var _is_sheet_open := false
## Returns the targets to light through the dim, while pointing
var _spotlight_source := Callable()
var _sheet_tween: Tween
var _point_tween: Tween
var _stamp_tween: Tween


func _ready() -> void:
	scrim.visible = false
	sheet.visible = false
	dim.visible = false
	point_bar.visible = false
	stamp.visible = false
	point_bar.custom_minimum_size.y = POINT_BAR_HEIGHT
	set_process(false)

	scrim.gui_input.connect(_on_scrim_gui_input)
	cancel_button.pressed.connect(_on_cancel_pressed)
	next_button.pressed.connect(_on_next_pressed)
	change_rule_button.pressed.connect(rule_change_requested.emit)
	report_button.pressed.connect(report_confirmed.emit)


## Slides the rules notepad up, on the rule picked before if the player came back to change it
##
## rules_app: The rules group of the screen being reported ("MessagesHome", "Email", "Bank" or
## "browser"), listed first and the only one whose rules can be picked
func open_rules(rules_app: String = "") -> void:
	_rules_app = rules_app
	_hide_pointing()
	_fill_rules()

	_is_sheet_open = true
	scrim.visible = true
	scrim.modulate.a = 0.0
	sheet.visible = true
	sheet.position.y = size.y

	# Containers are not laid out while hidden, so the labels only measure their real
	# height once the sheet has been visible for a frame
	await get_tree().process_frame
	if not _is_sheet_open:
		return

	# Back to the anchored layout, so the sheet is sized for what it holds now, then offscreen
	sheet.offset_top = 0.0
	sheet.offset_bottom = 0.0
	var rest_y := sheet.position.y
	sheet.position.y = size.y

	_restart_sheet_tween()
	_sheet_tween.tween_property(scrim, "modulate:a", 1.0, SHEET_SECONDS)
	_sheet_tween.tween_property(sheet, "position:y", rest_y, SHEET_SECONDS)


## Dims the phone, lighting only the section hovered or picked, naming the rule picked
##
## spotlight_source: Returns the DiscrepancyTarget nodes to light, asked again every frame so
## sections that scroll or arrive meanwhile are lit too
func start_pointing(spotlight_source: Callable) -> void:
	_close_sheet()
	_spotlight_source = spotlight_source
	point_rule_number.text = _chosen_row.number_label.text if _chosen_row else ""
	point_rule_title.text = _chosen_row.title_label.text if _chosen_row else ""
	report_button.disabled = true

	dim.visible = true
	point_bar.visible = true
	_update_spotlights()
	set_process(true)

	if _point_tween:
		_point_tween.kill()
	_point_tween = create_tween().set_parallel()
	_point_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_point_tween.tween_method(_set_dim_strength, 0.0, 1.0, DIM_SECONDS)
	_point_tween.tween_property(point_bar, "modulate:a", 1.0, DIM_SECONDS).from(0.0)


## Height the bar takes at the bottom while pointing, for the screen to be shrunk by
func get_point_bar_height() -> float:
	return POINT_BAR_HEIGHT


## Lets the report be sent once a section is picked, tying the rule to it with a line
func set_section_picked(is_picked: bool) -> void:
	report_button.disabled = not is_picked
	if is_picked:
		link.play()
		_update_spotlights()
	else:
		link.clear()


## Puts everything away, forgetting the rule picked
func stop() -> void:
	_close_sheet()
	_hide_pointing()
	_chosen_rule_id = ""
	_chosen_row = null


## Slams the verdict of a report over the app, then fades it away
##
## result: "verdict" ("found", "duplicate", "late", "stale", "wrong" or "false"), "title" and
## "subtitle", as judged by events_director
func play_stamp(result: Dictionary = {}) -> void:
	if _stamp_tween:
		_stamp_tween.kill()

	var title := str(result.get("title", "DENUNCIADO"))
	stamp_label.text = title
	stamp_label.add_theme_font_size_override(
		"font_size", 20 if title.length() > STAMP_LONG_TITLE else 28
	)
	stamp_sub_label.text = str(result.get("subtitle", "GOLPE REPORTADO · ENIGMA")).to_upper()

	var color := STAMP_FOUND_COLOR
	match str(result.get("verdict", "found")):
		"duplicate", "late", "stale":
			color = STAMP_NEUTRAL_COLOR
		"wrong", "false":
			color = STAMP_WRONG_COLOR
	var style := stamp.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = color
	stamp.add_theme_stylebox_override("panel", style)
	stamp_label.add_theme_color_override("font_color", color)
	stamp_sub_label.add_theme_color_override("font_color", color.darkened(0.3))
	# Shrinks back around the new text before being centred on the phone
	stamp.reset_size()
	stamp.position = (size - stamp.size) / 2.0

	stamp.visible = true
	stamp.pivot_offset = stamp.size / 2.0
	stamp.modulate.a = 0.0
	stamp.scale = Vector2.ONE * 1.8

	_stamp_tween = create_tween()
	_stamp_tween.set_parallel()
	_stamp_tween.tween_property(stamp, "scale", Vector2.ONE, 0.16).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	_stamp_tween.tween_property(stamp, "modulate:a", 1.0, 0.1)
	_stamp_tween.chain().tween_property(stamp, "modulate:a", 0.0, 0.3).set_delay(STAMP_HOLD_SECONDS)
	_stamp_tween.chain().tween_callback(func() -> void: stamp.visible = false)


func _process(_delta: float) -> void:
	_update_spotlights()


## Slides the rules notepad away, if it is open
func _close_sheet() -> void:
	if not _is_sheet_open:
		return
	_is_sheet_open = false

	_restart_sheet_tween()
	_sheet_tween.set_ease(Tween.EASE_IN)
	_sheet_tween.tween_property(scrim, "modulate:a", 0.0, SHEET_SECONDS * 0.8)
	_sheet_tween.tween_property(sheet, "position:y", size.y, SHEET_SECONDS * 0.8)
	_sheet_tween.chain().tween_callback(func() -> void:
		scrim.visible = false
		sheet.visible = false
	)


## Takes the dim and the bar away at once
func _hide_pointing() -> void:
	if _point_tween:
		_point_tween.kill()
	set_process(false)
	_spotlight_source = Callable()
	dim.visible = false
	point_bar.visible = false
	link.clear()


## Tells the dim where every target that can be seen right now is, and which ones are lit
##
## A lit target (hovered, pressed or selected) gets a bright hole in the dim, the others only
## a discreet outline.
func _update_spotlights() -> void:
	var targets: Array = _spotlight_source.call() if _spotlight_source.is_valid() else []
	var holes := PackedVector4Array()
	var radii := PackedFloat32Array()
	var lit_flags := PackedFloat32Array()
	var dim_origin := dim.get_global_rect().position
	var selected_target: DiscrepancyTarget = null

	for target: DiscrepancyTarget in targets:
		if target.selected:
			selected_target = target
		if holes.size() >= 32: # MAX_HOLES in spotlight.gdshader
			break
		var rect := target.get_spotlight_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		holes.append(Vector4(
			rect.position.x - dim_origin.x, rect.position.y - dim_origin.y, rect.size.x, rect.size.y
		))
		radii.append(target.get_spotlight_corner_radius())
		lit_flags.append(1.0 if target.is_lit() else 0.0)

	# Uniform arrays keep their declared length, the unused slots are skipped by hole_count
	var count := holes.size()
	holes.resize(32)
	radii.resize(32)
	lit_flags.resize(32)
	var dim_material := dim.material as ShaderMaterial
	dim_material.set_shader_parameter("hole_count", count)
	dim_material.set_shader_parameter("holes", holes)
	dim_material.set_shader_parameter("radii", radii)
	dim_material.set_shader_parameter("lit_flags", lit_flags)

	if selected_target:
		link.set_ends(
			point_rule_badge.get_global_rect(),
			selected_target.get_spotlight_rect(),
			selected_target.get_spotlight_corner_radius()
		)


func _set_dim_strength(value: float) -> void:
	(dim.material as ShaderMaterial).set_shader_parameter("strength", value)


## Lists the rules in force today by app, oldest first, flagging the ones added today
##
## The group of the screen being reported comes first and is the only one that can be picked,
## the others follow, faded, for the player to read. A rule checked in several apps is listed in
## each of their groups.
func _fill_rules() -> void:
	for row in rules_list.get_children():
		rules_list.remove_child(row)
		row.queue_free()
	_chosen_row = null
	next_button.disabled = true

	var rules := _load_rules()
	var groups: Array = RULES_GROUPS.keys()
	if groups.has(_rules_app):
		groups.erase(_rules_app)
		groups.push_front(_rules_app)

	for group in groups:
		var is_current: bool = group == _rules_app
		var group_rules := rules.filter(
			func(rule: Dictionary) -> bool:
				return (
					int(rule.get("day", 0)) <= GameData.current_day
					and rule.get("apps", []).has(group)
				)
		)
		if group_rules.is_empty():
			continue

		var heading: String = RULES_GROUPS[group]
		if not is_current:
			heading = "Em outros apps · " + heading
		_add_group_heading(heading)

		var number := 0
		for rule in group_rules:
			number += 1
			var row := RULE_ROW.instantiate()
			rules_list.add_child(row)
			row.setup(rule, number, int(rule.get("day", 0)) == GameData.current_day)
			row.set_enabled(is_current)
			row.chosen.connect(_on_rule_chosen)
			if is_current and str(rule.get("id", "")) == _chosen_rule_id:
				_on_rule_chosen(row)

	rules_scroll.scroll_vertical = 0


## Writes the name of a rules group on the page, past the margin line, on a ruling
func _add_group_heading(text: String) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(RulesNotebook.MARGIN_WIDTH) + 6)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", GROUP_FONT)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.5686275, 0.101960786, 0.21960784, 0.9))
	margin.add_child(label)
	rules_list.add_child(margin)
	RulesNotebook.fit_to_ruling(label)


## Reads the whole rulebook, every day included
func _load_rules() -> Array:
	var file := FileAccess.open(RULES_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open rules file: %s" % RULES_PATH)
		return []

	var rules = JSON.parse_string(file.get_as_text())
	if not rules is Array:
		push_error("Rules file is not a JSON array: %s" % RULES_PATH)
		return []
	return rules


func _restart_sheet_tween() -> void:
	if _sheet_tween:
		_sheet_tween.kill()
	_sheet_tween = create_tween().set_parallel()
	_sheet_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_rule_chosen(row: PanelContainer) -> void:
	if _chosen_row and is_instance_valid(_chosen_row):
		_chosen_row.set_selected(false)
	_chosen_row = row
	_chosen_rule_id = str(row.rule.get("id", ""))
	row.set_selected(true)
	next_button.disabled = false


func _on_next_pressed() -> void:
	if _chosen_row == null:
		return
	rule_chosen.emit(_chosen_row.rule)


func _on_cancel_pressed() -> void:
	rules_cancelled.emit()


func _on_scrim_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not event.pressed:
		_on_cancel_pressed()
