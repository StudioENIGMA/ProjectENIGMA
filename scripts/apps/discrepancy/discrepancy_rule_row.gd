extends PanelContainer
## One rule of the day written in the rules notepad, picked by tapping it
##
## The chosen rule gets its title marked with a highlighter and its number circled.

## Emitted when the player taps the row
signal chosen(row: PanelContainer)

## How far the pointer may travel between press and release to count as a tap, in pixels
const TAP_SLOP := 10.0

@export var number_label: Label
@export var new_tag: Control
@export var title_label: Label
@export var description_label: Label
@export var highlight_color := Color(0.44705883, 0.87450981, 0.7294118, 0.55)
@export var circle_color := Color(0.30980393, 0.79607844, 0.68235296, 1)

## The rule shown, as read from data/rules/rules.json
var rule: Dictionary = {}
## Whether the row can be picked: the rules of the other apps are only there to be read
var is_enabled := true

var _is_selected := false
## Where the pointer went down, in viewport coordinates, or null while nothing is pressed
var _press_position = null


func _ready() -> void:
	for label in [number_label, title_label, description_label]:
		RulesNotebook.fit_to_ruling(label)
	title_label.resized.connect(queue_redraw)


## Fills the row with a rule
##
## rule_data: The rule, with its "title" and "description"
## number: Position of the rule in the day's rulebook, starting at 1
## is_new: Whether the rule was added today
func setup(rule_data: Dictionary, number: int, is_new: bool) -> void:
	rule = rule_data
	number_label.text = str(number)
	new_tag.visible = is_new
	title_label.text = str(rule_data.get("title", ""))
	description_label.text = str(rule_data.get("description", ""))
	set_selected(false)


## Lets the row be picked, or fades it as a rule of another app
func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	modulate.a = 1.0 if enabled else 0.4


## Shows the row as the chosen one, or as a plain option
func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	queue_redraw()


func _draw() -> void:
	if not _is_selected:
		return

	# A highlighter stroke over the lower part of each line of the title
	var title_origin := title_label.global_position - global_position
	var font := title_label.get_theme_font("font")
	var font_size := title_label.get_theme_font_size("font_size")
	var line_count := title_label.get_line_count()
	var one_line_width := font.get_string_size(
		title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x
	var width := minf(one_line_width, title_label.size.x) if line_count == 1 else title_label.size.x
	for line in line_count:
		var line_top: float = title_origin.y + line * RulesNotebook.LINE_PITCH
		draw_rect(
			Rect2(title_origin.x - 3, line_top + 9, width + 6, RulesNotebook.BASELINE - 6),
			highlight_color
		)

	# The number circled in pen
	var number_center := Vector2(
		number_label.global_position.x - global_position.x + number_label.size.x / 2.0,
		number_label.global_position.y - global_position.y + RulesNotebook.BASELINE - 5.5
	)
	draw_arc(number_center, 10.0, 0.0, TAU, 32, circle_color, 2.0, true)


func _gui_input(event: InputEvent) -> void:
	if not is_enabled:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		_press_position = event.global_position
		return

	if _press_position == null:
		return

	# Compared in viewport coordinates, a drag that scrolled the list is not a tap
	var is_tap: bool = event.global_position.distance_to(_press_position) <= TAP_SLOP
	_press_position = null
	if is_tap:
		accept_event()
		chosen.emit(self)
