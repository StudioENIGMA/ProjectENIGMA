extends Node2D

const CONVERSATION_ROW_SCENE = preload("res://scenes/conversation_row.tscn")

@onready var conversation_rows: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var conversation_data : Array[Dictionary]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.send_message.connect(_on_send_message)

func _on_send_message(name : String, message : String, time : int):
	var conversation_index = conversation_data.find_custom(func(conversation : Dictionary) : return conversation["name"] == name)
	
	if  conversation_index == -1:
		var photo_path = str("res://assets/avatars/", name, ".png")
		conversation_data.push_front({"name" : name, "photo" : photo_path, "messages" : [{"message" : message, "sender" : name, "time" : time, "visualized" : false}]})
	else:
		conversation_data[conversation_index]["messages"].append({"message" : message, "sender" : name, "time" : time, "visualized" : false})
		conversation_data.push_front(conversation_data.pop_at(conversation_index))
			
	update_conversation_rows(conversation_index)


func update_conversation_rows(index : int):
	if index == -1:
		var conversation_instance = CONVERSATION_ROW_SCENE.instantiate()
		conversation_rows.add_child(conversation_instance)
		conversation_instance.setup(conversation_data[0])
		conversation_rows.move_child(conversation_instance, 0)
	else:
		var conversation_instance = conversation_rows.get_child(index)
		conversation_instance.setup(conversation_data[0])
		conversation_rows.move_child(conversation_instance, 0)

	
