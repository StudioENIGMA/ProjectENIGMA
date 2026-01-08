# res://scripts/story/messages/messages_director.gd
extends Node

#region CHILDREN NODES REFERENCES
@export var messages_dir_path: String = "res://data/messages"
@export var npc_messages_director:Node2D
@export var answers_director:Node2D
#endregion CHILDREN NODES REFERENCES

# thread_id -> thread_dict
var threads_by_id: Dictionary = {}

# Queue entries:
# {"thread_id":String, "branch":String, "index":int, "priority":int, "due_at":int, "seq":int}
var message_queue: Array[Dictionary] = []
var enqueue_seq: int = 0

#region INITIALIZATION
## Connects signals and loads today's messages
func _ready() -> void:
	answers_director.answer_committed.connect(_on_answer_committed)

	reload_and_queue_today()

## Reloads all message threads and queues today's entry points
func reload_and_queue_today() -> void:
	_load_threads_from_directory()
	_queue_today_entry_points()
#endregion INITIALIZATION


#region LOADING MESSAGES
## Loads all message threads from JSON files in the messages directory
func _load_threads_from_directory() -> void:
	threads_by_id.clear()

	# Open directory
	var opened_dir := DirAccess.open(messages_dir_path)
	if opened_dir == null:
		push_error("MessagesDirector: Failed to open dir: %s" % messages_dir_path)
		return

	# Iterate files and load JSONs
	opened_dir.list_dir_begin()
	while true:
		var file_name := opened_dir.get_next()
		if file_name == "":
			break

		if opened_dir.current_is_dir():
			continue
		if file_name.begins_with("."):
			continue
		if file_name.get_extension().to_lower() != "json":
			continue

		var full_path := messages_dir_path.path_join(file_name)
		_load_one_json_file(full_path)

	# Close directory
	opened_dir.list_dir_end()

## Loads one JSON file and registers its threads
##
## @param path The full path to the JSON file
func _load_one_json_file(path: String) -> void:
	# Open file
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MessagesDirector: Failed to open file: %s" % path)
		return

	# Parse JSON
	var json_parser := JSON.new()
	var parse_error := json_parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"MessagesDirector: JSON parse error (%s) in %s" % [json_parser.get_error_message(), path]
		)
		return

	# Register threads
	var root: Variant = json_parser.data

	# Determine shape
	if typeof(root) == TYPE_DICTIONARY and root.has("threads"):
		for thread_dict in root["threads"]:
			_register_thread(thread_dict, path)
	elif typeof(root) == TYPE_DICTIONARY and root.has("thread_id"):
		_register_thread(root, path)
	else:
		push_error("MessagesDirector: Unexpected JSON shape in %s" % path)

## Registers one thread dictionary
##
## @param thread_dict The thread dictionary
## @param source_path The source file path (for error reporting)
func _register_thread(thread_dict: Variant, source_path: String) -> void:
	# Validate
	if typeof(thread_dict) != TYPE_DICTIONARY:
		return

	# Register
	var thread_id := str(thread_dict.get("thread_id", ""))
	if thread_id == "":
		push_error("MessagesDirector: thread_id missing in %s" % source_path)
		return

	# Check duplicates
	if threads_by_id.has(thread_id):
		push_error("MessagesDirector: Duplicate thread_id '%s' in %s" % [thread_id, source_path])
		return

	# Store
	threads_by_id[thread_id] = thread_dict
#endregion LOADING MESSAGES

#region QUEUING ENTRY POINTS
## Queues all entry points for today's day
func _queue_today_entry_points() -> void:
	message_queue.clear()
	enqueue_seq = 0

	# Iterate threads
	for thread_id in threads_by_id.keys():
		var thread: Dictionary = threads_by_id[thread_id]
		var entry_points: Array = thread.get("entry_points", [])

		# For each entry point, check if it matches today and enqueue if so
		for entry in entry_points:
			if typeof(entry) != TYPE_DICTIONARY:
				continue

			if int(entry.get("day", -999)) != int(GameData.data.current_day):
				continue

			var requires: Array = entry.get("requires", [])
			if not check_requirements_met_for_entry(requires):
				continue

			# Get messages (branch) for this entry, skip if missing
			var branch := str(entry.get("branch", ""))
			if branch == "":
				continue

			# Send message at due time, else don't send
			var relative_due_time = entry.get("relative_due_time", INF)

			# enqueue branch start
			_enqueue_queue_entry(
				thread_id,
				branch,
				relative_due_time + GameData.starting_hours_minutes # Enqueue from day start
			)

## This function will insert a branch start into the message queue
##
## The message queue is sorted by due time, if it collides its a queue
##
## @param thread_id The thread ID
## @param branch The branch name
## @param absolute_due_time The due time in minutes
func _enqueue_queue_entry(thread_id: String, branch: String, absolute_due_time: int) -> void:
	# Create the queue entry
	var queue_entry: Dictionary = {
		"thread_id": thread_id,
		"branch": branch,
		"due_at": absolute_due_time,
	}

	# Since the queue is ordered by due time, we need to insert it in the right place
	# Binary search insertion is possible, but overkill, we have dozens of messages at most
	for index in range(message_queue.size()):
		var existing_entry: Dictionary = message_queue[index]
		if int(existing_entry["due_at"]) > absolute_due_time:
			message_queue.insert(index, queue_entry)
			return

	# Append at the end if no earlier due time found
	message_queue.append(queue_entry)
#endregion QUEUING ENTRY POINTS

#region DELIVERY OF MESSAGES
## Called every clock tick to deliver due messages
##
## @param current_minutes The current time in minutes
func on_clock_tick(current_minutes: int) -> void:
	# If no messages to deliver there is nothing to do
	if message_queue.is_empty():
		return

	# Peek at head of queue, is is ordered by due time
	# If head is not due yet, nothing to do
	# Else, try to deliver the first message that can be delivered
	var head: Dictionary = message_queue[0]
	if current_minutes < int(head["due_at"]):
		return

	# Check if head has requirements met, if not check rest of queue
	var index := 0
	while index < message_queue.size():
		# Get entry
		var entry: Dictionary = message_queue[index]

		# As soon as we find an entry not due, stop checking
		if current_minutes < int(entry["due_at"]):
			break

		# Check requirements
		if check_requirements_met_for_entry(entry.get("requires", [])):
			# Deliver this entry and remove from queue
			_deliver_queue_entry(entry, current_minutes)
			message_queue.remove_at(index)
			return # Only deliver one per tick

		# Move to next entry if requirements not met
		index += 1


func _deliver_queue_entry(queue_entry: Dictionary, current_minutes: int) -> void:
	var thread_id := str(queue_entry.get("thread_id", ""))
	var thread: Dictionary = threads_by_id.get(thread_id, {})
	if thread.is_empty():
		return

	var branches: Dictionary = thread.get("branches", {})
	var branch_name := str(queue_entry.get("branch", ""))
	var branch_nodes: Array = branches.get(branch_name, [])

	var node_index := int(queue_entry.get("index", 0))
	if node_index < 0 or node_index >= branch_nodes.size():
		return

	var node: Dictionary = branch_nodes[node_index]

	if not _requirements_met(node.get("requires", [])):
		queue_entry["due_at"] = current_minutes + 1
		_insert_sorted_by_due(queue_entry)
		return

	# 1) Emit NPC message (call down into child director)
	npc_messages_director.send_npc_message(
		str(node.get("sender", thread_id)),
		str(node.get("text", "")),
		node.get("annex", {}),
		GameData.hours_minutes
	)

	# 2) If node has choices, delegate to AnswersDirector and STOP branch progression here.
	var choices: Array = node.get("choices", [])
	if not choices.is_empty():
		answers_director.present_choices(
			thread_id,
			branch_name,
			node_index,
			int(queue_entry.get("priority", 0)),
			node,
			choices,
			GameData.hours_minutes
		)
		return

	# 3) Otherwise continue to next node
	var next_index := node_index + 1
	if next_index < branch_nodes.size():
		var next_priority := int(node.get("priority", queue_entry.get("priority", 0)))
		_enqueue_queue_entry({
			"thread_id": thread_id,
			"branch": branch_name,
			"index": next_index,
			"priority": next_priority,
		}, _delay_for_priority(next_priority))
#endregion DELIVERY OF MESSAGES

#region REQUIREMENTS
## Checks if an entry can be enqueued based on its requirements
##
## @param requires The array of requirement dictionaries
func check_requirements_met_for_entry(requirements: Array) -> bool:
	if requirements.is_empty():
		return true

	for requirement in requirements:
		if typeof(requirement) != TYPE_DICTIONARY:
			continue

		# Requirement is a "flag" equals "expected"
		var flag := str(requirement.get("flag", ""))
		var expected := bool(requirement.get("is", true))
		var evaluation := _evaluate_flag(flag)

		# Check if matches expected
		if evaluation != expected:
			return false

	return true

## Evaluates a flag string into a boolean
##
## @param flag The flag string
func _evaluate_flag(flag: String) -> bool:
	# Check if flag is an app name, if so check if app is downloaded
	if flag in GameData.apps_name.keys():
		return GameData.downloaded_apps.has(GameData.apps_name[flag])

	return false
#endregion REQUIREMENTS

#region ANSWERS
func _on_answer_committed(
	thread_id: String,
	choice: Dictionary,
	origin_branch: String,
	origin_index: int,
	priority: int
) -> void:
	# Preferred path: npc_reply -> goto_branch after delay
	if choice.has("npc_reply"):
		var reply: Dictionary = choice.get("npc_reply", {})
		var delay_ticks := int(reply.get("delay_ticks", 0))

		if reply.has("goto_branch"):
			_enqueue_branch_start(thread_id, str(reply["goto_branch"]), priority, delay_ticks)
			return

	# Fallback: continue current branch after the choice node
	var thread: Dictionary = threads_by_id.get(thread_id, {})
	var branches: Dictionary = thread.get("branches", {})
	var origin_nodes: Array = branches.get(origin_branch, [])
	var next_index := origin_index + 1

	if next_index >= 0 and next_index < origin_nodes.size():
		_enqueue_queue_entry({
			"thread_id": thread_id,
			"branch": origin_branch,
			"index": next_index,
			"priority": priority,
		}, 0)
#endregion ANSWERS
