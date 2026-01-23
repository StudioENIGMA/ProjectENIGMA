extends Control

@export var news_content: Label
@export var news_metadata: Label

func setup(data: Dictionary) -> void:
    if data.has("title"):
        news_content.text = data["title"] 
    if data.has("metadata"):
        news_metadata.text = data["metadata"]

func _ready() -> void:
    print("abriu")