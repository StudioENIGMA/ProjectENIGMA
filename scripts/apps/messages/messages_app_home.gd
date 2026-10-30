extends Control

signal subscreen_open_requested(subscreen_name:String, conversation_data:Dictionary)

const CONVERSATION_ROW_SCENE = preload("res://scenes/apps/messages/conversation_row.tscn")
## Prefix of the id given to conversations of saves made before conversations had ids
const LEGACY_ID_PREFIX = "legacy:"

## Hint of the empty state when the conversations of the days gone by are in the history
const EMPTY_HINT_WITH_HISTORY = (
	"As mensagens de hoje vão aparecer aqui. As dos dias anteriores ficam no Histórico."
)

@export var list_of_chats:VBoxContainer
@export var empty_state:CenterContainer
@export var empty_state_hint:Label
## Opens the conversations of the days gone by, on top of the list
@export var history_row:Control

var conversations_data:Array[Dictionary]
## Hint the empty state comes with, shown while there is no history yet
var _empty_hint_without_history:String

func _ready() -> void:
	_empty_hint_without_history = empty_state_hint.text
	self.visibility_changed.connect(_refresh_empty_state)
	history_row.open_requested.connect(_on_open_history)
	load_conversations(GameData.saved_messages_conversations)

## Handles the player's answer to an NPC's message
##
## conversation_id: The conversation the answer belongs to
## message: The content of the player's answer
## title: The title of the answer option chosen
## reputation_points: The reputation points associated with the answer
## answer_id: The unique identifier for the answer option
func on_player_answer(
	conversation_id:String,
	message:String,
	title:String,
	reputation_points:int,
	answer_id:int
) -> void:
	# Get conversation with the NPC
	var conversation_index = _find_conversation(conversation_id)

	# Should not happen, but just in case
	if conversation_index == -1:
		return

	# Append the player's answer option to the conversation
	conversations_data[conversation_index]["options"].append(
		{"message":message, "title":title, "reputation_points":reputation_points, "answer_id":answer_id}
	)
	_sync_conversations_to_game_data()

## Handles the creation of a new message in the messaging app
##
## contact: The conversation the message belongs to ("id", "name", "photo", "verified")
## message: The content of the message
## sender: Enum indicating who sent the message (ME or OTHER)
## time: The time the message was sent
func on_send_message(
	contact:Dictionary,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
):
	var conversation_index = _find_conversation(contact["id"])
	if conversation_index == -1:
		conversation_index = _adopt_legacy_conversation(contact)

	var current_date_dict = GameData.get_current_date_dict()

	# Create new conversation if it doesn't exist
	if conversation_index == -1:
		# Conversation should be at the top of the list
		conversations_data.push_front({
			"id":contact["id"],
			"name":contact["name"],
			"photo":contact["photo"],
			"verified":contact["verified"],
			"account":contact.get("account", ""),
			"notification_count": 1,
			"messages":[{
				"message":message,
				"annex":annex,
				"sender":sender,
				"time":time,
				"visualized":false,
				"date_dict": current_date_dict
			}],
			"options":[]
		})
	else:
		# Append message to existing conversation
		conversations_data[conversation_index]["messages"].append({
			"message":message,
			"annex":annex,
			"sender":sender,
			"time":time,
			"visualized":false,
			"date_dict": current_date_dict
		})
		conversations_data[conversation_index]["notification_count"] += 1

		# Move conversation to the top of the list
		conversations_data.push_front(conversations_data.pop_at(conversation_index))

	# Update the conversation in the UI
	_update_list_of_chats(conversation_index)
	_sync_conversations_to_game_data()

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
	_refresh_empty_state()

## Handles the request to open a chat conversation
##
## conversation_data: The data of the conversation to be opened
func _on_open_chat(conversation_data:Dictionary) -> void:
	subscreen_open_requested.emit(GameData.App.MESSAGESCHAT, conversation_data)

func on_delete_answers(conversation_id:String) -> void:
	var idx = _find_conversation(conversation_id)
	if idx == -1:
		return
	conversations_data[idx]["options"].clear()
	_update_list_of_chats(idx)
	_sync_conversations_to_game_data()

## Every day starts with an empty list: the conversations of the day that ended go to the history
func _on_start_new_day() -> void:
	# The day is counted when the next one is set, so the one that ended is the one before
	_archive_conversations(GameData.current_day - 1)

## Moves every conversation into the history as the conversations of a day gone by
##
## day: The day the conversations belong to
func _archive_conversations(day:int) -> void:
	if conversations_data.is_empty():
		return

	_add_to_history(day, conversations_data)

	conversations_data.clear()
	for child in list_of_chats.get_children():
		child.queue_free()
	_sync_conversations_to_game_data()
	_refresh_empty_state()

## Puts conversations in the history of a day, joining the ones already archived on it
##
## day: The day the conversations belong to
## conversations: The conversations, archived as copies with nothing left to answer
func _add_to_history(day:int, conversations:Array) -> void:
	var archived_conversations:Array[Dictionary] = []
	for conversation in conversations:
		var archived_conversation:Dictionary = conversation.duplicate(true)
		# The day is over: nothing is left to answer nor to read as new
		archived_conversation["options"] = []
		archived_conversation["notification_count"] = 0
		archived_conversations.append(archived_conversation)

	var history:Array = GameData.saved_messages_history
	if not history.is_empty() and int(history.back().get("day", -1)) == day:
		history.back()["conversations"].append_array(archived_conversations)
		return

	history.append({
		"day": day,
		"date_dict": conversations[0]["messages"].back().get("date_dict", {}),
		"conversations": archived_conversations,
	})

## Marks how the scam of a conversation ended, so the history shows it
##
## conversation_id: The conversation of the scam
## outcome: "fallen" when the player fell for it, "reported" when the player found it
func mark_outcome(conversation_id:String, outcome:String) -> void:
	var idx = _find_conversation(conversation_id)
	if idx == -1:
		return
	# Falling for it is what the player has to learn from, a late report does not hide it
	if conversations_data[idx].get("outcome", "") == "fallen":
		return
	conversations_data[idx]["outcome"] = outcome
	_sync_conversations_to_game_data()

func _on_open_history() -> void:
	subscreen_open_requested.emit(GameData.App.MESSAGESHISTORY, {})

func _sync_conversations_to_game_data() -> void:
	GameData.saved_messages_conversations = conversations_data.duplicate(true)

func load_conversations(saved_conversations: Array) -> void:
	conversations_data.clear()

	for child in list_of_chats.get_children():
		child.queue_free()

	for saved_conversation in saved_conversations:
		var restored_conversation: Dictionary = saved_conversation.duplicate(true)
		# Saves from before conversations had ids were told apart by the contact name
		if not restored_conversation.has("id"):
			restored_conversation["id"] = str(LEGACY_ID_PREFIX, restored_conversation["name"])
		conversations_data.append(restored_conversation)

		var conversation_row = CONVERSATION_ROW_SCENE.instantiate()
		conversation_row.setup(restored_conversation)
		conversation_row.open_chat_requested.connect(_on_open_chat)
		list_of_chats.add_child(conversation_row)

	_refresh_empty_state()

func on_delete_conversation(conversation_id: String) -> void:
	var idx = _find_conversation(conversation_id)
	if idx == -1:
		return
	# A scam blocked after being reported leaves the list, but the history keeps how it ended
	if conversations_data[idx].has("outcome"):
		_add_to_history(GameData.current_day, [conversations_data[idx]])
	conversations_data.remove_at(idx)
	_sync_conversations_to_game_data()

	for child in list_of_chats.get_children():
		if child.conversation_data.get("id", "") == conversation_id:
			child.queue_free()
			break

	_refresh_empty_state()

## Keeps the empty state and the history row in sync with the list
func _refresh_empty_state() -> void:
	var has_history:bool = not GameData.saved_messages_history.is_empty()
	empty_state.visible = conversations_data.is_empty()
	empty_state_hint.text = EMPTY_HINT_WITH_HISTORY if has_history else _empty_hint_without_history

	history_row.visible = has_history
	if has_history:
		history_row.setup(GameData.saved_messages_history)

## Position of a conversation in conversations_data, -1 when there is none
##
## conversation_id: The conversation_id of the conversation's JSON
func _find_conversation(conversation_id:String) -> int:
	return conversations_data.find_custom(
		func(conversation:Dictionary):return conversation["id"] == conversation_id
	)

## Hands a conversation restored from an old save over to the contact now writing in it
##
## Old saves only know the contact name, so the first conversation of the same name
## takes the contact's id instead of a duplicate chat being created.
## Returns its position, -1 when there is none.
##
## contact: The contact sending the message
func _adopt_legacy_conversation(contact:Dictionary) -> int:
	var index := _find_conversation(str(LEGACY_ID_PREFIX, contact["name"]))
	if index != -1:
		conversations_data[index]["id"] = contact["id"]
	return index
