class_name EmailData

extends Resource

var sender: String
var content: String
var attachments: Dictionary = {}

func _init(_sender: String, _content: String, _attachments: Dictionary = {}) -> void:
  sender = _sender
  content = _content
  attachments = _attachments
