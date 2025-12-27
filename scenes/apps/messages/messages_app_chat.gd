extends Control

## Request the UI main node to send a notification
##
## app: The application the notification is related to (Messages)
## content: The content of the notification
## title: The title of the notification
## time: Duration the notification should be displayed
signal request_message_notification(
	app:EventBus.App,
  content:String,
  title:String,
  time:String
)

const MY_MESSAGE = preload("res://scenes/apps/messages/my_message.tscn")
const OTHERS_MESSAGE = preload("res://scenes/apps/messages/others_message.tscn")

@export var messages_list:VBoxContainer

var conversation_name:String = ""

func setup(conversation_data:Dictionary) -> void:
	conversation_name = conversation_data["name"]

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

func on_create_message(
	npc_name:String,
	message:String,
	sender:EventBus.Sender,
	time:String
) -> void:
	# Check if the message belongs to the currently open conversation
	if npc_name != conversation_name:
		# Notify new message received
		if sender == EventBus.Sender.OTHER:
			request_message_notification.emit(
				EventBus.App.MESSAGES,
				message,
				npc_name,
				time
			)
		return

	# Add the new message to the messages list
	var message_instance:MarginContainer;
	if sender == EventBus.Sender.ME:
		message_instance = MY_MESSAGE.instantiate()
	else:
		message_instance = OTHERS_MESSAGE.instantiate()

	messages_list.add_child(message_instance)
	message_instance.setup(message)