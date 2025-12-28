extends MarginContainer

signal message_answered(answer_id:int)

signal request_message_creation_on_answer(
	name:String,
	message:String,
	sender:GameData.Sender,
	time:int
)

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
	request_message_creation_on_answer.emit(
		_name,
		_message,
		GameData.Sender.PLAYER,
		GameData.hours_minutes
	)
	EventBus.delete_answers.emit(_name)
	message_answered.emit(_answer_id)
