extends Node2D

signal news_ready(day_news_data: Dictionary)
signal update_news

## Lanes of the story queue. Whenever no chat is in progress the main characters (the bosses of
## the company) go first, then the random employees asking the intern for help, by message or email
enum Lane { MAIN, RANDOM }

#region CHILDREN NODES REFERENCES
@export var messages_director: Node
@export var emails_director: Node
@export var browser_director: Node
@export var bank_director: Node
@export var randomness_director: Node
@export var events_director: Node
@export var introduction_director: Node

@export var ui: Control
@export var event_handler: Node2D
@export var messages_dir_path: String = "res://data/messages"
@export var news_dir_path: String = "res://data/news.json"
@export var emails_dir_path: String = "res://data/emails"
@export var reviews_dir_path: String = "res://data/browser/reviewed_companies.json"
@export var shops_items_dir_path: String = "res://data/browser/shops_items.json"
@export var pix_codes_dir_path: String = "res://data/bank/pix_codes_data.json"
@export var ticket_codes_dir_path: String = "res://data/bank/ticket_codes_data.json"
## Holds one day_<n>/{tasks,scams} folder per day with random events
@export var random_dir_path: String = "res://data/random"
@export var events_dir_path: String = "res://data/events/events.json"
@export var rules_dir_path: String = "res://data/rules/rules.json"
@export var introduction_dir_path: String = "res://data/introduction"
#endregion CHILDREN NODES REFERENCES

## Game minutes a chat in progress keeps holding the others while it waits for the player (an
## answer, an email to be read) with nothing else queued. 0 holds them for as long as it takes
@export var lock_timeout_minutes: int = 60

#region QUEUE STATE
# One queue per lane for all apps that deliver story content over time
# {"channel":String, "owner":String, "lane":Lane, "continues":bool, "due_at":int, "seq":int,
#  "requires":Array, "payload":Dictionary}
var main_queue: Array[Dictionary] = []
var random_queue: Array[Dictionary] = []
var story_enqueue_seq: int = 0

# Maps channel name to director node
var channel_director_by_name: Dictionary = {}
#endregion QUEUE STATE

#region LOCK STATE
## Chat in progress ("messages:<conversation_id>" or "emails:<thread_id>"), empty when none.
## Until it ends only its own next messages are delivered, every other chat waits
var active_owner: String = ""
## Event of the random task in progress, which holds the others until it is done
var active_event_id: String = ""
## Whether the chat in progress said everything and only its event is left to be done
var active_chat_done: bool = false
## Last minute the chat in progress was delivered or got its next message queued
var lock_last_activity: int = 0
## Lane each chat was last delivered in, so its next messages stay in it
var lane_by_owner: Dictionary = {}
#endregion LOCK STATE

#region INITIALIZATION
## Creates channel_director_by_name and connects to their schedule_entry_requested signals.
func _ready() -> void:
	channel_director_by_name = {
		"messages": messages_director,
		"emails": emails_director,
	}

	messages_director.schedule_entry_requested.connect(_on_messages_schedule_entry_requested)
	emails_director.schedule_entry_requested.connect(_on_emails_schedule_entry_requested)
	# Random messages and emails share the random lane, one in progress holds the other
	randomness_director.schedule_message.connect(_on_random_message_requested)
	randomness_director.schedule_email.connect(_on_random_email_requested)

	messages_director.conversation_finished.connect(_on_conversation_finished)
	emails_director.thread_finished.connect(_on_thread_finished)
	events_director.scam_blocked.connect(_on_scam_blocked)

	reload_and_setup_today()
#endregion INITIALIZATION

#region SETUP FLOW
## Reloads all JSON data and sets up today's story entries.
func reload_and_setup_today() -> void:
	# Clear existing queue
	_clear_story_queue()

	# Load JSON roots from data directories
	var message_roots := _load_json_roots_from_all_directories(messages_dir_path)
	
	var email_roots := _load_json_roots_from_directory(emails_dir_path)
	var random_day_dir_path := random_dir_path.path_join("day_%d" % GameData.current_day)
	var tasks_roots := _load_json_roots_from_directory(random_day_dir_path.path_join("tasks"))
	var scams_roots := _load_json_roots_from_directory(random_day_dir_path.path_join("scams"))
	var introduction_roots := _load_json_roots_from_directory(introduction_dir_path)

	# Load JSON file from file path
	var reviews_array := _read_json_array(reviews_dir_path)
	var shops_dictionary = _read_json_root(shops_items_dir_path)
	var pix_dictionary = _read_json_root(pix_codes_dir_path)
	var tickets_dictionary = _read_json_root(ticket_codes_dir_path)
	var events_dictionary = _read_json_root(events_dir_path)
	var rules_array := _read_json_array(rules_dir_path)

	# StoryDirector provides data, directors interpret and request schedules upward
	messages_director.setup_from_json_roots(message_roots)
	emails_director.setup_from_json_roots(email_roots)
	browser_director.reviews_director.setup_from_json_array(reviews_array)
	browser_director.shops_director.setup_from_json_file(shops_dictionary)
	bank_director.setup_from_json_file(pix_dictionary, tickets_dictionary)
	var task_roots: Array = _drop_missing_random_events(tasks_roots)
	randomness_director.setup_from_json_roots(
		task_roots,
		_drop_missing_random_events(scams_roots),
		events_dictionary,
		rules_array
	)
	_publish_trusted_senders(task_roots[0], events_dictionary)
	events_director.setup_from_json_file(events_dictionary, rules_array)
	introduction_director.setup_from_json_roots(introduction_roots)

	#Update Browser News
	_on_update_news()

## Tells the Notes who sends the random tasks of today: anyone else asking for something is a scam
##
## task_events: The random tasks of today, as data/random/day_<n>/tasks lists them
## events: Every event of data/events/events.json
func _publish_trusted_senders(task_events: Array, events: Dictionary) -> void:
	var senders: Array[Dictionary] = []
	for event in task_events:
		var sender: Dictionary
		if event.has("email_id"):
			sender = {
				"email": emails_director.get_sender(str(event["thread_id"]), str(event["email_id"]))
			}
		else:
			var contact: Dictionary = messages_director._get_contact(str(event["conversation_id"]))
			sender = {
				"name": contact["name"],
				"account": contact["account"],
				"verified": contact["verified"],
			}
		# A sender with many tasks in the pool is listed once
		if not senders.has(sender):
			senders.append(sender)

	# Neither are the emails the story sends today that are not scams (an invoice, a recovery code)
	for email in emails_director.get_emails_of_day(GameData.current_day):
		var event: Dictionary = events.get(str(email.get("event_id", "")), {})
		if event.get("type", "") == "scam":
			continue
		var sender := {"email": str(email.get("sender", "")).strip_edges()}
		if not senders.has(sender):
			senders.append(sender)
	GameData.trusted_senders_today = senders

## Leaves out the random events naming a conversation branch or an email that does not exist,
## they could never be done and would hold the random lane until the timeout
func _drop_missing_random_events(roots: Array) -> Array:
	var existing_events: Array = []
	for root in roots:
		for event in root:
			var exists: bool
			if event.has("email_id"):
				exists = emails_director.has_email(
					str(event.get("thread_id")), str(event.get("email_id"))
				)
			else:
				exists = messages_director.has_branch(
					str(event.get("conversation_id")), str(event.get("branch"))
				)
			if exists:
				existing_events.append(event)
			else:
				push_error("Random event of day %d not found in the data: %s" % [
					GameData.current_day, event
				])
	return [existing_events]
#endregion SETUP FLOW

#region SIGNAL HANDLERS
## Handles schedule_entry_requested from messages director
func _on_messages_schedule_entry_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("messages", schedule_entry)

## Handles schedule_entry_requested from email director
func _on_emails_schedule_entry_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("emails", schedule_entry)

## Handles schedule_message from randomness director
func _on_random_message_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("messages", schedule_entry, Lane.RANDOM)

## Handles schedule_email from randomness director
func _on_random_email_requested(schedule_entry: Dictionary) -> void:
	_enqueue_story_entry("emails", schedule_entry, Lane.RANDOM)

## Handles conversation_finished from messages director: the NPC has nothing left to say
func _on_conversation_finished(conversation_id: String) -> void:
	_on_chat_done(_get_owner("messages", conversation_id))

## Handles thread_finished from email director: the player read the email
func _on_thread_finished(thread_id: String) -> void:
	_on_chat_done(_get_owner("emails", thread_id))

## The chat said everything: it stops holding the others, unless it is a random task still to be
## done (a purchase, a payment...), see _should_release_lock()
func _on_chat_done(owner: String) -> void:
	if active_owner != owner:
		return
	active_chat_done = true
	if not events_director.is_event_pending(active_event_id):
		_release_lock()

## Handles scam_blocked from events director: a blocked conversation goes no further, so its
## queued messages are dropped and it stops holding the other chats
func _on_scam_blocked(conversation_ids: Array) -> void:
	for conversation_id in conversation_ids:
		var owner := _get_owner("messages", str(conversation_id))
		if active_owner == owner:
			_release_lock()
		for queue in [main_queue, random_queue]:
			for entry_index in range(queue.size() - 1, -1, -1):
				if queue[entry_index]["owner"] == owner:
					queue.remove_at(entry_index)

## Enqueues a story entry into the queue of its lane
##
## lane: Lane.RANDOM for random events. Left out, the entry goes in the lane its chat was last
## delivered in, the main one for a chat not delivered yet
func _enqueue_story_entry(channel_name: String, schedule_entry: Dictionary, lane: int = -1) -> void:
	var due_at := int(schedule_entry["due_at"])
	var requires: Array = schedule_entry.get("requires", [])
	var chat_id_key := "conversation_id" if channel_name == "messages" else "thread_id"
	var owner := _get_owner(channel_name, str(schedule_entry.get(chat_id_key, "")))
	if lane == -1:
		lane = lane_by_owner.get(owner, Lane.MAIN)

	var story_entry: Dictionary = {
		"channel": channel_name,
		"owner": owner,
		"lane": lane,
		# Next message of a chat already delivered, rather than a new chat (or branch) to start
		"continues": bool(schedule_entry.get("continues", false)),
		"due_at": due_at,
		"seq": story_enqueue_seq,
		"requires": requires,
		"payload": schedule_entry,
	}

	story_enqueue_seq += 1
	_insert_story_entry_sorted(_get_queue(lane), story_entry)

	# The NPC replying keeps its chat in progress
	if owner == active_owner:
		lock_last_activity = int(GameData.hours_minutes)
#endregion SIGNAL HANDLERS

#region CLOCK
## Called by Clock every tick to process due story entries
##
## Delivers at most one entry per tick. While a chat is in progress only its own next messages
## are delivered and every other chat, messages or emails, waits for it to end. With no chat in
## progress the main lane goes first and the random lane after it, which gets its next random
## event right then, so they come one after another.
func on_clock_tick(current_minutes: int) -> void:
	events_director._on_clock_tick()
	emails_director._on_clock_tick()

	if active_owner != "" and not _should_release_lock(current_minutes):
		for queue in [main_queue, random_queue]:
			if _deliver_first_ready(queue, current_minutes, active_owner):
				return
		return

	_release_lock()
	if _deliver_first_ready(main_queue, current_minutes):
		return

	# The next random event is picked only once the last one picked was delivered
	var has_random_to_start := random_queue.any(
		func(story_entry: Dictionary) -> bool: return not story_entry["continues"]
	)
	if not has_random_to_start:
		randomness_director.schedule_next_event(current_minutes)
	_deliver_first_ready(random_queue, current_minutes)

## Whether the chat in progress gives its turn away
##
## A main chat gives it away once its next message waits on something done outside the chat (a
## purchase, a payment...). A random task holds it until done: its waiting message comes, or its
## event is completed or blocked. Waiting on the player (an answer, an email to be read, a task)
## holds it for lock_timeout_minutes at most, so a scam the player refuses does not hold forever.
func _should_release_lock(current_minutes: int) -> bool:
	var is_timed_out := lock_timeout_minutes > 0 \
		and current_minutes - lock_last_activity >= lock_timeout_minutes

	# A random task that said everything, waiting for the player to do it
	if active_chat_done:
		return is_timed_out or not events_director.is_event_pending(active_event_id)

	for queue in [main_queue, random_queue]:
		for story_entry in queue:
			if story_entry["owner"] != active_owner or not story_entry["continues"]:
				continue
			var is_due := _is_due(story_entry, current_minutes)
			if not is_due or _requirements_met(story_entry["requires"]):
				return false
			# Its next message waits on something done outside the chat
			return story_entry["lane"] == Lane.MAIN or is_timed_out

	# Nothing queued: the NPC is typing, or it waits for an answer or for the email to be read
	return is_timed_out

## Delivers the first due entry of the queue whose requirements are met, returning whether it did
##
## owner: When given, only the next messages of that chat are delivered
func _deliver_first_ready(
	queue: Array[Dictionary], current_minutes: int, owner: String = ""
) -> bool:
	for entry_index in range(queue.size()):
		var story_entry := queue[entry_index]

		# Ordered by due_at, so no entry after this one is due either
		if not _is_due(story_entry, current_minutes):
			return false

		if owner != "" and (story_entry["owner"] != owner or not story_entry["continues"]):
			continue

		# Entries blocked by unmet requirements are skipped for now, checking only the head would
		# cause a head-of-line blocking
		if not _requirements_met(story_entry["requires"]):
			continue

		queue.remove_at(entry_index)
		_deliver(story_entry, current_minutes)
		return true

	return false

## Whether an entry is due. The tutorial (day 0) has no time passing, so its entries come one
## after another, in the order of their due times, as each chat in progress ends
func _is_due(story_entry: Dictionary, current_minutes: int) -> bool:
	return GameData.current_day == 0 or current_minutes >= int(story_entry["due_at"])

## Puts the chat of the entry in progress and calls down into the right controller
func _deliver(story_entry: Dictionary, current_minutes: int) -> void:
	var payload: Dictionary = story_entry["payload"]
	var event_id := str(payload.get("event_id", ""))

	# Set before delivering, as a delivery may end its chat right away
	var is_same_chat: bool = story_entry["owner"] == active_owner and story_entry["continues"]
	active_owner = story_entry["owner"]
	active_chat_done = false
	lock_last_activity = current_minutes
	lane_by_owner[active_owner] = story_entry["lane"]
	# The event a random task waits on comes with its first message
	if not is_same_chat:
		active_event_id = event_id if story_entry["lane"] == Lane.RANDOM else ""

	var controller: Node = channel_director_by_name[story_entry["channel"]]
	events_director._on_event_initiated(event_id)
	controller.deliver_scheduled_entry(payload, current_minutes)

## Lets every other chat go on
func _release_lock() -> void:
	active_owner = ""
	active_event_id = ""
	active_chat_done = false
#endregion CLOCK

#region QUEUE OPS
## Clears the story queues, the chat in progress and resets sequence counter
func _clear_story_queue() -> void:
	main_queue.clear()
	random_queue.clear()
	story_enqueue_seq = 0
	_release_lock()
	lane_by_owner.clear()

## Inserts a story entry into a story queue maintaining order by due_at and seq
## This allows FIFO ordering for entries with the same due_at
func _insert_story_entry_sorted(queue: Array[Dictionary], story_entry: Dictionary) -> void:
	var due_at := int(story_entry["due_at"])
	var seq := int(story_entry["seq"])

	for index in range(queue.size()):
		var existing := queue[index]
		var existing_due := int(existing["due_at"])

		if existing_due > due_at:
			queue.insert(index, story_entry)
			return

		if existing_due == due_at and int(existing["seq"]) > seq:
			queue.insert(index, story_entry)
			return

	queue.append(story_entry)

func _get_queue(lane: int) -> Array[Dictionary]:
	return random_queue if lane == Lane.RANDOM else main_queue

## Key of the chat (a conversation or an email thread) a story entry belongs to
func _get_owner(channel_name: String, chat_id: String) -> String:
	return "%s:%s" % [channel_name, chat_id]
#endregion QUEUE OPS

#region JSON LOADING
## Loads all JSON roots of all directories inside a given directory path
func _load_json_roots_from_all_directories(directory_path: String) -> Array:
	var subdirectory_paths := _list_subdirectory_paths(directory_path)
	subdirectory_paths.sort()

	var roots: Array = []
	for subdirectory_path in subdirectory_paths:
		roots.append_array(_load_json_roots_from_directory(subdirectory_path))
	return roots

## Lists all subdirectory paths in a given directory
func _list_subdirectory_paths(directory_path: String) -> Array[String]:
	var directory := DirAccess.open(directory_path)
	var subdirectory_paths: Array[String] = []
	if directory == null:
		return subdirectory_paths

	directory.list_dir_begin()
	while true:
		var directory_name := directory.get_next()
		if directory_name == "":
			break
		if not directory.current_is_dir():
			continue
		if directory_name.begins_with("."):
			continue
		subdirectory_paths.append(directory_path.path_join(directory_name))
	directory.list_dir_end()

	return subdirectory_paths
	
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
	if directory == null:
		return file_paths

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
			var store = GameData.shop_string_to_enum.get(store_id, null)

			if store == null:
				return false
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
	# Read without being consumed, unlike events_director, so a story beat can wait for it
	if flag == "option":
		return GameData.options_chose.get(requirement.get("choice", ""), false)
	if flag == "email_read":
		return GameData.read_emails.has(requirement.get("email_id", ""))

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

func _on_update_news() -> void:
	update_news.emit()

#endregion REQUIREMENTS
