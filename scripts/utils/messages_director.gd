extends Node

#region CHILDREN NODES REFERENCES
@export var messages_dir_path: String = "res://data/messages"
@export var npc_messages_director: Node2D
@export var answers_director: Node2D
#endregion CHILDREN NODES REFERENCES

# thread_id -> thread_dict
var threads_by_id: Dictionary = {}

# Queue entries:
# {"thread_id":String, "branch":String, "index":int, "due_at":int, "seq":int, "requires":Array}
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

			var branch := str(entry.get("branch", ""))
			if branch == "":
				continue

			# Use float for INF comparison
			var relative_due_time: float = float(entry.get("relative_due_time", INF))
			if relative_due_time == INF:
				# No due time => don't schedule.
				continue

			# Get absolute due time (Back as int)
			var absolute_due_time := int(relative_due_time) + int(GameData.starting_hours_minutes)

			# Keep requires on the queue entry so it can become valid later in the same day.
			var requires: Array = entry.get("requires", [])

			_enqueue_queue_entry(thread_id, branch, absolute_due_time, 0, requires)

## Enqueue a branch/node into the message queue (sorted by due_at, then seq)
func _enqueue_queue_entry(
	thread_id: String,
	branch: String,
	absolute_due_time: int,
	index: int = 0,
	requires: Array = []
) -> void:
	var queue_entry: Dictionary = {
		"thread_id": thread_id,
		"branch": branch,
		"index": index,
		"due_at": absolute_due_time,
		"seq": enqueue_seq,
		"requires": requires,
	}
	enqueue_seq += 1 # Global sequence to preserve order of insertion

	_insert_sorted_by_due(queue_entry)

## Inserts an entry preserving ordering by due_at then seq
func _insert_sorted_by_due(queue_entry: Dictionary) -> void:
	var due_at := int(queue_entry.get("due_at", 0))
	var seq := int(queue_entry.get("seq", 0))

	# Find insertion point (binary search is overkill)
	for i in range(message_queue.size()):
		var existing := message_queue[i]
		var existing_due := int(existing.get("due_at", 0))
		if existing_due > due_at:
			message_queue.insert(i, queue_entry)
			return

		if existing_due == due_at and int(existing.get("seq", 0)) > seq:
			message_queue.insert(i, queue_entry)
			return

	# Append at end if no earlier point found
	message_queue.append(queue_entry)

## Enqueues the start of a branch at an absolute due time for convenience
func _enqueue_branch_start(thread_id: String, branch: String, absolute_due_time: int) -> void:
	_enqueue_queue_entry(thread_id, branch, absolute_due_time, 0, [])
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
	# If head is not due yet, nothing to do (as it is ordered)
	# Else, try to deliver the first message that can be delivered
	var head: Dictionary = message_queue[0]
	if current_minutes < int(head.get("due_at", 0)):
		return

	# Check if head has requirements met, if not check rest of queue
	var index := 0
	while index < message_queue.size():
		# Get entry
		var entry: Dictionary = message_queue[index]

		if current_minutes < int(entry.get("due_at", 0)):
			break

		# Entry-point requirements (allows “become true later” behavior)
		if not _requirements_met(entry.get("requires", [])):
			entry["due_at"] = current_minutes + 1
			message_queue.remove_at(index)
			_insert_sorted_by_due(entry)
			return

		_deliver_queue_entry(entry, current_minutes)
		message_queue.remove_at(index)
		return # Only deliver one per tick

## Delivers one queue entry (assumes requirements are met)
##
## @param queue_entry The queue entry to deliver
## @param current_minutes The current time in minutes
func _deliver_queue_entry(queue_entry: Dictionary, current_minutes: int) -> void:
	# Thread is the conversation (such as boss messages)
	var thread_id := str(queue_entry.get("thread_id", ""))
	var thread: Dictionary = threads_by_id.get(thread_id, {})
	if thread.is_empty():
		return

	# Branch is a sequence of nodes within the conversation
	var branches: Dictionary = thread.get("branches", {})
	var branch_name := str(queue_entry.get("branch", ""))
	var branch_nodes: Array = branches.get(branch_name, [])

	var node_index := int(queue_entry.get("index", 0))
	if node_index < 0 or node_index >= branch_nodes.size():
		return

	var node: Dictionary = branch_nodes[node_index]

	# Each node (message) may have its own requirements, if not met, requeue
	# The requeue is done from the current index
	if not _requirements_met(node.get("requires", [])):
		queue_entry["due_at"] = current_minutes + 1
		_insert_sorted_by_due(queue_entry)
		return

	# Emit NPC message (call down into child director)
	npc_messages_director.send_npc_message(
		str(node.get("sender", thread_id)), # Npc name
		str(node.get("text", "")), # Message text
		node.get("annex", {}), # Annex if any
		GameData.hours_minutes # Time
	)

	# If node has choices, delegate to AnswersDirector and STOP branch progression here
	# We stop until an answer is committed
	var choices: Array = node.get("choices", [])
	if not choices.is_empty():
		answers_director.present_choices(
			thread_id,
			node,
			choices,
			GameData.hours_minutes
		)
		return

	# Otherwise continue to next node (optional delay, util for answers replies)
	var next_index := node_index + 1
	if next_index < branch_nodes.size():
		var delay_minutes := int(node.get("delay_minutes", 2)) # Default delay
		_enqueue_queue_entry(
			thread_id,
			branch_name,
			current_minutes + delay_minutes,
			next_index,
			[]
		)
#endregion DELIVERY OF MESSAGES

#region REQUIREMENTS
## Checks if all requirements in the array are met
##
## @param requirements An array of requirement dictionaries
func _requirements_met(requirements: Array) -> bool:
	if requirements.is_empty():
		return true

	for requirement in requirements:
		var flag := str(requirement.get("flag", ""))
		var expected := bool(requirement.get("is", true))
		var evaluation := _evaluate_flag(flag)

		if evaluation != expected:
			return false

	return true

## Evaluates a flag string into a boolean
##
## @param flag The flag string to evaluate
func _evaluate_flag(flag: String) -> bool:
	# Check if flag is an app name, if so check if app is downloaded
	if flag in GameData.apps_name.keys():
		return GameData.downloaded_apps.has(GameData.apps_name[flag])

	return false
#endregion REQUIREMENTS

#region ANSWERS
## Handles an answer being committed
##
## @param thread_id The thread ID
## @param choice The choice dictionary
func _on_answer_committed(
	thread_id: String,
	choice: Dictionary,
) -> void:
	var delay_ticks:int

	if choice.has("npc_reply"):
		var reply: Dictionary = choice.get("npc_reply", {})
		delay_ticks = int(reply.get("delay_ticks", 2)) # Default delay

		# Send NPC reply message if any
		if reply.has("goto_branch"):
			var goto_branch := str(reply.get("goto_branch", ""))
			if goto_branch != "":
				_enqueue_branch_start(
					thread_id,
					goto_branch,
					int(GameData.hours_minutes) + delay_ticks
				)
				return
#endregion ANSWERS
