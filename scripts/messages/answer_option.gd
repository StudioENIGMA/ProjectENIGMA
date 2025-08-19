extends MarginContainer

@onready var button = $Button
@onready var label = $PanelContainer/Label
@onready var _name : String
@onready var _message : String
@onready var _answer_id : int

func setup(name : String, title : String, message : String, answer_id : int) -> void:
	label.text = title
	_name = name
	_message = message
	_answer_id = answer_id

func _on_button_pressed() -> void:
	EventBus.create_message.emit(_name, _message, EventBus.Sender.Me, GameData.hours_minutes)
	EventBus.clean_answers.emit()
	EventBus.delete_answers.emit(_name)
	EventBus.message_answered.emit(_answer_id)
