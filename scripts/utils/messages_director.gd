extends Node

## Short explanation:
##   Threads are conversations with NPCs made up of message branches (a specific json with an NPC)
##   Branches are sequences of messages, each message node can have choices for the player
##   that can lead to different branches or NPC replies


#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
signal npc_message_created(
	npc_name: String,
	message: String,
	annex: Dictionary,
	sender: GameData.Sender,
	time: int
)
signal npc_message_sent(
	npc_name: String,
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
var threads_by_id: Dictionary = {}
#endregion STATE

#region SETUP
## Initializes connections to child directors
func _ready() -> void:
	answers_director.answer_committed.connect(_on_answer_committed)

## Sets up threads from JSON roots (called by StoryDirector)
func setup_from_json_roots(json_roots: Array) -> void:
	threads_by_id.clear()

	for root in json_roots:
		_register_threads_from_root(root)

	_queue_today_entry_points()
#endregion SETUP

#region REGISTER THREADS
## Registers threads from a JSON root Variant
func _register_threads_from_root(root: Variant) -> void:
	if typeof(root) == TYPE_DICTIONARY and root.has("threads"):
		for thread_dict in root["threads"]:
			_register_one_thread(thread_dict)
		return

	if typeof(root) == TYPE_DICTIONARY and root.has("thread_id"):
		_register_one_thread(root)
		return

	assert(false) # bad JSON shape

## Registers a single thread given its dictionary
func _register_one_thread(thread_dict: Variant) -> void:
	assert(typeof(thread_dict) == TYPE_DICTIONARY)

	var thread_id := str(thread_dict["thread_id"])
	assert(thread_id != "")
	assert(not threads_by_id.has(thread_id))

	threads_by_id[thread_id] = thread_dict
#endregion REGISTER THREADS

#region SCHEDULING TODAY
## Queues today's entry points for all registered threads
func _queue_today_entry_points() -> void:
	for thread_id in threads_by_id.keys():
		var thread: Dictionary = threads_by_id[thread_id]
		var entry_points: Array = thread.get("entry_points", [])

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
			var first_node_requires := _get_node_requires(thread, branch, 0)

			# Signal upward to StoryDirector to schedule this entry point
			schedule_entry_requested.emit({
				"thread_id": thread_id,
				"branch": branch,
				"index": 0,
				"due_at": absolute_due_time,
				"requires": _combine_requires(entry_requires, first_node_requires),
			})
#endregion SCHEDULING TODAY

#region DELIVERY (CALLED DOWN BY STORYDIRECTOR)
## Delivers a scheduled story entry (called by StoryDirector)
func deliver_scheduled_entry(schedule_entry: Dictionary, current_minutes: int) -> void:
	var thread_id := str(schedule_entry["thread_id"])
	var branch := str(schedule_entry["branch"])
	var node_index := int(schedule_entry["index"])

	var thread: Dictionary = threads_by_id[thread_id]
	var branches: Dictionary = thread.get("branches", {})
	var branch_nodes: Array = branches.get(branch, [])

	var message_node: Dictionary = branch_nodes[node_index]

	# Emit NPC message
	npc_message_created.emit(
		thread.get("sender", thread_id),
	)

	## Await animation time
	var wait_time: float = GameData.get_human_typing_time(message_node.get("text", ""))
	await  get_tree().create_timer(wait_time).timeout

	npc_message_sent.emit(
		thread.get("sender", thread_id),
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
			thread_id,
			thread.get("sender", thread_id),
			choices,
			GameData.hours_minutes
		)
		return

	# Schedule next node if any
	var next_index := node_index + 1
	if next_index < branch_nodes.size():
		var delay_minutes = message_node.get("delay_minutes", 2) # Default delay

		var next_node_requires := _get_node_requires(thread, branch, next_index)

		schedule_entry_requested.emit({
			"thread_id": thread_id,
			"branch": branch,
			"index": next_index,
			"due_at": current_minutes + delay_minutes,
			"requires": next_node_requires,
		})
#endregion DELIVERY

#region ANSWERS
## Handles answer_committed from AnswersDirector
func _on_answer_committed(
	thread_id: String,
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

			var thread: Dictionary = threads_by_id[thread_id]
			var first_node_requires := _get_node_requires(thread, goto_branch, 0)

			schedule_entry_requested.emit({
				"thread_id": thread_id,
				"branch": goto_branch,
				"index": 0,
				"due_at": int(GameData.hours_minutes) + delay_minutes,
				"requires": first_node_requires,
			})
			return
#endregion ANSWERS

#region HELPERS
## Gets the requires array for a given node in a thread branch
func _get_node_requires(thread: Dictionary, branch: String, index: int) -> Array:
	var branches: Dictionary = thread.get("branches", {})
	var nodes: Array = branches.get(branch, [])
	assert(index >= 0 and index < nodes.size())

	var node: Dictionary = nodes[index]
	return node.get("requires", [])

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
