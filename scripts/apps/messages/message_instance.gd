# res://scripts/apps/messages/message_instance.gd
extends HBoxContainer

signal apk_installation_requested(app: GameData.App)

enum Align { LEFT, RIGHT }

const MAX_BUBBLE_WIDTH := 200.0

@export var align: Align = Align.RIGHT

@export var label: Label
@export var panel_container: PanelContainer
@export var time_label: Label

@export var message_animation: HBoxContainer
# Optional: allow the same script to support both scenes cleanly
@export var left_margin: MarginContainer
@export var right_margin: MarginContainer
@export var annex_container: CenterContainer
@export var annex_button: Button
@export var progress_bar: ProgressBar
@export var animation_player: AnimationPlayer

var _is_reflowing := false

func _ready() -> void:
	resized.connect(_reflow)
	var vp := get_viewport()
	if vp:
		vp.size_changed.connect(_reflow)
	call_deferred("_reflow")


func setup(message: String, annex: Dictionary, time : int, play_animation: bool = false) -> void:
	if label and time_label:
		if play_animation and message_animation and annex_container:
			message_animation.visible = true
			label.visible = false
			annex_container.visible = false
			time_label.visible = false
		elif message_animation and annex_container:
			annex_container.visible = true
			label.visible = true
			message_animation.visible = false
			time_label.visible = true
		label.text = message
		time_label.text = GameData.hours_minutes_as_string(time - GameData.starting_hours_minutes)
	_apply_annex(annex)
	_reflow()


## Applies the annex data to the message instance
##
## Checks the annex dictionary and sets up the annex button accordingly
## If the annex type is "apk", connects the button to handle APK installation
##
## annex: The annex dictionary containing annex data
func _apply_annex(annex: Dictionary) -> void:
	annex_container.visible = not annex.is_empty()
	if annex.has("image"):
		annex_button.icon = load(annex["image"])
	if annex.has("caption"):
		annex_button.text = annex["caption"]
	if annex.has("due_day"):
		var due_day = annex["due_day"]
		var current_day = GameData.current_day
		if due_day != current_day:
			annex_button.disabled = true
			annex_button.text = "Anexo expirado"

	# If annex type is apk, connect download action
	if annex.get("type", "") == "apk":
		# Check if already installed
		var app_key := str(annex.get("app_name", ""))
		var app: GameData.App = GameData.apps_name.get(app_key, GameData.App.MESSAGESHOME)
		if GameData.downloaded_apps.has(app):
			annex_button.disabled = true
			annex_button.text = "Instalado"
		else:
			annex_button.pressed.connect(_on_apk_annex_pressed.bind(annex))
	# TODO: deal with images, may be used to payments


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

	var reserved_edge := 8
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

func _on_apk_annex_pressed(annex: Dictionary) -> void:
	# Emit a signal to request APK installation
	var app_key := str(annex.get("app_name", ""))
	var app: GameData.App = GameData.apps_name.get(app_key, GameData.App.MESSAGESHOME)

	apk_installation_requested.emit(app) # Warn desktop UI to add icon in game screen

	# Disable the button to prevent multiple clicks
	annex_button.disabled = true
	annex_button.text = "BAIXANDO..."
	progress_bar.visible = true
	animation_player.play("download_animation")

	# Simulate download time
	await get_tree().create_timer(2.5).timeout
	progress_bar.visible = false
	annex_button.text = "INSTALADO"
