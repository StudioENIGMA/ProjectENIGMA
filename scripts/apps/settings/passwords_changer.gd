extends Control

signal password_changed()

const MAXIMUM_PASSWORD_LENGTH: int = 20
const DIGITS: String = "0123456789"
const LOWERCASE: String = "abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúç"
const UPPERCASE: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÀÂÃÉÊÍÓÔÕÚÇ"
## What a new password needs on each day (index = GameData.current_day, later days reuse the
## last entry): the minimum length and how many characters of each class it must have
const DAILY_REQUIREMENTS: Array[Dictionary] = [
	{"length": 4, "digits": 0, "lowercase": 0, "uppercase": 0, "symbols": 0},
	{"length": 6, "digits": 1, "lowercase": 0, "uppercase": 0, "symbols": 0},
	{"length": 8, "digits": 1, "lowercase": 1, "uppercase": 0, "symbols": 0},
	{"length": 8, "digits": 1, "lowercase": 1, "uppercase": 1, "symbols": 0},
	{"length": 10, "digits": 1, "lowercase": 1, "uppercase": 1, "symbols": 1},
	{"length": 12, "digits": 2, "lowercase": 1, "uppercase": 1, "symbols": 1},
	{"length": 14, "digits": 2, "lowercase": 1, "uppercase": 1, "symbols": 2},
]
## Character classes a requirement can ask for, keyed like DAILY_REQUIREMENTS. Symbols have no
## character list: they are anything that is not a letter or a digit
const CHARACTER_CLASSES: Array[Dictionary] = [
	{
		"key": "lowercase", "characters": LOWERCASE,
		"singular": "letra minúscula", "plural": "letras minúsculas",
	},
	{
		"key": "uppercase", "characters": UPPERCASE,
		"singular": "letra maiúscula", "plural": "letras maiúsculas",
	},
	{
		"key": "digits", "characters": DIGITS,
		"singular": "número", "plural": "números",
	},
	{
		"key": "symbols", "characters": "",
		"singular": "símbolo (!, @, #...)", "plural": "símbolos (!, @, #...)",
	},
]
const HINT_TEXT: String = (
	"A senha expira todo dia e as exigências aumentam com o tempo. Misturar letras, números e"
	+ " símbolos deixa a senha mais difícil de descobrir."
)
const ALERT_COLOR: Color = Color(0.5686275, 0.101960786, 0.21960784)
const NEUTRAL_COLOR: Color = Color(0.13333334, 0.28235295, 0.38431373)
const MUTED_COLOR: Color = Color(0.43137255, 0.44313726, 0.5019608)
const CHECK_MET_COLOR: Color = Color(0.30980393, 0.79607844, 0.68235296)
const CHECK_UNMET_COLOR: Color = Color(0.85882354, 0.84705883, 0.8117647)

#region CHILDREN NODES REFERENCES
@export var subtitle_label: Label
@export var app_icon: TextureRect
@export var app_name_label: Label
@export var line_edit: LineEdit
@export var toggle_visibility_button: Button
@export var hint_label: Label
@export var requirements_list: VBoxContainer
## Hidden row duplicated once per requirement of the day
@export var requirement_row_template: HBoxContainer
@export var strength_row: HBoxContainer
@export var strength_bar: ProgressBar
@export var strength_label: Label
@export var confirm_button: Button
#endregion

#region ICONS
@export var visible_password_icon: Texture2D
@export var hidden_password_icon: Texture2D
#endregion

#region STRENGTH BAR STYLES
@export var weak_strength_style: StyleBoxFlat
@export var medium_strength_style: StyleBoxFlat
@export var strong_strength_style: StyleBoxFlat
#endregion

var gated_app: GameData.App

## Requirement rows of the day, each {"row": HBoxContainer, "check": Callable}
var _requirement_rows: Array[Dictionary] = []

func _ready() -> void:
	line_edit.max_length = MAXIMUM_PASSWORD_LENGTH
	line_edit.text_changed.connect(_user_typed)
	line_edit.text_submitted.connect(_on_password_submitted)
	toggle_visibility_button.pressed.connect(_on_toggle_visibility_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)

## Sets up the PasswordsChanger UI with the provided data, initializing the gated app
## and naming the app whose password is about to change
func setup(data: Dictionary) -> void:
	gated_app = int(data["GatedApp"]) as GameData.App

	var app_data: Dictionary = GameData.apps_data.get(gated_app, {})
	var app_name: String = app_data.get(
		"name", GameData.apps_name_reverse.get(gated_app, "Aplicativo")
	)

	var app_icon_path = app_data.get("icon_path", "")
	if app_icon_path != "":
		app_icon.texture = load(app_icon_path)

	app_name_label.text = app_name
	subtitle_label.text = "Escolha uma senha nova para %s." % app_name

	_reset_form()
	_build_requirements()

	# Catch focus to the line edit
	await get_tree().process_frame
	line_edit.grab_focus()

#region PASSWORD LOGIC
## Puts the form back in its editable, empty state so a reused instance never shows
## the previous app's result
func _reset_form() -> void:
	line_edit.text = ""
	line_edit.editable = true
	line_edit.secret = true
	toggle_visibility_button.icon = hidden_password_icon
	toggle_visibility_button.tooltip_text = "Mostrar senha"
	toggle_visibility_button.disabled = false
	hint_label.text = HINT_TEXT
	hint_label.add_theme_color_override("font_color", MUTED_COLOR)
	strength_row.visible = false
	confirm_button.disabled = true
	confirm_button.text = "Confirmar"

## Enables the confirm button once every requirement of the day is met and keeps the
## checklist and the strength meter in sync with what is typed
func _user_typed(entered_password: String) -> void:
	confirm_button.disabled = not _refresh_requirements(entered_password)
	_refresh_strength(entered_password)

## Toggles the password between masked and plain text
func _on_toggle_visibility_pressed() -> void:
	line_edit.secret = not line_edit.secret

	if line_edit.secret:
		toggle_visibility_button.icon = hidden_password_icon
		toggle_visibility_button.tooltip_text = "Mostrar senha"
	else:
		toggle_visibility_button.icon = visible_password_icon
		toggle_visibility_button.tooltip_text = "Ocultar senha"

## Lets the on-screen keyboard's "done" key confirm the password
func _on_password_submitted(_entered_password: String) -> void:
	if not confirm_button.disabled:
		_on_confirm_button_pressed()

## Handles confirm button press to update the password in GameData
func _on_confirm_button_pressed() -> void:
	confirm_button.disabled = true
	GameData.passwords[gated_app] = line_edit.text
	if not GameData.passwords_updated_today.has(gated_app):
		GameData.passwords_updated_today.append(gated_app)

	# Lock the form down and report the change where the field used to ask for it
	line_edit.editable = false
	line_edit.secret = true
	toggle_visibility_button.disabled = true
	strength_row.visible = false
	confirm_button.text = "Senha alterada"
	hint_label.text = "Senha alterada com sucesso!"
	hint_label.add_theme_color_override("font_color", NEUTRAL_COLOR)

	await get_tree().create_timer(1.0).timeout
	emit_signal("password_changed")
#endregion

#region PASSWORD REQUIREMENTS
## Rebuilds the checklist with today's requirements, plus not reusing the current password
func _build_requirements() -> void:
	for requirement in _requirement_rows:
		requirement["row"].queue_free()
	_requirement_rows.clear()

	var day_index: int = clampi(GameData.current_day, 0, DAILY_REQUIREMENTS.size() - 1)
	var requirements: Dictionary = DAILY_REQUIREMENTS[day_index]

	_add_requirement(
		"Pelo menos %d caracteres" % requirements["length"],
		func(password: String) -> bool: return password.length() >= requirements["length"]
	)
	for character_class in CHARACTER_CLASSES:
		_add_class_requirement(requirements[character_class["key"]], character_class)

	var current_password: String = GameData.passwords.get(gated_app, "")
	_add_requirement(
		"Diferente da senha atual",
		func(password: String) -> bool:
			return not password.is_empty() and password != current_password
	)

	_refresh_requirements("")

## Adds an "at least N characters of this class" row, skipped when the day does not ask for it
func _add_class_requirement(minimum: int, character_class: Dictionary) -> void:
	if minimum <= 0:
		return

	var noun: String = character_class["singular"] if minimum == 1 else character_class["plural"]
	_add_requirement(
		"Pelo menos %d %s" % [minimum, noun],
		func(password: String) -> bool:
			return _count_characters(password, character_class["characters"]) >= minimum
	)

func _add_requirement(text: String, check: Callable) -> void:
	var row: HBoxContainer = requirement_row_template.duplicate()
	row.get_node("Label").text = text
	requirements_list.add_child(row)
	_requirement_rows.append({"row": row, "check": check})

## Ticks every requirement the password meets and tells whether all of them are met
func _refresh_requirements(entered_password: String) -> bool:
	var all_met: bool = true

	for requirement in _requirement_rows:
		var is_met: bool = requirement["check"].call(entered_password)
		all_met = all_met and is_met

		var row: HBoxContainer = requirement["row"]
		row.visible = true
		row.get_node("Check").self_modulate = CHECK_MET_COLOR if is_met else CHECK_UNMET_COLOR
		row.get_node("Label").add_theme_color_override(
			"font_color", NEUTRAL_COLOR if is_met else MUTED_COLOR
		)

	return all_met

## Counts the characters of the password in the class. An empty class counts symbols
func _count_characters(entered_password: String, class_characters: String) -> int:
	var count: int = 0
	for character in entered_password:
		if class_characters.is_empty():
			if not (DIGITS + LOWERCASE + UPPERCASE).contains(character):
				count += 1
		elif class_characters.contains(character):
			count += 1
	return count
#endregion

#region PASSWORD STRENGTH
## Shows the strength meter for anything typed, scoring length and character variety
func _refresh_strength(entered_password: String) -> void:
	strength_row.visible = not entered_password.is_empty()
	if entered_password.is_empty():
		return

	var score: int = _strength_score(entered_password)
	strength_bar.value = max(score, 1)

	if score <= 1:
		strength_bar.add_theme_stylebox_override("fill", weak_strength_style)
		strength_label.add_theme_color_override("font_color", ALERT_COLOR)
		strength_label.text = "Fraca"
	elif score == 2:
		strength_bar.add_theme_stylebox_override("fill", medium_strength_style)
		strength_label.add_theme_color_override("font_color", NEUTRAL_COLOR)
		strength_label.text = "Média"
	else:
		strength_bar.add_theme_stylebox_override("fill", strong_strength_style)
		strength_label.add_theme_color_override("font_color", NEUTRAL_COLOR)
		strength_label.text = "Forte"

## Scores a password from 0 to 4: one point per length milestone, one per extra
## character class beyond the first
func _strength_score(entered_password: String) -> int:
	var score: int = 0

	if entered_password.length() >= 8:
		score += 1
	if entered_password.length() >= 12:
		score += 1

	var classes: int = _character_classes(entered_password)
	if classes >= 2:
		score += 1
	if classes >= 3:
		score += 1

	return score

## Counts how many of digits, lowercase, uppercase and symbols appear in the password
func _character_classes(entered_password: String) -> int:
	var has_digit: bool = false
	var has_lowercase: bool = false
	var has_uppercase: bool = false
	var has_symbol: bool = false

	for character in entered_password:
		if DIGITS.contains(character):
			has_digit = true
		elif LOWERCASE.contains(character):
			has_lowercase = true
		elif UPPERCASE.contains(character):
			has_uppercase = true
		else:
			has_symbol = true

	var classes: int = 0
	for is_present in [has_digit, has_lowercase, has_uppercase, has_symbol]:
		if is_present:
			classes += 1

	return classes
#endregion
