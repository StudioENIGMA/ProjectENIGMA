extends Control

## Average reading speed used to estimate the article's reading time
const WORDS_PER_MINUTE = 200

@export var news_title: Label
@export var news_metadata: Label
@export var news_content: Label
## Outlet name shown on the masthead, taken from the metadata's "outlet  •  time" text
@export var outlet_label: Label


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

	if _news_data.has("content"):
		news_content.text = _news_data["content"].strip_edges()

	if _news_data.has("metadata"):
		var parts: PackedStringArray = _news_data["metadata"].split("•", true, 1)
		outlet_label.text = parts[0].strip_edges().to_upper()
		var published := parts[1].strip_edges() if parts.size() > 1 else ""
		var reading_time := "Leitura de %d min" % _reading_minutes(news_content.text)
		news_metadata.text = "%s  •  %s" % [published, reading_time] if published else reading_time

func _reading_minutes(text: String) -> int:
	var words := text.split(" ", false).size()
	return maxi(1, ceili(words / float(WORDS_PER_MINUTE)))
