extends Node

## Short explanation:
##   Conversations are chats with NPCs made up of message branches (one json per conversation).
##   A conversation is identified by its "conversation_id"; "contact_name" is only the name shown
##   on the phone, so several conversations may share it (e.g. a scammer posing as a real contact)
##   Branches are sequences of messages, each message node can have choices for the player
##   that can lead to different branches or NPC replies


#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
## contact: The conversation the message belongs to, see _get_contact()
signal npc_message_created(contact: Dictionary)
signal npc_message_sent(
	contact: Dictionary,
	message: String,
	annex: Dictionary,
	sender: GameData.Sender,
	time: int
)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var answers_director: Node2D
#endregion CHILDREN NODES REFERENCES

#region STATE
var conversations_by_id: Dictionary = {}
#endregion STATE

#region SETUP
## Initializes connections to child directors
func _ready() -> void:
	answers_director.answer_committed.connect(_on_answer_committed)

## Sets up conversations from JSON roots (called by StoryDirector)
func setup_from_json_roots(json_roots: Array) -> void:
	conversations_by_id.clear()

	for root in json_roots:
		_register_conversations_from_root(root)

	_queue_today_entry_points()
#endregion SETUP

#region REGISTER CONVERSATIONS
## Registers conversations from a JSON root Variant
func _register_conversations_from_root(root: Variant) -> void:
	if typeof(root) == TYPE_DICTIONARY and root.has("conversations"):
		for conversation_dict in root["conversations"]:
			_register_one_conversation(conversation_dict)
		return

	if typeof(root) == TYPE_DICTIONARY and root.has("conversation_id"):
		_register_one_conversation(root)
		return

	assert(false) # bad JSON shape

## Registers a single conversation given its dictionary
func _register_one_conversation(conversation_dict: Variant) -> void:
	assert(typeof(conversation_dict) == TYPE_DICTIONARY)

	var conversation_id := str(conversation_dict["conversation_id"])
	assert(conversation_id != "")
	assert(not conversations_by_id.has(conversation_id))

	conversations_by_id[conversation_id] = conversation_dict
#endregion REGISTER CONVERSATIONS

#region SCHEDULING TODAY
## Queues today's entry points for all registered conversations
func _queue_today_entry_points() -> void:
	for conversation_id in conversations_by_id.keys():
		var conversation: Dictionary = conversations_by_id[conversation_id]
		var entry_points: Array = conversation.get("entry_points", [])

		for entry in entry_points:
			if typeof(entry) != TYPE_DICTIONARY:
				continue

			if int(entry.get("day", -999)) != int(GameData.current_day):
				continue

			var branch := str(entry.get("branch", ""))
			assert(branch != "")

			# Get absolute due time
			var relative_due_time: float = float(entry.get("relative_due_time", INF))
			assert(relative_due_time != INF)
			var absolute_due_time := int(relative_due_time) + int(GameData.starting_hours_minutes)

			# We must combine the requires of the whole branch with the first node of it
			var entry_requires: Array = entry.get("requires", [])
			var first_node_requires := _get_node_requires(conversation, branch, 0)

			var event_id = entry.get("event_id", "")
			# Signal upward to StoryDirector to schedule this entry point
			schedule_entry_requested.emit({
				"conversation_id": conversation_id,
				"branch": branch,
				"index": 0,
				"due_at": absolute_due_time,
				"requires": _combine_requires(entry_requires, first_node_requires),
				"event_id": event_id,
			})
#endregion SCHEDULING TODAY

#region DELIVERY (CALLED DOWN BY STORYDIRECTOR)
## Delivers a scheduled story entry (called by StoryDirector)
func deliver_scheduled_entry(schedule_entry: Dictionary, current_minutes: int) -> void:
	var conversation_id := str(schedule_entry["conversation_id"])
	var branch := str(schedule_entry["branch"])
	var node_index := int(schedule_entry["index"])

	# A conversation reported as a scam goes no further
	if GameData.blocked_conversations.has(conversation_id):
		return

	var conversation: Dictionary = conversations_by_id[conversation_id]
	var branches: Dictionary = conversation.get("branches", {})
	var branch_nodes: Array = branches.get(branch, [])

	var message_node: Dictionary = branch_nodes[node_index]
	var contact := _get_contact(conversation_id)

	# Emit NPC message
	npc_message_created.emit(contact)

	## Await animation time
	var wait_time: float = GameData.get_human_typing_time(message_node.get("text", ""))
	await  get_tree().create_timer(wait_time).timeout

	npc_message_sent.emit(
		contact,
		message_node.get("text", ""),
		message_node.get("annex", {}),
		GameData.Sender.NPC,
		current_minutes + wait_time
	)

	await  get_tree().create_timer(1).timeout

	# Handle choices if any
	var choices: Array = message_node.get("choices", [])
	if not choices.is_empty():
		answers_director.present_choices(
			contact,
			choices,
			GameData.hours_minutes
		)
		return

	# Schedule next node if any
	var next_index := node_index + 1
	if next_index < branch_nodes.size():
		var delay_minutes = message_node.get("delay_minutes", 2) # Default delay

		var next_node_requires := _get_node_requires(conversation, branch, next_index)

		var event_id := _get_event_id(conversation, branch, next_index)

		schedule_entry_requested.emit({
			"conversation_id": conversation_id,
			"branch": branch,
			"index": next_index,
			"due_at": current_minutes + delay_minutes,
			"requires": next_node_requires,
			"event_id": event_id
		})
#endregion DELIVERY

#region ANSWERS
## Handles answer_committed from AnswersDirector
func _on_answer_committed(
	conversation_id: String,
	choice: Dictionary,
) -> void:
	var delay_minutes := 2 # Default delay

	# Check if there's an NPC reply to schedule
	if choice.has("npc_reply"):
		var reply: Dictionary = choice.get("npc_reply", {})
		delay_minutes = int(reply.get("delay_ticks", 2))

		if reply.has("goto_branch"):
			var goto_branch := str(reply.get("goto_branch", ""))
			assert(goto_branch != "")

			var conversation: Dictionary = conversations_by_id[conversation_id]
			var first_node_requires := _get_node_requires(conversation, goto_branch, 0)

			schedule_entry_requested.emit({
				"conversation_id": conversation_id,
				"branch": goto_branch,
				"index": 0,
				"due_at": int(GameData.hours_minutes) + delay_minutes,
				"requires": first_node_requires,
			})
			return
#endregion ANSWERS

#region HELPERS
## Builds the contact a conversation is shown as on the phone
##
## "id" is the conversation_id, which is what the UI tells conversations apart by, so two
## conversations with the same contact_name are still separate chats.
## Optional fields: "avatar" (file name in assets/avatars/, defaults to the contact_name),
## "verified" (shows the verified badge, defaults to false) and "account" (the account name shown
## under the contact, defaults to the contact_name as a handle, see GameData.account_from_name()).
func _get_contact(conversation_id: String) -> Dictionary:
	var conversation: Dictionary = conversations_by_id[conversation_id]
	var npc_name := str(conversation.get("contact_name", conversation_id))
	var avatar := str(conversation.get("avatar", npc_name))

	return {
		"id": conversation_id,
		"name": npc_name,
		"photo": str("res://assets/avatars/", avatar, ".png"),
		"verified": bool(conversation.get("verified", false)),
		"account": str(conversation.get("account", GameData.account_from_name(npc_name))),
	}

## Gets the requires array for a given node in a conversation branch
func _get_node_requires(conversation: Dictionary, branch: String, index: int) -> Array:
	var branches: Dictionary = conversation.get("branches", {})
	var nodes: Array = branches.get(branch, [])
	assert(index >= 0 and index < nodes.size())

	var node: Dictionary = nodes[index]
	return node.get("requires", [])

func _get_event_id(conversation: Dictionary, branch: String, index: int) -> String:
	var branches: Dictionary = conversation.get("branches", {})
	var nodes: Array = branches.get(branch, [])
	assert(index >= 0 and index < nodes.size())

	var node: Dictionary = nodes[index]
	return node.get("event_id", "")	

## Combines two requires arrays into one
func _combine_requires(left: Array, right: Array) -> Array:
	if left.is_empty():
		return right
	if right.is_empty():
		return left
	var combined: Array = []
	combined.append_array(left)
	combined.append_array(right)
	return combined
#endregion HELPERS
