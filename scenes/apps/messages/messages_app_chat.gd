extends Control

const MY_MESSAGE = preload("res://scenes/apps/messages/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/apps/messages/others_message.tscn")

@export var messages_list:VBoxContainer

func setup(conversation_data:Dictionary) -> void:
	for child_node in messages_list.get_children():
		messages_list.remove_child(child_node)
		child_node.queue_free()

	for message in conversation_data["messages"]:
		var message_instance:MarginContainer;
		if message.sender == EventBus.Sender.ME:
			message_instance = MY_MESSAGE.instantiate()
		else:
			message_instance = OTHERS_MESSAGE.instantiate()

		messages_list.add_child(message_instance)
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

	#scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
