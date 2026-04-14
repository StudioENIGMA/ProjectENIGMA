extends PanelContainer

@export var conscent_button: Button

func _ready() -> void:
	var file_path := "user://age_verification.flag"
	if not FileAccess.file_exists(file_path):
		show()
	conscent_button.pressed.connect(_on_conscent_button_pressed)

func _on_conscent_button_pressed() -> void:
	var file_path = "user://age_verification.flag"
	var age_file = FileAccess.open(file_path, FileAccess.WRITE)
	if age_file == null:
		push_error("Could not open save file for writing")
		return

	age_file.store_string("")
	age_file.close()
	hide()
