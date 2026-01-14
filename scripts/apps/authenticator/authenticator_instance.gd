extends MarginContainer

const CODE_VALIDITY_DURATION:int = 60

#region CHILDREN NODES REFERENCES
@export var app_icon: TextureRect
@export var code_label: Label
@export var remaining_time_bar: ProgressBar
@export var validity_label: Label
#endregion CHILDREN NODES REFERENCES

var authenticated_app: GameData.App
var current_validity_time:int = 0 # Each code is valid for 60 seconds

func setup(app: GameData.App) -> void:
	authenticated_app = app
	update_codes_validity()

## Updates the validity timer and generates a new code if needed
func update_codes_validity() -> void:
	current_validity_time = current_validity_time - 1
	if current_validity_time <= 0:
		generate_new_code()
		current_validity_time = CODE_VALIDITY_DURATION
	remaining_time_bar.value = CODE_VALIDITY_DURATION - current_validity_time
	validity_label.text = "Válido por:\n %02d s" % current_validity_time

## Generates a new 4-digit code and updates the code label
func generate_new_code() -> void:
	var new_code = ""
	for i in range(4):
		new_code += str(randi() % 10)
	code_label.text = new_code
	GameData.authentication_codes[authenticated_app] = new_code
