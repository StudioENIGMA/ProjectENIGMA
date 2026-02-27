extends Control

@export var news_title: Label
@export var news_metadata: Label
@export var news_content: Label


var _news_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	_news_data = data

	if is_inside_tree():
		_apply_data()

func _ready() -> void:
	_apply_data()

func _apply_data() -> void:
	if _news_data.is_empty():
		return

	if _news_data.has("title"):
		news_title.text = _news_data["title"]

	if _news_data.has("metadata"):
		news_metadata.text = _news_data["metadata"]

	if _news_data.has("content"):
		news_content.text = _news_data["content"]
