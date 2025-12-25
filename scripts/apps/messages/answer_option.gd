extends MarginContainer

@onready var button = $Button
@onready var label = $PanelContainer/Label
@onready var _name:String
@onready var _message:String
@onready var _answer_id:int

func setup(sender_name:String, title:String, message:String, answer_id:int) -> void:
	label.text = title
	_name = sender_name
	_message = message
	_answer_id = answer_id

func _on_button_pressed() -> void:
	EventBus.create_message.emit(_name, _message, EventBus.Sender.ME, GameData.hours_minutes)
	EventBus.delete_answers.emit(_name)
	EventBus.message_answered.emit(_answer_id)
