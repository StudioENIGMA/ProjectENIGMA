extends Control

const CODE_VALIDITY_DURATION: int = 60
const EXPIRING_THRESHOLD: int = 10 # Seconds left when the code is drawn as expiring

const CODE_COLOR := Color(0.13333334, 0.28235295, 0.38431373)
const EXPIRING_COLOR := Color(0.5686275, 0.101960786, 0.21960784)
const FILL_COLOR := Color(0.30980393, 0.79607844, 0.68235296)
const EXPIRING_FILL_COLOR := Color(0.92156863, 0.039215688, 0.27058825)

#region CHILDREN NODES REFERENCES
@export var app_icon: TextureRect
@export var app_name_label: Label
@export var code_label: Label
@export var remaining_time_bar: ProgressBar
@export var validity_label: Label
@export var progress_fill_style: StyleBoxFlat
#endregion CHILDREN NODES REFERENCES

var authenticated_app: GameData.App
var current_validity_time: int = 0 # Each code is valid for 60 seconds

func _ready() -> void:
	# Each instance recolours its own fill, so it must not share the scene's StyleBox
	progress_fill_style = progress_fill_style.duplicate()
	remaining_time_bar.add_theme_stylebox_override("fill", progress_fill_style)
	remaining_time_bar.max_value = CODE_VALIDITY_DURATION

## Fills in the icon and name of the authenticated app and generates its first code
func setup(app: GameData.App) -> void:
	authenticated_app = app

	var app_data: Dictionary = GameData.apps_data.get(app, {})
	var app_icon_path: String = app_data.get("icon_path", "")
	if app_icon_path != "":
		app_icon.texture = load(app_icon_path)
	app_name_label.text = app_data.get("name", "")

	update_codes_validity()

## Updates the validity timer and generates a new code if needed
func update_codes_validity() -> void:
	current_validity_time = current_validity_time - 1
	if current_validity_time <= 0:
		generate_new_code()
		current_validity_time = CODE_VALIDITY_DURATION
	_refresh_timer_display()

## Generates a new 4-digit code and updates the code label
func generate_new_code() -> void:
	var new_code = ""
	for i in range(4):
		new_code += str(randi() % 10)
	code_label.text = new_code
	GameData.authentication_codes[authenticated_app] = new_code

## Shows the remaining validity, turning the code crimson when it is about to expire
func _refresh_timer_display() -> void:
	var expiring: bool = current_validity_time <= EXPIRING_THRESHOLD
	remaining_time_bar.value = current_validity_time
	validity_label.text = "%d s" % current_validity_time
	code_label.add_theme_color_override("font_color", EXPIRING_COLOR if expiring else CODE_COLOR)
	validity_label.add_theme_color_override(
		"font_color", EXPIRING_COLOR if expiring else Color(0.43137255, 0.44313726, 0.5019608)
	)
	progress_fill_style.bg_color = EXPIRING_FILL_COLOR if expiring else FILL_COLOR
