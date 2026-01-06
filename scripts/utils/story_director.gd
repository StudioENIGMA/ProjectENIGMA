extends Node2D

signal npc_message_created(
	npc_name: String,
	message: String,
	annex: Dictionary,
	sender: GameData.Sender,
	time: int
)

signal request_answer_option(
	npc_name: String,
	message: String,
	title: String,
	reputation_points: int,
	time: int,
	answer_id: int
)

signal news_ready(day_news_data: Dictionary)

@export var ui: Control
@export var event_handler: Node2D
@export var messages_dir_path: String = "res://data/messages"
@export var news_dir_path: String = "res://data/news.json"

# thread_id -> {"thread_id":..., "entry_points":[...], "branches":{ branch_name: [node,...] } }
var threads_by_id: Dictionary = {}

# Sorted queue entries:
# {"thread_id":String, "branch":String, "index":int, "priority":int, "due_at":int}
var message_queue: Array[Dictionary] = []
var enqueue_seq: int = 0

# answer_id -> {"thread_id":String, "choice":Dictionary, "origin":Dictionary, "priority":int}
var answer_state_by_id: Dictionary = {}
var next_answer_id: int = 1


func _ready() -> void:
	ui.message_answered.connect(_on_message_answered)
	event_handler.clock_tick.connect(_on_clock_tick)

	_load_threads_from_directory()
	_queue_today_entry_points()


# -------------------------
# Loading
# -------------------------
func _load_threads_from_directory() -> void:
	threads_by_id.clear()

	var dir := DirAccess.open(messages_dir_path)
	if dir == null:
		push_error("StoryDirectorJSON: Failed to open dir: %s" % messages_dir_path)
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break

		# Skip folders and hidden files
		if dir.current_is_dir():
			continue
		if file_name.begins_with("."):
			continue

		# Only JSON files
		if file_name.get_extension().to_lower() != "json":
			continue

		var full_path := messages_dir_path.path_join(file_name)
		_load_one_json_file(full_path)

	dir.list_dir_end()


func _load_one_json_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("StoryDirectorJSON: Failed to open file: %s" % path)
		return

	var parser := JSON.new()
	var err := parser.parse(file.get_as_text())
	if err != OK:
		push_error("StoryDirectorJSON: JSON parse error (%s) in %s" % [parser.get_error_message(), path])
		return

	var root: Variant = parser.data

	# Supports:
	# 1) { "thread_id": "...", ... }
	# 2) { "threads": [ {thread...}, ... ] }
	if typeof(root) == TYPE_DICTIONARY and root.has("threads"):
		for thread_dict in root["threads"]:
			_register_thread(thread_dict, path)
	elif typeof(root) == TYPE_DICTIONARY and root.has("thread_id"):
		_register_thread(root, path)
	else:
		push_error("StoryDirectorJSON: Unexpected JSON shape in %s" % path)


func _register_thread(thread_dict: Variant, source_path: String) -> void:
	if typeof(thread_dict) != TYPE_DICTIONARY:
		return

	var thread_id := str(thread_dict.get("thread_id", ""))
	if thread_id == "":
		push_error("StoryDirectorJSON: thread_id missing in %s" % source_path)
		return

	if threads_by_id.has(thread_id):
		# Choose one behavior:
		# 1) override
		# 2) skip and warn
		push_error("StoryDirectorJSON: Duplicate thread_id '%s' in %s" % [thread_id, source_path])
		return

	threads_by_id[thread_id] = thread_dict

# -------------------------
# Scheduling
# -------------------------
func _queue_today_entry_points() -> void:
	message_queue.clear()

	for thread_id in threads_by_id.keys():
		var thread: Dictionary = threads_by_id[thread_id]
		var entry_points: Array = thread.get("entry_points", [])

		for entry in entry_points:
			if typeof(entry) != TYPE_DICTIONARY:
				continue

			if int(entry.get("day", -999)) != int(GameData.data.current_day):
				continue

			# IMPORTANT: entry_points are "select one branch" style gates.
			# If unmet now, we skip (do NOT postpone), otherwise the "other branch"
			# could accidentally fire later.
			var requires: Array = entry.get("requires", [])
			if not _requirements_met(requires):
				continue

			var priority := int(entry.get("priority", 0))
			var branch := str(entry.get("branch", ""))
			if branch == "":
				continue

			_enqueue_branch_start(thread_id, branch, priority, _delay_for_priority(priority))


func _enqueue_branch_start(
	thread_id: String,
	branch: String,
	priority: int,
	delay_ticks: int
) -> void:
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
	var new_pri := int(entry.get("priority", 0))
	var new_seq := int(entry.get("seq", 0))

	var insert_index := 0
	while insert_index < message_queue.size():
		var cur := message_queue[insert_index]

		var cur_due := int(cur.get("due_at", 0))
		var cur_pri := int(cur.get("priority", 0))
		var cur_seq := int(cur.get("seq", 0))

		# cur comes before entry if:
		# 1) earlier due_at
		# 2) same due_at but smaller priority (more negative = higher priority)
		# 3) same due_at & priority but smaller seq (earlier enqueue)
		var cur_before := (
			cur_due < new_due
			or (cur_due == new_due and cur_pri < new_pri)
			or (cur_due == new_due and cur_pri == new_pri and cur_seq < new_seq)
		)

		# If cur is NOT before entry, we insert here
		if not cur_before:
			break

		insert_index += 1

	message_queue.insert(insert_index, entry)


func _delay_for_priority(priority: int) -> int:
	# same spirit as your old director
	if priority <= 0:
		return 0
	return randi_range(2, 4)


# -------------------------
# Tick -> Deliver
# -------------------------
func _on_clock_tick(current_minutes: int) -> void:
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

	# node-level gating: if unmet, postpone 1 tick (so it can unlock later)
	if not _requirements_met(node.get("requires", [])):
		queue_entry["due_at"] = current_minutes + 1
		_insert_sorted_by_due(queue_entry)
		return

	# Emit NPC message to the UI/app system
	npc_message_created.emit(
		str(node.get("sender", thread_id)),
		str(node.get("text", "")),
		node.get("annex", {}),
		GameData.Sender.NPC,
		GameData.hours_minutes
	)

	# If there are choices: present them and STOP branch progression until an answer is chosen.
	var choices: Array = node.get("choices", [])
	if not choices.is_empty():
		_present_choices(
			thread_id,
			branch_name,
			node_index,
			int(queue_entry.get("priority", 0)),
			node,
			choices
		)
		return

	# Otherwise continue to next node in this branch
	var next_index := node_index + 1
	if next_index < branch_nodes.size():
		var next_priority := int(node.get("priority", queue_entry.get("priority", 0)))
		_enqueue_queue_entry({
			"thread_id": thread_id,
			"branch": branch_name,
			"index": next_index,
			"priority": next_priority
		}, _delay_for_priority(next_priority))


func _present_choices(
	thread_id: String,
	origin_branch: String,
	origin_index: int,
	priority: int,
	node: Dictionary,
	choices: Array
) -> void:
	var npc_name := str(node.get("sender", thread_id))

	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue

		var answer_id := _new_answer_id()
		answer_state_by_id[answer_id] = {
			"thread_id": thread_id,
			"choice": choice,
			"origin": {"branch": origin_branch, "index": origin_index},
			"priority": priority,
		}

		var player_text := str(choice.get("player_text", ""))
		var title := str(choice.get("title", player_text))
		var rep_points := int(choice.get("reputation_points", 0))

		# The answers bar treats "time" as due-time unless negative.
		# We want it available immediately, so use current minute.
		request_answer_option.emit(
			npc_name,
			player_text,
			title,
			rep_points,
			GameData.hours_minutes,
			answer_id
		)


func _new_answer_id() -> int:
	next_answer_id += 1
	return next_answer_id


# -------------------------
# Answer chosen
# -------------------------
func _on_message_answered(answer_id: int) -> void:
	if not answer_state_by_id.has(answer_id):
		return

	var state: Dictionary = answer_state_by_id[answer_id]
	answer_state_by_id.erase(answer_id)

	var thread_id := str(state.get("thread_id", ""))
	var choice: Dictionary = state.get("choice", {})
	var origin: Dictionary = state.get("origin", {})
	var priority := int(state.get("priority", 0))

	_apply_choice_effects(choice)

	# Preferred path: npc_reply -> goto_branch after delay
	if choice.has("npc_reply"):
		var reply: Dictionary = choice.get("npc_reply", {})
		var delay_ticks := int(reply.get("delay_ticks", 0))

		if reply.has("goto_branch"):
			_enqueue_branch_start(thread_id, str(reply["goto_branch"]), priority, delay_ticks)
			return

	# Fallback behavior:
	# If no npc_reply was defined, continue the current branch after the choice node.
	var thread: Dictionary = threads_by_id.get(thread_id, {})
	var branches: Dictionary = thread.get("branches", {})
	var origin_branch := str(origin.get("branch", ""))
	var origin_nodes: Array = branches.get(origin_branch, [])
	var next_index := int(origin.get("index", 0)) + 1

	if next_index >= 0 and next_index < origin_nodes.size():
		_enqueue_queue_entry({
			"thread_id": thread_id,
			"branch": origin_branch,
			"index": next_index,
			"priority": priority
		}, 0)


func _apply_choice_effects(choice: Dictionary) -> void:
	# Keep this intentionally minimal for now.
	# Your JSON currently contains effects like {"installer": 1}, {"task_type": 1}, etc.
	# Those ints can be unreliable unless you standardize them.
	var rep_points := int(choice.get("reputation_points", 0))
	if rep_points != 0:
		GameData.data["reputation_points"] = int(GameData.data.get("reputation_points", 0)) + rep_points


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
	# Map your JSON flags -> current GameData truth.
	# (Uses downloaded_apps, which is what your store installation updates.)
	var app_map := {
		"settings": GameData.App.SETTINGS,
		"browser": GameData.App.BROWSER,
		"mail": GameData.App.EMAIL,
		"store": GameData.App.STORE,
		"fake_store": GameData.App.FAKESTORE,
	}

	if flag in app_map:
		return GameData.downloaded_apps.has(app_map[flag])

	# optional fallback: GameData.data booleans if you ever use them
	var key := "has_%s" % flag
	if typeof(GameData.data) == TYPE_DICTIONARY and GameData.data.has(key):
		return bool(GameData.data[key])

	return false

func _on_browser_request_news() -> void:
	var day_news := _load_news_data()
	if typeof(day_news) != TYPE_DICTIONARY:
		day_news = {}
	news_ready.emit(day_news)

# get the news of the current day
func _load_news_data() -> Dictionary:
	var current_day = _get_current_day()
	print(current_day)
	var file = FileAccess.open(news_dir_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	var day_key = "day_%d" % current_day
	return data[day_key]

#get the current day
func _get_current_day():
	var file = FileAccess.open("res://data/save.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	var current_day = data["current_day"]
	return current_day

