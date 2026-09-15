extends Button

## Report that the player picked this option as the answer to be sent
##
## sender_name: The NPC the answer is addressed to
## message: The message that goes to the conversation once the answer is sent
## answer_id: The identifier of the answer, used to advance the story
signal option_selected(sender_name:String, message:String, answer_id:int)

var _name:String
var _message:String
var _answer_id:int

## Fills the reply card with the text the player may send
##
## sender_name: The NPC the answer is addressed to
## title: The short text shown on the card
## message: The message sent to the conversation when the option is picked
## answer_id: The identifier of the answer, used to advance the story
func setup(sender_name:String, title:String, message:String, answer_id:int) -> void:
	var bank_password := str(GameData.passwords.get(GameData.App.BANK, ""))
	text = title.replace("$bank_password", bank_password)
	_name = sender_name
	_message = message.replace("$bank_password", bank_password)
	_answer_id = answer_id

## Puts every card of the same batch under one group, so only one stays picked
##
## group: The group shared by the cards currently on screen
func set_option_group(group:ButtonGroup) -> void:
	button_group = group

func _on_pressed() -> void:
	# The group already unpressed the card picked before, this one only reports itself
	option_selected.emit(_name, _message, _answer_id)
