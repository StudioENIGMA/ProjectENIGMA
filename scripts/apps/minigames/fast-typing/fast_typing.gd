extends Control

const PHRASE_SCENE = preload("res://scenes/apps/minigames/fast-typing/phrase_to_type.tscn")
const RANDOM_WORDS = ["apple", "banana", "cherry", "date", "elderberry", "fig", "grape", "honeydew"]

#region CHILDREN NODES REFERENCES
@export var line_edit: LineEdit
@export var phrases_vbox: VBoxContainer
#endregion

var current_phrases = []
var current_index = 0

func _ready():
	current_phrases.append(generate_random_phrase())

	for i in range(2):
		# Generate 2 bools, 1 for each extra phrase that may be added
		var random_bool = randf() < 0.5
		if random_bool:
			current_phrases.append(generate_random_phrase())

	update_display()

## Means hack minigame started
func setup():


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
		phrase_instance.setup(phrase, current_index)
		phrases_vbox.add_child(phrase_instance)
		current_index += 1
