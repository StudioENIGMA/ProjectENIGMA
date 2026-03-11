extends Control

#region CHILDREN NODES REFERENCES
@export var update_button: Button
@export var gear: TextureRect
#endregion CHILDREN NODES REFERENCES

var is_updating: bool = false

func _ready() -> void:
	update_button.pressed.connect(_on_update_button_pressed)

func _on_update_button_pressed() -> void:
	GameData.updated_os_today = true
	update_button.text = "Sistema atualizado hoje"
	update_button.disabled = true
	is_updating = true

