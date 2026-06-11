extends VBoxContainer

#region CHILDREN NODES REFERENCES
@export var profile_picture:Control
@export var sender_label: Label
@export var hour_received_label: Label
@export var content_label: Label
#endregion CHILDREN NODES REFERENCES

func setup(email_data: Dictionary) -> void:
  var npc_name = email_data.get("sender")
  var photo_path = str("res://assets/avatars/", npc_name, ".png")

  profile_picture.setup(photo_path, npc_name)
  sender_label.text = email_data.get("sender")
  hour_received_label.text = GameData.hours_minutes_as_string(email_data.get("relative_due_time"))
  content_label.text = email_data.get("content")
