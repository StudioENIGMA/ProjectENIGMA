extends Control

signal password_changed()

#region CHILDREN NODES REFERENCES
@export var password_digit_1: Label
@export var password_digit_2: Label
@export var password_digit_3: Label
@export var password_digit_4: Label
@export var instruction_label: Label
@export var confirm_button: Button
#endregion

var gated_app: GameData.App

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)

## Sets up the PasswordsInserter UI with the provided data, initializing the gated app
## and updating the instruction label accordingly
func setup(data: Dictionary) -> void:
	gated_app = data["GatedApp"]
	var app_name = GameData.apps_name_reverse.get(gated_app, "Desconhecido")
	instruction_label.text = "Insira a nova senha para %s:" % app_name

	clear_password_fields()

#region PASSWORD LOGIC
## Retrieves the entered password as a concatenated string of the four digit labels
func get_entered_password() -> String:
	return "%s%s%s%s" % [
		password_digit_1.text,
		password_digit_2.text,
		password_digit_3.text,
		password_digit_4.text,
	]

## Clears the password digit labels, resetting them to their default state
func clear_password_fields() -> void:
	confirm_button.disabled = true
	password_digit_1.text = "_"
	password_digit_2.text = "_"
	password_digit_3.text = "_"
	password_digit_4.text = "_"

## Handles key input events to capture numeric password entry and validate it against
## the stored password for the gated app
func _input(event: InputEvent) -> void:
	# Avoid capturing keys when hidden
	if not is_visible_in_tree():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event = event as InputEventKey

		if key_event.unicode >= ord("0") and key_event.unicode <= ord("9"):
			var digit = char(key_event.unicode)

			if password_digit_1.text == "_":
				password_digit_1.text = digit
			elif password_digit_2.text == "_":
				password_digit_2.text = digit
			elif password_digit_3.text == "_":
				password_digit_3.text = digit
			elif password_digit_4.text == "_":
				password_digit_4.text = digit
				confirm_button.disabled = false

## Handles confirm button press to update the password in GameData
func _on_confirm_button_pressed() -> void:
	var new_password = get_entered_password()
	GameData.passwords[gated_app] = new_password
	clear_password_fields()
	instruction_label.text = "Senha alterada com sucesso!"
	emit_signal("password_changed")
#endregion
