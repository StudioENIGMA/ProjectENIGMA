extends Node

#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var npc_messages_director: Node2D
@export var answers_director: Node2D
#endregion CHILDREN NODES REFERENCES

#region STATE
# thread_id -> thread_dict
var threads_by_id: Dictionary = {}
#endregion STATE

#region SETUP
func _ready() -> void:
	answers_director.answer_committed.connect(_on_answer_committed)

func setup_from_json_roots(json_roots: Array) -> void:
	threads_by_id.clear()

	for root in json_roots:
		_register_threads_from_root(root)

	_queue_today_entry_points()
#endregion SETUP

#region REGISTER THREADS
func _register_threads_from_root(root: Variant) -> void:
	if typeof(root) == TYPE_DICTIONARY and root.has("threads"):
		for thread_dict in root["threads"]:
			_register_one_thread(thread_dict)
		return

	if typeof(root) == TYPE_DICTIONARY and root.has("thread_id"):
		_register_one_thread(root)
		return

	assert(false) # bad JSON shape

func _register_one_thread(thread_dict: Variant) -> void:
	assert(typeof(thread_dict) == TYPE_DICTIONARY)

	var thread_id := str(thread_dict["thread_id"])
	assert(thread_id != "")
	assert(not threads_by_id.has(thread_id))

	threads_by_id[thread_id] = thread_dict
#endregion REGISTER THREADS

#region SCHEDULING TODAY
func _queue_today_entry_points() -> void:
	for thread_id in threads_by_id.keys():
		var thread: Dictionary = threads_by_id[thread_id]
		var entry_points: Array = thread.get("entry_points", [])

		for entry in entry_points:
			if typeof(entry) != TYPE_DICTIONARY:
				continue

			if int(entry.get("day", -999)) != int(GameData.data.current_day):
				continue

			var branch := str(entry.get("branch", ""))
			assert(branch != "")

			var relative_due_time: float = float(entry.get("relative_due_time", INF))
			assert(relative_due_time != INF)

			var absolute_due_time := int(relative_due_time) + int(GameData.starting_hours_minutes)

			var entry_requires: Array = entry.get("requires", [])
			var first_node_requires := _get_node_requires(thread, branch, 0)

			schedule_entry_requested.emit({
				"thread_id": thread_id,
				"branch": branch,
				"index": 0,
				"due_at": absolute_due_time,
				"requires": _combine_requires(entry_requires, first_node_requires),
			})
#endregion SCHEDULING TODAY

#region DELIVERY (CALLED DOWN BY STORYDIRECTOR)
func deliver_scheduled_entry(schedule_entry: Dictionary, current_minutes: int) -> void:
	var thread_id := str(schedule_entry["thread_id"])
	var branch := str(schedule_entry["branch"])
	var node_index := int(schedule_entry["index"])

	var thread: Dictionary = threads_by_id[thread_id]
	var branches: Dictionary = thread.get("branches", {})
	var branch_nodes: Array = branches.get(branch, [])

	var node: Dictionary = branch_nodes[node_index]

	npc_messages_director.send_npc_message(
		str(node.get("sender", thread_id)),
		str(node.get("text", "")),
		node.get("annex", {}),
		GameData.hours_minutes
	)

	var choices: Array = node.get("choices", [])
	if not choices.is_empty():
		answers_director.present_choices(
			thread_id,
			node,
			choices,
			GameData.hours_minutes
		)
		return

	var next_index := node_index + 1
	if next_index < branch_nodes.size():
		var delay_minutes := int(node.get("delay_minutes", 2))
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
func _on_answer_committed(
	thread_id: String,
	choice: Dictionary,
) -> void:
	var delay_minutes := 2

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
func _get_node_requires(thread: Dictionary, branch: String, index: int) -> Array:
	var branches: Dictionary = thread.get("branches", {})
	var nodes: Array = branches.get(branch, [])
	assert(index >= 0 and index < nodes.size())

	var node: Dictionary = nodes[index]
	return node.get("requires", [])

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
