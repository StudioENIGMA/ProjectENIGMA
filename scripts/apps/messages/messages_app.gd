extends Node2D

const ANSWER_OPTION = preload("res://scenes/apps/messages/answer_option.tscn")
const MY_MESSAGE = preload("res://scenes/apps/messages/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/apps/messages/others_message.tscn")

@export var list_of_chats:VBoxContainer

func _ready() -> void:
	

func _on_open_chat(conversation_data:Dictionary):
	current_contact = conversation_data["name"]

	# update chat data
	for node in chat_box.get_children():
		node.queue_free()

	for message in conversation_data["messages"]:
		var message_instance:MarginContainer;
		if message.sender == EventBus.Sender.ME:
			message_instance = MY_MESSAGE.instantiate()
		else:
			message_instance = OTHERS_MESSAGE.instantiate()

		chat_box.add_child(message_instance)
		message_instance.setup(message.message)

	for option in conversation_data["options"]:
		EventBus.answer_option.emit(
			conversation_data.name,
			option.message,
			option.title,
			option.reputation_points,
			-2,
			option.answer_id
		)

	await get_tree().create_timer(0.04).timeout
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
	# Hide Home
	home.visible = false

func _on_create_answer_option(
	npc_name:String,
	title:String,
	message:String,
	answer_id:int
) -> void:
	if npc_name != current_contact:
		return

	var answer_option_instance = ANSWER_OPTION.instantiate()
	options_container.add_child(answer_option_instance)
	answer_option_instance.setup(npc_name, title, message, answer_id)

func _on_create_message(
	npc_name:String,
	message:String,
	sender:EventBus.Sender,
	time : String,
) -> void:
	if npc_name != current_contact:
		return

	var message_instance;
	if sender == EventBus.Sender.ME:
		message_instance = MY_MESSAGE.instantiate()
	else:
		message_instance = OTHERS_MESSAGE.instantiate()

	chat_box.add_child(message_instance)
	message_instance.setup(message)

	scroll_container.scroll_to_bottom()
