extends Node2D

const CONVERSATION_ROW_SCENE = preload("res://scenes/conversation_row.tscn")

@onready var conversation_rows: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var conversations_data : Array[Dictionary]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.create_message.connect(_on_create_message)
	EventBus.storage_answer.connect(_on_storage_answer)
	EventBus.delete_answers.connect(_on_delete_answers)	

func _on_delete_answers(name : String) -> void:
	var conversation_index = conversations_data.find_custom(func(conversation : Dictionary) : return conversation["name"] == name)
	
	if conversation_index == -1:
		return
	
	conversations_data[conversation_index]["options"].clear()


func _on_storage_answer(name : String, message : String, title : String, reputation_points : int, answer_id : int) -> void:
	var conversation_index = conversations_data.find_custom(func(conversation : Dictionary) : return conversation["name"] == name)
	
	if conversation_index == -1:
		return
	
	conversations_data[conversation_index]["options"].append({"message" : message, "title" : title, "reputation_points" : reputation_points, "answer_id" : answer_id})

func _on_create_message(name : String, message : String, sender : EventBus.Sender, time : String):
	var conversation_index = conversations_data.find_custom(func(conversation : Dictionary) : return conversation["name"] == name)
	
	if  conversation_index == -1:
		var photo_path = str("res://assets/avatars/", name, ".png")
		conversations_data.push_front({"name" : name, "photo" : photo_path, "messages" : [{"message" : message, "sender" : sender, "time" : time, "visualized" : false}], "options" : []})
	else:
		conversations_data[conversation_index]["messages"].append({"message" : message, "sender" : sender, "time" : time, "visualized" : false})
		conversations_data.push_front(conversations_data.pop_at(conversation_index))
			
	update_conversation_rows(conversation_index)


func update_conversation_rows(index : int):
	if index == -1:
		var conversation_instance = CONVERSATION_ROW_SCENE.instantiate()
		conversation_rows.add_child(conversation_instance)
		conversation_instance.setup(conversations_data[0])
		conversation_rows.move_child(conversation_instance, 0)
	else:
		var conversation_instance = conversation_rows.get_child(index)
		conversation_instance.setup(conversations_data[0])
		conversation_rows.move_child(conversation_instance, 0)

	
