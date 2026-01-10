extends Node2D

#region CHILDREN NODES REFERENCES
@export var messages_director: Node
@export var emails_director: Node

@export var messages_dir_path: String = "res://data/messages"
@export var emails_dir_path: String = "res://data/emails"
#endregion CHILDREN NODES REFERENCES

#region QUEUE STATE
# Unified queue entries:
# {"channel":String, "due_at":int, "seq":int, "requires":Array, "payload":Dictionary}
var story_queue: Array[Dictionary] = []
var story_enqueue_seq: int = 0

# channel -> controller node
var channel_controller_by_name: Dictionary = {}
#endregion QUEUE STATE

#region INITIALIZATION
func _ready() -> void:
	channel_controller_by_name = {
		"messages": messages_director,
		"emails": emails_director,
	}

	messages_director.schedule_entry_requested.connect(_on_messages_schedule_entry_requested)
	emails_director.schedule_entry_requested.connect(_on_emails_schedule_entry_requested)

	reload_and_setup_today()
#endregion INITIALIZATION

#region SETUP FLOW
func reload_and_setup_today() -> void:
	_clear_story_queue()

	var message_roots := _load_json_roots_from_directory(messages_dir_path)
	var email_roots := _load_json_roots_from_directory(emails_dir_path)

	# Call down: StoryDirector provides data; controllers interpret and request schedules upward
	messages_director.setup_from_json_roots(message_roots)
	emails_director.setup_from_json_roots(email_roots)
#endregion SETUP FLOW

#region SIGNAL HANDLERS
func _on_messages_schedule_entry_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("messages", schedule_entry)

func _on_emails_schedule_entry_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("emails", schedule_entry)

func _enqueue_story_entry(channel_name: String, schedule_entry: Dictionary) -> void:
	var due_at := int(schedule_entry["due_at"])
	var requires: Array = schedule_entry.get("requires", [])

	var story_entry: Dictionary = {
		"channel": channel_name,
		"due_at": due_at,
		"seq": story_enqueue_seq,
		"requires": requires,
		"payload": schedule_entry,
	}

	story_enqueue_seq += 1
	_insert_story_entry_sorted(story_entry)
#endregion SIGNAL HANDLERS

#region CLOCK
func on_clock_tick(current_minutes: int) -> void:
	if story_queue.is_empty():
		return

	var head := story_queue[0]
	if current_minutes < int(head["due_at"]):
		return

	# Deliver at most one per tick
	var entry_index := 0
	while entry_index < story_queue.size():
		var story_entry := story_queue[entry_index]

		if current_minutes < int(story_entry["due_at"]):
			return

		if not _requirements_met(story_entry.get("requires", [])):
			# Requeue blocked entry
			story_entry["due_at"] = current_minutes + 1
			story_queue.remove_at(entry_index)
			_insert_story_entry_sorted(story_entry)
			return

		# Ready: remove + call down into the right controller
		story_queue.remove_at(entry_index)

		var channel_name := str(story_entry["channel"])
		var controller: Node = channel_controller_by_name[channel_name]
		controller.deliver_scheduled_entry(story_entry["payload"], current_minutes)
		return
#endregion CLOCK

#region QUEUE OPS
func _clear_story_queue() -> void:
	story_queue.clear()
	story_enqueue_seq = 0

func _insert_story_entry_sorted(story_entry: Dictionary) -> void:
	var due_at := int(story_entry["due_at"])
	var seq := int(story_entry["seq"])

	for i in range(story_queue.size()):
		var existing := story_queue[i]
		var existing_due := int(existing["due_at"])

		if existing_due > due_at:
			story_queue.insert(i, story_entry)
			return

		if existing_due == due_at and int(existing["seq"]) > seq:
			story_queue.insert(i, story_entry)
			return

	story_queue.append(story_entry)
#endregion QUEUE OPS

#region JSON LOADING
func _load_json_roots_from_directory(directory_path: String) -> Array:
	var file_paths := _list_json_file_paths(directory_path)
	file_paths.sort()

	var roots: Array = []
	for file_path in file_paths:
		roots.append(_read_json_root(file_path))
	return roots

func _list_json_file_paths(directory_path: String) -> Array[String]:
	var directory := DirAccess.open(directory_path)
	var file_paths: Array[String] = []

	directory.list_dir_begin()
	while true:
		var file_name := directory.get_next()
		if file_name == "":
			break
		if directory.current_is_dir():
			continue
		if file_name.begins_with("."):
			continue
		if file_name.get_extension().to_lower() != "json":
			continue
		file_paths.append(directory_path.path_join(file_name))
	directory.list_dir_end()

	return file_paths

func _read_json_root(file_path: String) -> Variant:
	var file := FileAccess.open(file_path, FileAccess.READ)
	var parser := JSON.new()
	var result := parser.parse(file.get_as_text())
	assert(result == OK)
	return parser.data
#endregion JSON LOADING

#region REQUIREMENTS
func _requirements_met(requirements: Array) -> bool:
	if requirements.is_empty():
		return true

	for requirement in requirements:
		var flag := str(requirement.get("flag", ""))
		var expected := bool(requirement.get("is", true))
		if _evaluate_flag(flag) != expected:
			return false

	return true

func _evaluate_flag(flag: String) -> bool:
	if flag in GameData.apps_name.keys():
		return GameData.downloaded_apps.has(GameData.apps_name[flag])
	return false
#endregion REQUIREMENTS
