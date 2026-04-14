extends Control

signal password_changed()

#region CHILDREN NODES REFERENCES
@export var instruction_label: Label
@export var confirm_button: Button
@export var line_edit: LineEdit
#endregion

var gated_app: GameData.App

func _ready() -> void:
	line_edit.text_changed.connect(_user_typed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)

## Sets up the PasswordsInserter UI with the provided data, initializing the gated app
## and updating the instruction label accordingly
func setup(data: Dictionary) -> void:
	gated_app = data["GatedApp"]
	var app_name = GameData.apps_name_reverse.get(gated_app, "Desconhecido")
	instruction_label.text = "Insira a nova senha para %s:" % app_name

	line_edit.text = ""

	# Catch focus to the line edit
	await get_tree().process_frame
	line_edit.grab_focus()

#region PASSWORD LOGIC
## Handles key input events to capture numeric password entry and validate it against
## the stored password for the gated app
func _user_typed(entered_password: String) -> void:
	# If empty, allow it
	if entered_password.is_empty():
		confirm_button.disabled = true
		return
		
	# Check if the new text is a valid number
	if !entered_password.is_valid_float():
			line_edit.text = line_edit.text.substr(0, line_edit.text.length() - 1)
			line_edit.set_caret_column(line_edit.text.length())  # Move caret to the end
	
	if entered_password.length() > 4:
		line_edit.text = entered_password.substr(0, 4)
		line_edit.set_caret_column(line_edit.text.length())  # Move caret to the end
	
	if line_edit.text.length() == 4:
		confirm_button.disabled = false
	else:
		confirm_button.disabled = true

## Handles confirm button press to update the password in GameData
func _on_confirm_button_pressed() -> void:
	confirm_button.disabled = true
	var new_password = line_edit.text
	GameData.passwords[gated_app] = new_password
	line_edit.text = ""
	instruction_label.text = "Senha alterada com sucesso!"
	GameData.updated_password_today = true
	emit_signal("password_changed")
#endregion
