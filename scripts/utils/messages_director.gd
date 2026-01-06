# res://scripts/story/messages/messages_director.gd
extends Node

@export var messages_dir_path: String = "res://data/messages"
@export var npc_messages_director:Node2D
@export var answers_director:Node2D

# thread_id -> thread_dict
var threads_by_id: Dictionary = {}

# Queue entries:
# {"thread_id":String, "branch":String, "index":int, "priority":int, "due_at":int, "seq":int}
var message_queue: Array[Dictionary] = []
var enqueue_seq: int = 0

func _ready() -> void:
	# MessagesDirector is the parent of AnswersDirector, so connecting here is fine.
	answers_director.answer_committed.connect(_on_answer_committed)

	reload_and_queue_today()


func reload_and_queue_today() -> void:
	_load_threads_from_directory()
	_queue_today_entry_points()


# -------------------------
# Loading
# -------------------------
func _load_threads_from_directory() -> void:
	threads_by_id.clear()

	var opened_dir := DirAccess.open(messages_dir_path)
	if opened_dir == null:
		push_error("MessagesDirector: Failed to open dir: %s" % messages_dir_path)
		return

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

	opened_dir.list_dir_end()


func _load_one_json_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MessagesDirector: Failed to open file: %s" % path)
		return

	var json_parser := JSON.new()
	var parse_error := json_parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error("MessagesDirector: JSON parse error (%s) in %s" % [json_parser.get_error_message(), path])
		return

	var root: Variant = json_parser.data

	if typeof(root) == TYPE_DICTIONARY and root.has("threads"):
		for thread_dict in root["threads"]:
			_register_thread(thread_dict, path)
	elif typeof(root) == TYPE_DICTIONARY and root.has("thread_id"):
		_register_thread(root, path)
	else:
		push_error("MessagesDirector: Unexpected JSON shape in %s" % path)


func _register_thread(thread_dict: Variant, source_path: String) -> void:
	if typeof(thread_dict) != TYPE_DICTIONARY:
		return

	var thread_id := str(thread_dict.get("thread_id", ""))
	if thread_id == "":
		push_error("MessagesDirector: thread_id missing in %s" % source_path)
		return

	if threads_by_id.has(thread_id):
		push_error("MessagesDirector: Duplicate thread_id '%s' in %s" % [thread_id, source_path])
		return

	threads_by_id[thread_id] = thread_dict


# -------------------------
# Scheduling
# -------------------------
func _queue_today_entry_points() -> void:
	message_queue.clear()
	enqueue_seq = 0

	for thread_id in threads_by_id.keys():
		var thread: Dictionary = threads_by_id[thread_id]
		var entry_points: Array = thread.get("entry_points", [])

		for entry in entry_points:
			if typeof(entry) != TYPE_DICTIONARY:
				continue

			if int(entry.get("day", -999)) != int(GameData.data.current_day):
				continue

			var requires: Array = entry.get("requires", [])
			if not _requirements_met(requires):
				continue

			var priority := int(entry.get("priority", 0))
			var branch := str(entry.get("branch", ""))
			if branch == "":
				continue

			_enqueue_branch_start(thread_id, branch, priority, _delay_for_priority(priority))


func _enqueue_branch_start(thread_id: String, branch: String, priority: int, delay_ticks: int) -> void:
	_enqueue_queue_entry({
		"thread_id": thread_id,
		"branch": branch,
		"index": 0,
		"priority": priority,
	}, delay_ticks)


func _enqueue_queue_entry(entry: Dictionary, delay_ticks: int) -> void:
	enqueue_seq += 1
	entry["seq"] = enqueue_seq
	entry["due_at"] = GameData.hours_minutes + max(delay_ticks, 0)
	_insert_sorted_by_due(entry)


func _insert_sorted_by_due(entry: Dictionary) -> void:
	var new_due := int(entry.get("due_at", 0))
	var new_priority := int(entry.get("priority", 0))
	var new_seq := int(entry.get("seq", 0))

	var insert_index := 0
	while insert_index < message_queue.size():
		var current := message_queue[insert_index]

		var current_due := int(current.get("due_at", 0))
		var current_priority := int(current.get("priority", 0))
		var current_seq := int(current.get("seq", 0))

		var current_before := (
			current_due < new_due
			or (current_due == new_due and current_priority < new_priority)
			or (current_due == new_due and current_priority == new_priority and current_seq < new_seq)
		)

		if not current_before:
			break

		insert_index += 1

	message_queue.insert(insert_index, entry)


func _delay_for_priority(priority: int) -> int:
	if priority <= 0:
		return 0
	return randi_range(2, 4)


# -------------------------
# Tick -> Deliver
# -------------------------
func on_clock_tick(current_minutes: int) -> void:
	if message_queue.is_empty():
		return

	var head: Dictionary = message_queue[0]
	if current_minutes < int(head["due_at"]):
		return

	message_queue.pop_front()
	_deliver_queue_entry(head, current_minutes)


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


# -------------------------
# Answer committed (from AnswersDirector)
# -------------------------
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


# -------------------------
# Requirements
# -------------------------
func _requirements_met(requires: Array) -> bool:
	if requires.is_empty():
		return true

	for req in requires:
		if typeof(req) != TYPE_DICTIONARY:
			continue

		var flag := str(req.get("flag", ""))
		var expected := bool(req.get("is", true))
		var actual := _read_flag(flag)

		if actual != expected:
			return false

	return true


func _read_flag(flag: String) -> bool:
	var app_map := {
		"settings": GameData.App.SETTINGS,
		"browser": GameData.App.BROWSER,
		"mail": GameData.App.EMAIL,
		"store": GameData.App.STORE,
		"fake_store": GameData.App.FAKESTORE,
	}

	if flag in app_map:
		return GameData.downloaded_apps.has(app_map[flag])

	var key := "has_%s" % flag
	if typeof(GameData.data) == TYPE_DICTIONARY and GameData.data.has(key):
		return bool(GameData.data[key])

	return false
