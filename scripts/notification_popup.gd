extends Node2D

@onready var content = $notification/content
@onready var title = $notification/title

var initial_content : String
var initial_title : String

func setup(content_ : String, title_ : String):
	self.initial_content = content_
	self.initial_title = title_

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content.text = initial_content
	title.text = initial_title

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
