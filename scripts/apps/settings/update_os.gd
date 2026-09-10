extends Control

#region CONSTANTS
const PENDING_STATUS_TEXT: String = "Atualização disponível"
const RUNNING_STATUS_TEXT: String = "Instalando atualização"
const DONE_STATUS_TEXT: String = "Tudo em dia"

const PENDING_STATUS_COLOR: Color = Color(0.5686275, 0.101960786, 0.21960784)
const NEUTRAL_STATUS_COLOR: Color = Color(0.13333334, 0.28235295, 0.38431373)
#endregion CONSTANTS

#region CHILDREN NODES REFERENCES
@export var update_button: Button
@export var animator: AnimationPlayer
@export var progress_bar: ProgressBar
@export var status_pill: PanelContainer
@export var status_label: Label
@export var percent_label: Label
#endregion CHILDREN NODES REFERENCES

#region STATUS PILL STYLES
@export var pending_status_style: StyleBoxFlat
@export var running_status_style: StyleBoxFlat
@export var done_status_style: StyleBoxFlat
#endregion STATUS PILL STYLES

func _ready() -> void:
	update_button.pressed.connect(_on_update_button_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()

## Rebuilds the screen from GameData, so reopening it always shows the real state
func _refresh() -> void:
	percent_label.visible = false
	progress_bar.value = 100.0 if GameData.updated_os_today else 0.0

	if GameData.updated_os_today:
		_set_status(DONE_STATUS_TEXT, done_status_style, NEUTRAL_STATUS_COLOR)
		update_button.text = "Sistema atualizado hoje"
		update_button.disabled = true
	else:
		_set_status(PENDING_STATUS_TEXT, pending_status_style, PENDING_STATUS_COLOR)
		update_button.text = "Atualizar OS"
		update_button.disabled = false

## Applies one of the three pill looks (pending, running, done) to the status chip
func _set_status(text: String, style: StyleBoxFlat, font_color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", font_color)
	status_pill.add_theme_stylebox_override("panel", style)

func _on_visibility_changed() -> void:
	if visible and not animator.is_playing():
		_refresh()

func _on_update_button_pressed() -> void:
	GameData.updated_os_today = true
	update_button.text = "Atualizando Sistema"
	update_button.disabled = true
	_set_status(RUNNING_STATUS_TEXT, running_status_style, NEUTRAL_STATUS_COLOR)
	percent_label.visible = true
	animator.play("update_os")

func _on_progress_bar_value_changed(value: float) -> void:
	percent_label.text = "%d%%" % int(round(value))

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	# Use to detect when update is over (at the end of the animation)
	_refresh()
