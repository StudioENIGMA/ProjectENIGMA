class_name EmailData

extends Resource

var sender: String
var content: String
var attachments: Dictionary
var is_fake: bool

func _init(
  _sender: String = "",
  _content: String = "",
  _attachments: Dictionary = {},
  _is_fake: bool = false
) -> void:
  sender = _sender
  content = _content
  attachments = _attachments
  is_fake = _is_fake