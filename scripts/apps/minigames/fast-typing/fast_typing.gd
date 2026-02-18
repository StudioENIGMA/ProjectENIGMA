extends Control


#region CHILDREN NODES REFERENCES
@export var text_to_type1: RichTextLabel
@export var text_to_type2: RichTextLabel
@export var player_type_space: LineEdit
@export var minigame_timer: MarginContainer
#endregion

var bytes_of_text_to_type1: PackedByteArray
var bytes_of_text_to_type2: PackedByteArray
var first_completed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bytes_of_text_to_type1 = text_to_type1.text.to_utf8_buffer()
	bytes_of_text_to_type2 = text_to_type1.text.to_utf8_buffer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func verify_correct_text() -> void:
	var bytes_of_player_text: PackedByteArray = player_type_space.text.to_utf8_buffer()
	for i in range(player_type_space.text.length()):
		if first_completed:
			if bytes_of_text_to_type2[i] == bytes_of_player_text[i]:
				

	

