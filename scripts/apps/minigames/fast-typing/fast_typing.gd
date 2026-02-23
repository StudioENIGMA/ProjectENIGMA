extends Control


#region CHILDREN NODES REFERENCES
@export var text_to_type1:RichTextLabel
@export var text_to_type2:RichTextLabel
@export var player_type_space:LineEdit
@export var minigame_timer:MarginContainer
#endregion

var text_sequence_queue: Array = [] 
#var bytes_of_text_to_type1: PackedByteArray
#var bytes_of_text_to_type2: PackedByteArray
var first_completed:bool = false
var type_completed:bool
var current_text:String
var splited_text_words:Array
var typed_correctly_words:Array
var word:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_to_type1.text = "[font_size=50] Received text 1"
	text_to_type2.text = "[font_size=50] Received text 2"
	#bytes_of_text_to_type1 = text_to_type1.text.to_utf8_buffer()
	#bytes_of_text_to_type2 = text_to_type1.text.to_utf8_buffer()
	push_to_queue(text_to_type1.text)
	push_to_queue(text_to_type2.text)
	
	setup()

func setup() -> void:
		
	current_text = text_sequence_queue.pop_front()
	splited_text_words = current_text.split(" ")
	
	splited_text_words.pop_front() # Removing font size from the array
	typed_correctly_words.clear() # Removing first text from correct words
	
	word = splited_text_words.pop_front()
	print(word)
	
#func verify_player_typed_text() -> void:
#	current_text = text_sequence_queue.pop_front()
#	type_completed = false
#	
#	splited_text_words = current_text.split(" ")
#	word = splited_text_words.pop_front()
#	
#	while !type_completed:
#		if player_type_space.text == word:
#			if !text_sequence_queue.is_empty():
#				typed_correctly_words.append("[color=green] "+word+"[/clolor]")
#				update_correct_word(text_to_type1)
#			else:
#				typed_correctly_words.append("[color=green] "+word+"[/clolor]")
#				update_correct_word(text_to_type2)

func update_correct_word(text_to_type:RichTextLabel) -> void:
	var colored_text:String = ""
	
	for colored_word in typed_correctly_words:
		colored_text = colored_text + " " + colored_word
		
	if splited_text_words.is_empty():
		text_to_type.text = "[font_size=50]" + colored_text
		player_type_space.clear()
		
		setup()
		return
		
	for word in splited_text_words:
		colored_text = colored_text + " " + word
		
	text_to_type.text = "[font_size=50]" + colored_text
	player_type_space.clear()
	word = splited_text_words.pop_front()
	

func push_to_queue(text: String) -> void:
	text_sequence_queue.push_back(text)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_type_space.text == word:
			if !text_sequence_queue.is_empty():
				typed_correctly_words.append("[color=green]"+word+"[/color]")
				update_correct_word(text_to_type1)
			else:
				typed_correctly_words.append("[color=green]"+word+"[/color]")
				update_correct_word(text_to_type2)
