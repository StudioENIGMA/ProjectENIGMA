extends Control

signal subscreen_open_requested(subscreen_name:String, conversation_data:Dictionary)

const CONVERSATION_ROW_SCENE = preload("res://scenes/apps/messages/conversation_row.tscn")

@export var list_of_chats:VBoxContainer

var conversations_data:Array[Dictionary]

## Handles the player's answer to an NPC's message
##
## npc_name: The name of the NPC which the conversation is with
## message: The content of the player's answer
## title: The title of the answer option chosen
## reputation_points: The reputation points associated with the answer
## answer_id: The unique identifier for the answer option
func on_player_answer(
	npc_name:String,
	message:String,
	title:String,
	reputation_points:int,
	answer_id:int
) -> void:
	# Get conversation with the NPC
	var conversation_index = conversations_data.find_custom(
		func(conversation:Dictionary):return conversation["name"] == npc_name
	)

	# Should not happen, but just in case
	if conversation_index == -1:
		return

	# Append the player's answer option to the conversation
	conversations_data[conversation_index]["options"].append(
		{"message":message, "title":title, "reputation_points":reputation_points, "answer_id":answer_id}
	)

	# Update the conversation in the UI
	_update_list_of_chats(conversation_index)

## Handles the creation of a new message in the messaging app
##
## npc_name: The name of the NPC which the conversation is with
## message: The content of the message
## sender: Enum indicating who sent the message (ME or OTHER)
## time: The time the message was sent
func on_create_message(
	npc_name:String,
	message:String,
	sender:EventBus.Sender,
	time:String
):
	var conversation_index = conversations_data.find_custom(
		func(conversation:Dictionary):return conversation["name"] == npc_name
	)

	# Create new conversation if it doesn't exist
	if conversation_index == -1:
		var photo_path = str("res://assets/avatars/", npc_name, ".png")

		# Conversation should be at the top of the list
		conversations_data.push_front({
			"name":npc_name,
			"photo":photo_path,
			"messages":[{
				"message":message,
				"sender":sender,
				"time":time,
				"visualized":false
			}],
			"options":[]
		})
	else:
		# Append message to existing conversation
		conversations_data[conversation_index]["messages"].append({
			"message":message,
			"sender":sender,
			"time":time,
			"visualized":false
		})

		# Move conversation to the top of the list
		conversations_data.push_front(conversations_data.pop_at(conversation_index))

	# Update the conversation in the UI
	_update_list_of_chats(conversation_index)

## Updates the list of chats in the UI.
##
## When a new message is created, this function ensures that the corresponding
## conversation is either added to the top of the list or updated and moved to
## the top if it already exists.
##
## index: The index of the conversation in the conversations_data array.
func _update_list_of_chats(index:int) -> void:
	var conversation_row

	if index == -1:
		conversation_row = CONVERSATION_ROW_SCENE.instantiate()
		conversation_row.setup(conversations_data[0])
		conversation_row.open_chat_requested.connect(_on_open_chat)
		list_of_chats.add_child(conversation_row)
	else:
		conversation_row = list_of_chats.get_child(index)
		conversation_row.setup(conversations_data[0])

	list_of_chats.move_child(conversation_row, 0)

## Handles the request to open a chat conversation
##
## conversation_data: The data of the conversation to be opened
func _on_open_chat(conversation_data:Dictionary) -> void:
	subscreen_open_requested.emit("Messages_chat", conversation_data)
