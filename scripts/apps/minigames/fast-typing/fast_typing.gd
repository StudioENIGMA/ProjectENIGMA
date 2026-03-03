extends Control

signal hack_concluded

const PHRASE_SCENE = preload("res://scenes/apps/minigames/fast-typing/phrase_to_type.tscn")
const RANDOM_WORDS = ["apple", "banana", "cherry", "date", "elderberry", "fig", "grape", "honeydew"]

#region CHILDREN NODES REFERENCES
@export var line_edit: LineEdit
@export var phrases_vbox: VBoxContainer
#endregion

var current_phrases = []
var current_index = 0
var has_wrong_char = false
var completed_phrases = 0

func _ready():
	current_phrases.append(generate_random_phrase())

	for i in range(2):
		# Generate 2 bools, 1 for each extra phrase that may be added
		var random_bool = randf() < 0.5
		if random_bool:
			current_phrases.append(generate_random_phrase())

	update_display()

	line_edit.text_changed.connect(_user_typed)

## Means hack minigame started
func setup():
	# Catch focus to the line edit
	line_edit.grab_focus()

func generate_random_phrase():
	var random_phrase = []
	for i in range(5):
		var random_word = RANDOM_WORDS[randi() % RANDOM_WORDS.size()]
		random_phrase.append(random_word)
	
	return random_phrase

func update_display():
	current_index = 0
	for child in phrases_vbox.get_children():
		child.queue_free()
	for phrase in current_phrases:
		var phrase_instance = PHRASE_SCENE.instantiate()
		var is_completed = current_index < completed_phrases
		var is_current = current_index == completed_phrases
		phrase_instance.setup(phrase, current_index, is_completed, is_current)
		phrases_vbox.add_child(phrase_instance)
		current_index += 1

func _user_typed(new_text):
	# Get the current phrase to type
	var current_phrase = current_phrases[completed_phrases]
	var current_phrase_str = " ".join(current_phrase)
	
	# Check the last character that matches the current phrase
	if new_text == current_phrase_str:
		# User typed the whole phrase correctly, move to the next one
		_conclude_phrase()
	elif current_phrase_str.begins_with(new_text):
		# User is typing correctly so far
		has_wrong_char = false
		line_edit.add_theme_color_override("font_color", Color.LIME_GREEN)
	else:
		# User typed a wrong character
		has_wrong_char = true
		line_edit.add_theme_color_override("font_color", Color.RED)

func _conclude_phrase():
	completed_phrases += 1

	# Reset line edit
	line_edit.text = ""
	line_edit.add_theme_color_override("font_color", Color.WHITE)

	# Check if there are more phrases to type
	if completed_phrases >= current_phrases.size():
		# Hack minigame completed, emit signal to notify the main app
		hack_concluded.emit()
	else:
		# Mark current phrase as completed and update display
		update_display()
