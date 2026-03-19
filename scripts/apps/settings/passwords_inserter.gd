extends Control

signal password_correct()

#region CHILDREN NODES REFERENCES
@export var instruction_label: Label
@export var line_edit: LineEdit
#endregion

var gated_app: GameData.App

func _ready() -> void:
	line_edit.text_changed.connect(_user_typed)

## Sets up the PasswordsInserter UI with the provided data, initializing the gated app
## and updating the instruction label accordingly
func setup(data: Dictionary) -> void:
	gated_app = data["GatedApp"]
	var app_name = GameData.apps_name_reverse.get(gated_app, "Desconhecido")
	instruction_label.text = "Insira a senha para %s:" % app_name

	line_edit.text = ""

	# Catch focus to the line edit
	await get_tree().process_frame
	line_edit.grab_focus()

#region PASSWORD LOGIC
func _user_typed(entered_password: String) -> void:
	var correct_password = GameData.passwords.get(gated_app, "")

	if entered_password.length() == correct_password.length():
		if entered_password == correct_password:
			password_correct.emit()
		else:
			line_edit.text = ""
			instruction_label.text = "Senha incorreta"
#endregion
