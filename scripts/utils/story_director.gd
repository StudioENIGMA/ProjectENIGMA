extends Node2D

signal news_ready(day_news_data: Dictionary)
signal update_news
## Emitted when a random task or scam is lost, its contact gone offline before it was done:
## channel_name "messages" or "emails", chat_id its conversation or thread
signal chat_lost(channel_name: String, chat_id: String)
## Emitted when the contacts online change, with the owners online now ("messages:<id>")
signal online_chats_changed(owners: Array)

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
@export var boletos_director: Node

@export var ui: Control
@export var event_handler: Node2D
@export var messages_dir_path: String = "res://data/messages"
@export var news_dir_path: String = "res://data/news.json"
@export var emails_dir_path: String = "res://data/emails"
@export var reviews_dir_path: String = "res://data/browser/reviewed_companies.json"
@export var shops_items_dir_path: String = "res://data/browser/shops_items.json"
@export var pix_codes_dir_path: String = "res://data/bank/pix_codes_data.json"
@export var ticket_codes_dir_path: String = "res://data/bank/ticket_codes_data.json"
@export var boletos_dir_path: String = "res://data/bank/boletos.json"
## Holds the banks accepted on each day, which a forged boleto stays out of
@export var board_dir_path: String = "res://data/notes/board.json"
## Holds one day_<n>/{tasks,scams} folder per day with random events
@export var random_dir_path: String = "res://data/random"
@export var events_dir_path: String = "res://data/events/events.json"
@export var rules_dir_path: String = "res://data/rules/rules.json"
@export var introduction_dir_path: String = "res://data/introduction"
#endregion CHILDREN NODES REFERENCES

## Game minutes a chat in progress keeps holding the others while it waits for the player (an
## answer, an email to be read) with nothing else queued. 0 holds them for as long as it takes
@export var lock_timeout_minutes: int = 60
## Game minutes before its timeout a random task or scam warns that it is about to be lost, see
## _warn_before_losing()
@export var lock_warning_minutes: int = 20

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
## Whether the chat in progress is an email scam the player blocked, holding the others until the
## player deletes it
var active_awaiting_delete: bool = false
## Last minute the chat in progress was delivered or got its next message queued
var lock_last_activity: int = 0
## Lane each chat was last delivered in, so its next messages stay in it
var lane_by_owner: Dictionary = {}
## owner -> event its chat brought today, which keeps its contact online until done or lost
var event_by_owner: Dictionary = {}
## owner -> the last activity its contact was warned at, so it warns once per wait
var _warned_owners: Dictionary = {}
## Owners online at the last tick, see _publish_online_chats()
var _online_owners: Array = []
## DEBUG: no chat starts by itself, only the ones fired from the debug task launcher go on
var debug_isolated: bool = false
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
	emails_director.delete_offered.connect(_on_delete_offered)
	emails_director.thread_closed.connect(_on_thread_closed)
	events_director.scam_blocked.connect(_on_scam_blocked)

	reload_and_setup_today()

	## ======================================================
	##                     DEBUG CODE
	## ======================================================
	## F9 lists every event to fire one on demand, see debug_task_launcher.gd. The story runs as
	## in the exported game: one random event per sender a day
	if OS.is_debug_build():
		add_child(load("res://scripts/utils/debug_task_launcher.gd").new())
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
	var boletos_dictionary = _read_json_root(boletos_dir_path)
	var board_dictionary = _read_json_root(board_dir_path)

	# The boletos of today come first: the emails print them, the bank registers them and the
	# events wait on their codes
	var today_board: Dictionary = board_dictionary.get("days", {}).get(str(GameData.current_day), {})
	GameData.accepted_banks_today = _get_accepted_banks(today_board)
	boletos_director.setup(
		boletos_dictionary,
		rules_array,
		GameData.accepted_banks_today,
		pix_dictionary.keys() + tickets_dictionary.keys()
	)
	boletos_director.bind_events(events_dictionary)

	# StoryDirector provides data, directors interpret and request schedules upward
	messages_director.setup_from_json_roots(message_roots)
	emails_director.setup_from_json_roots(email_roots, boletos_director.boletos_today)
	browser_director.reviews_director.setup_from_json_array(reviews_array)
	browser_director.shops_director.setup_from_json_file(shops_dictionary)
	bank_director.setup_from_json_file(pix_dictionary, tickets_dictionary)
	bank_director.set_boletos(boletos_director.get_registered_codes())
	var task_roots: Array = _drop_missing_random_events(tasks_roots)
	# The Pix of Messages say their bank too, as boletos do
	var held_back_events: Array = boletos_director.get_events_with_unaccepted_banks(
		events_dictionary, tickets_dictionary.merged(pix_dictionary)
	)
	randomness_director.setup_from_json_roots(
		task_roots,
		_drop_missing_random_events(scams_roots),
		events_dictionary,
		rules_array,
		held_back_events,
		messages_director.get_contact_names(),
		messages_director.get_contact_names_of_today()
	)
	# A task held back by its bank never comes today, its sender asks for nothing
	var tasks_coming: Array = []
	for event in task_roots[0]:
		if not held_back_events.has(randomness_director._get_event_id(event)):
			tasks_coming.append(event)
	_publish_trusted_senders(tasks_coming, events_dictionary)
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

## Banks the company accepts today: data/notes/board.json lists them per difficulty ("easy",
## "normal" and "hard"), the harder the more banks a boleto is checked against
##
## today_board: The day of data/notes/board.json, without banks before they are checked
func _get_accepted_banks(today_board: Dictionary) -> Array:
	var banks_by_difficulty: Dictionary = today_board.get("accepted_banks", {})
	var difficulty := str(GameData.Difficulty.find_key(GameData.get_difficulty())).to_lower()
	return banks_by_difficulty.get(difficulty, [])

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
	# A blocked email scam is ended by its deletion instead
	if not active_awaiting_delete and not events_director.is_event_pending(active_event_id):
		_release_lock()

## Handles scam_blocked from events director: a blocked conversation goes no further, so its
## queued messages are dropped and it stops holding the other chats
func _on_scam_blocked(conversation_ids: Array) -> void:
	for conversation_id in conversation_ids:
		_end_chat(_get_owner("messages", str(conversation_id)))

## Handles delete_offered from email director: a blocked email scam in progress keeps its turn
## until the player deletes it, or for lock_timeout_minutes at most
func _on_delete_offered(thread_id: String) -> void:
	if active_owner != _get_owner("emails", thread_id):
		return
	active_awaiting_delete = true
	lock_last_activity = int(GameData.hours_minutes)

## Handles thread_closed from email director: the player deleted the thread, which goes no further
func _on_thread_closed(thread_id: String) -> void:
	_end_chat(_get_owner("emails", thread_id))

## Ends a chat for good: its queued entries are dropped and it stops holding the other chats
func _end_chat(owner: String) -> void:
	if active_owner == owner:
		_release_lock()
	for queue in [main_queue, random_queue]:
		for entry_index in range(queue.size() - 1, -1, -1):
			if queue[entry_index]["owner"] == owner:
				queue.remove_at(entry_index)

## Whether the chat in progress is a random task or scam still to be done, which its timeout loses
func _is_losable() -> bool:
	return active_owner != "" and lane_by_owner.get(active_owner, Lane.MAIN) == Lane.RANDOM \
		and active_event_id != "" and not active_awaiting_delete \
		and events_director.is_event_pending(active_event_id)

## Has the contact of the random task or scam in progress ask if the player is still there, once
## per wait, lock_warning_minutes before its timeout. It is no activity: the time left is the same
func _warn_before_losing(current_minutes: int) -> void:
	if lock_timeout_minutes <= 0 or not _is_losable():
		return
	if current_minutes - lock_last_activity < lock_timeout_minutes - lock_warning_minutes:
		return
	if _warned_owners.get(active_owner, -1) == lock_last_activity:
		return
	_warned_owners[active_owner] = lock_last_activity
	var channel_name := active_owner.get_slice(":", 0)
	var chat_id := active_owner.substr(channel_name.length() + 1)
	if channel_name == "messages":
		messages_director.send_nudge(chat_id)
	else:
		emails_director.send_nudge(chat_id)

## Loses the random task or scam in progress when its time ran out before the player did it: its
## contact goes offline and nothing of it goes on, see EventsDirector.lose_event()
func _lose_timed_out_chat(current_minutes: int) -> void:
	if lock_timeout_minutes <= 0 or not _is_losable():
		return
	if current_minutes - lock_last_activity < lock_timeout_minutes:
		return
	var owner := active_owner
	var channel_name := owner.get_slice(":", 0)
	var chat_id := owner.substr(channel_name.length() + 1)
	var pieces: Array = []
	if channel_name == "messages":
		pieces.append({"source": "messages", "conversation": chat_id})
		GameData.lost_conversations.append(chat_id)
		messages_director.forget_chat(chat_id)
	else:
		for email in emails_director.emails_by_id.get(chat_id, []):
			pieces.append({"source": "email", "email_id": str(email.get("email_id", ""))})
		GameData.lost_threads.append(chat_id)
	events_director.lose_event(active_event_id, pieces)
	_end_chat(owner)
	chat_lost.emit(channel_name, chat_id)
	_publish_online_chats()

## Tells the UI which contacts are online: the chat in progress, and every chat whose event of
## today is still to be done. Once done or lost, the contact is offline
func _publish_online_chats() -> void:
	var owners: Array = []
	if active_owner != "":
		owners.append(active_owner)
	for owner in event_by_owner:
		if not owners.has(owner) and events_director.is_event_pending(event_by_owner[owner]):
			owners.append(owner)
	owners.sort()
	if owners != _online_owners:
		_online_owners = owners
		online_chats_changed.emit(owners)

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
	_publish_online_chats()
	# Whatever chat is in progress, as the answers belong to a message already delivered
	messages_director.present_held_choices(_are_requirements_met)

	if active_owner != "" and not _should_release_lock(current_minutes):
		_warn_before_losing(current_minutes)
		for queue in [main_queue, random_queue]:
			if _deliver_first_ready(queue, current_minutes, active_owner):
				return
		return

	_lose_timed_out_chat(current_minutes)
	_release_lock()
	if debug_isolated:
		for queue in [main_queue, random_queue]:
			if _deliver_first_ready(queue, current_minutes, "", true):
				return
		return

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

	# An email scam the player blocked, waiting to be deleted
	if active_awaiting_delete:
		return is_timed_out

	# A random task that said everything, waiting for the player to do it
	if active_chat_done:
		return is_timed_out or not events_director.is_event_pending(active_event_id)

	for queue in [main_queue, random_queue]:
		for story_entry in queue:
			if story_entry["owner"] != active_owner or not story_entry["continues"]:
				continue
			var is_due := _is_due(story_entry, current_minutes)
			if not is_due or _requirements_met(story_entry):
				return false
			# Its next message waits on something done outside the chat
			return story_entry["lane"] == Lane.MAIN or is_timed_out

	# Nothing queued: the NPC is typing, or it waits for an answer or for the email to be read
	return is_timed_out

## Delivers the first due entry of the queue whose requirements are met, returning whether it did
##
## owner: When given, only the next messages of that chat are delivered
## continuing_only: Only the next messages of chats already delivered, no new chat
func _deliver_first_ready(
	queue: Array[Dictionary], current_minutes: int, owner: String = "", continuing_only := false
) -> bool:
	for entry_index in range(queue.size()):
		var story_entry := queue[entry_index]

		# Ordered by due_at, so no entry after this one is due either
		if not _is_due(story_entry, current_minutes):
			return false

		if owner != "" and (story_entry["owner"] != owner or not story_entry["continues"]):
			continue
		if continuing_only and not story_entry["continues"]:
			continue

		# Entries blocked by unmet requirements are skipped for now, checking only the head would
		# cause a head-of-line blocking
		if not _requirements_met(story_entry):
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
	active_awaiting_delete = false
	lock_last_activity = current_minutes
	lane_by_owner[active_owner] = story_entry["lane"]
	# The event a random task waits on comes with its first message
	if not is_same_chat:
		active_event_id = event_id if story_entry["lane"] == Lane.RANDOM else ""
	if event_id != "" and not event_by_owner.has(active_owner):
		event_by_owner[active_owner] = event_id

	var controller: Node = channel_director_by_name[story_entry["channel"]]
	events_director._on_event_initiated(event_id)
	controller.deliver_scheduled_entry(payload, current_minutes)

## Lets every other chat go on
func _release_lock() -> void:
	active_owner = ""
	active_event_id = ""
	active_chat_done = false
	active_awaiting_delete = false
#endregion CLOCK

#region QUEUE OPS
## Clears the story queues, the chat in progress and resets sequence counter
func _clear_story_queue() -> void:
	main_queue.clear()
	random_queue.clear()
	story_enqueue_seq = 0
	_release_lock()
	lane_by_owner.clear()
	event_by_owner.clear()
	_warned_owners.clear()
	_online_owners = []
	online_chats_changed.emit(_online_owners)

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
## Evaluates if all requirements of the given story entry are met
func _requirements_met(story_entry: Dictionary) -> bool:
	var requirements: Array = story_entry["requires"]
	if requirements.is_empty():
		return true
	return _are_requirements_met(requirements, _get_branch_event(story_entry["payload"]))

## Evaluates if all requirements in the given array are met
##
## event_id: The event of the chat they belong to, a purchase only counts when bought for it
func _are_requirements_met(requirements: Array, event_id: String = "") -> bool:
	for requirement in requirements:
		var expected = bool(requirement.get("is", true))
		if _evaluate_requirement(requirement, event_id) != expected:
			return false

	return true

## The event a chat message belongs to: the one a message of its branch starts (a story branch like
## "d2_start"), else the branch itself, named after its event for random tasks and scams
func _get_branch_event(payload: Dictionary) -> String:
	var branch := str(payload.get("branch", ""))
	var conversation: Dictionary = messages_director.conversations_by_id.get(
		str(payload.get("conversation_id", "")), {}
	)
	for node in conversation.get("branches", {}).get(branch, []):
		if str(node.get("event_id", "")) != "":
			return str(node["event_id"])
	return branch

## Evaluates a single requirement flag
##
## event_id: The event of the chat, a purchase only counts when bought for it
func _evaluate_requirement(requirement: Dictionary, event_id: String) -> bool:
	var flag = requirement.get("flag", "")
	if flag == "app_installed":
		var app_id = requirement.get("app_id", "")
		var app = GameData.apps_name.get(app_id, null)
		return GameData.downloaded_apps.has(app)
	if flag == "purchase":
		return events_director.has_purchased(event_id, requirement.get("items", []))
	if flag == "payment":
		# A boleto of today is paid by the code it was given today
		var payment_id = requirement.get(
			"payment_id", boletos_director.get_code(str(requirement.get("boleto_id", "")))
		)
		return GameData.completed_payments.has(payment_id)
	# Read without being consumed, unlike events_director, so a story beat can wait for it
	if flag == "option":
		return GameData.options_chose.has(requirement.get("choice", ""))
	if flag == "email_read":
		return GameData.read_emails.has(requirement.get("email_id", ""))
	if flag == "seen":
		return GameData.has_seen(str(requirement.get("info", "")))

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
