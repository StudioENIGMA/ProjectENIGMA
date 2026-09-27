extends MarginContainer

signal message_answered(answer_id:int)

signal request_message_creation_on_answer(
	contact:Dictionary,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
)

signal delete_answers(conversation_id:String)

@export var option_button:Button
@export var option_label:Label

var _contact:Dictionary
var _message:String
var _answer_id:int

func setup(contact:Dictionary, title:String, message:String, answer_id:int) -> void:
	var bank_password := str(GameData.passwords.get(GameData.App.BANK, ""))
	option_label.text = title.replace("$bank_password", bank_password)
	_contact = contact
	_message = message.replace("$bank_password", bank_password)
	_answer_id = answer_id

func _on_button_pressed() -> void:
	request_message_creation_on_answer.emit(
		_contact,
		_message,
		{},
		GameData.Sender.PLAYER,
		GameData.hours_minutes
	)
	message_answered.emit(_answer_id)
	delete_answers.emit(_contact["id"])
