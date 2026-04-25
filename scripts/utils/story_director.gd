extends Node2D

signal request_answer_option(
	npc_name: String,
	message: String,
	title: String,
	reputation_points: int,
	time: int,
	answer_id: int
)

signal news_ready(day_news_data: Dictionary)

#region CHILDREN NODES REFERENCES
@export var messages_director: Node
@export var emails_director: Node
@export var browser_director: Node
@export var bank_director: Node
@export var randomness_director: Node

@export var ui: Control
@export var event_handler: Node2D
@export var messages_dir_path: String = "res://data/messages"
@export var news_dir_path: String = "res://data/news.json"
@export var emails_dir_path: String = "res://data/emails"
@export var reviews_dir_path: String = "res://data/browser/reviewed_companies.json"
@export var shops_items_dir_path: String = "res://data/browser/shops_items.json"
@export var pix_codes_dir_path: String = "res://data/bank/pix_codes_data.json"
@export var ticket_codes_dir_path: String = "res://data/bank/ticket_codes_data.json"
@export var tasks_dir_path: String = "res://data/random/tasks"
@export var scams_dir_path: String = "res://data/random/scams"
#endregion CHILDREN NODES REFERENCES

#region QUEUE STATE
# Unified queue for all apps that deliver story content over time
# {"channel":String, "due_at":int, "seq":int, "requires":Array, "payload":Dictionary}
var story_queue: Array[Dictionary] = []
var story_enqueue_seq: int = 0

# Maps channel name to director node
var channel_director_by_name: Dictionary = {}
#endregion QUEUE STATE

#region INITIALIZATION
## Creates channel_director_by_name and connects to their schedule_entry_requested signals.
func _ready() -> void:
	channel_director_by_name = {
		"messages": messages_director,
		"emails": emails_director,
	}

	messages_director.schedule_entry_requested.connect(_on_messages_schedule_entry_requested)
	emails_director.schedule_entry_requested.connect(_on_emails_schedule_entry_requested)
	randomness_director.schedule_message.connect(_on_messages_schedule_entry_requested)
	randomness_director.schedule_email.connect(_on_emails_schedule_entry_requested)

	reload_and_setup_today()
#endregion INITIALIZATION

#region SETUP FLOW
## Reloads all JSON data and sets up today's story entries.
func reload_and_setup_today() -> void:
	# Clear existing queue
	_clear_story_queue()

	# Load JSON roots from data directories
	var message_roots := _load_json_roots_from_directory(messages_dir_path)
	var email_roots := _load_json_roots_from_directory(emails_dir_path)
	var tasks_roots := _load_json_roots_from_directory(tasks_dir_path)
	var scams_roots := _load_json_roots_from_directory(scams_dir_path)

	# Load JSON file from file path
	var reviews_array := _read_json_array(reviews_dir_path)
	var shops_dictionary = _read_json_root(shops_items_dir_path)
	var pix_dictionary = _read_json_root(pix_codes_dir_path)
	var tickets_dictionary = _read_json_root(ticket_codes_dir_path)

	# StoryDirector provides data, directors interpret and request schedules upward
	messages_director.setup_from_json_roots(message_roots)
	emails_director.setup_from_json_roots(email_roots)
	browser_director.reviews_director.setup_from_json_array(reviews_array)
	browser_director.shops_director.setup_from_json_file(shops_dictionary)
	bank_director.setup_from_json_file(pix_dictionary, tickets_dictionary)
	randomness_director.setup_from_json_roots(tasks_roots, scams_roots)
#endregion SETUP FLOW

#region SIGNAL HANDLERS
## Handles schedule_entry_requested from messages director
func _on_messages_schedule_entry_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("messages", schedule_entry)

## Handles schedule_entry_requested from email director
func _on_emails_schedule_entry_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("emails", schedule_entry)

## Enqueues a story entry into the unified story queue
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
## Called by Clock every tick to process due story entries
func on_clock_tick(current_minutes: int) -> void:
	randomness_director._on_clock_tick()

	# If no entries, nothing to do
	if story_queue.is_empty():
		return

	# Check the head of the queue (ordered, so earliest due_at first)
	var head := story_queue[0]
	if current_minutes < int(head["due_at"]):
		return # If the head is not due, nothing to do

	# If due, check all entries in order until we find one that can be delivered
	# or we run out of due entries.
	# The reason to do this is that some entries may be blocked by unmet requirements
	# and we want to skip them for now, checking only the head would cause a head-of-line blocking.

	# Deliver at most one per tick
	var entry_index := 0
	while entry_index < story_queue.size():
		var story_entry := story_queue[entry_index]

		# If we reached an entry not yet due, stop checking
		if current_minutes < int(story_entry["due_at"]):
			return

		# If due, check requirements
		if not _requirements_met(story_entry.get("requires", [])):
			# Requeue blocked entry for next tick
			story_entry["due_at"] = current_minutes + 1
			story_queue.remove_at(entry_index)
			_insert_story_entry_sorted(story_entry)
			return

		# If ready remove from queue + call down into the right controller
		story_queue.remove_at(entry_index)
		var channel_name := str(story_entry["channel"])
		var controller: Node = channel_director_by_name[channel_name]
		controller.deliver_scheduled_entry(story_entry["payload"], current_minutes)
		return # Only one delivery per tick
#endregion CLOCK

#region QUEUE OPS
## Clears the story queue and resets sequence counter
func _clear_story_queue() -> void:
	story_queue.clear()
	story_enqueue_seq = 0

## Inserts a story entry into the story queue maintaining order by due_at and seq
## This allows FIFO ordering for entries with the same due_at
func _insert_story_entry_sorted(story_entry: Dictionary) -> void:
	var due_at := int(story_entry["due_at"])
	var seq := int(story_entry["seq"])

	for index in range(story_queue.size()):
		var existing := story_queue[index]
		var existing_due := int(existing["due_at"])

		if existing_due > due_at:
			story_queue.insert(index, story_entry)
			return

		if existing_due == due_at and int(existing["seq"]) > seq:
			story_queue.insert(index, story_entry)
			return

	story_queue.append(story_entry)
#endregion QUEUE OPS

#region JSON LOADING
## Loads all JSON roots from a given directory path
func _load_json_roots_from_directory(directory_path: String) -> Array:
	var file_paths := _list_json_file_paths(directory_path)
	file_paths.sort()

	var roots: Array = []
	for file_path in file_paths:
		roots.append(_read_json_root(file_path))
	return roots

## Lists all JSON file paths in a given directory
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

## Reads and parses a JSON file, returning the root Variant
func _read_json_root(file_path: String) -> Variant:
	var file := FileAccess.open(file_path, FileAccess.READ)
	var parser := JSON.new()
	var result := parser.parse(file.get_as_text())
	assert(result == OK)
	return parser.data

func _read_json_array(file_path: String) -> Array:
	var json_data = _read_json_root(file_path)
	assert(typeof(json_data) == TYPE_ARRAY)
	return json_data


#endregion JSON LOADING

#region REQUIREMENTS
## Evaluates if all requirements in the given array are met
func _requirements_met(requirements: Array) -> bool:
	if requirements.is_empty():
		return true

	for requirement in requirements:
		var expected = bool(requirement.get("is", true))
		if _evaluate_requirement(requirement) != expected:
			return false

	return true

## Evaluates a single requirement flag
func _evaluate_requirement(requirement: Dictionary) -> bool:
	var flag = requirement.get("flag", "")
	if flag == "app_installed":
		var app_id = requirement.get("app_id", "")
		var app = GameData.apps_name.get(app_id, null)
		return GameData.downloaded_apps.has(app)
	if flag == "purchase":
		var items = requirement.get("items", [])
		for item in items:
			var item_id = item.get("item_id", "")
			var quantity = int(item.get("quantity", 0))
			var store_id = item.get("store", "")
			var store = GameData.apps_name.get(store_id, null)

			if not GameData.purchased_items.has(store):
				return false
			var store_purchases = GameData.purchased_items[store]
			if not store_purchases.has(item_id):
				return false
			if store_purchases[item_id] < quantity:
				return false

			return true
	if flag == "payment":
		var payment_id = requirement.get("payment_id", "")
		return GameData.completed_payments.has(payment_id)

	return false

func _on_browser_request_news() -> void:
	var day_news := _load_news_data()
	if typeof(day_news) != TYPE_DICTIONARY:
		day_news = {}
	news_ready.emit(day_news)

# get the news of the current day
func _load_news_data() -> Dictionary:
	var current_day = GameData.current_day
	var file = FileAccess.open(news_dir_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	var day_key = "day_%d" % current_day
	return data[day_key] if data.has(day_key) else {}

#endregion REQUIREMENTS
