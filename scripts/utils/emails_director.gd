extends Node

#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
signal email_received(email_data: Dictionary)
## Emitted once the player reads the email delivered in a thread, so the other chats can go on
signal thread_finished(thread_id: String)
## Emitted when a scam sent in a thread is blocked, so the thread offers to be deleted
signal delete_offered(thread_id: String)
## Emitted once the player deletes a thread, which ends it for good
signal thread_closed(thread_id: String)
#endregion SIGNALS

#region CONSTANTS
## A boleto field written in an email, "{boleto:<boleto_id>.<field>}", filled in on delivery
const BOLETO_PLACEHOLDER := "\\{boleto:([A-Za-z0-9_]+)\\.([a-z_]+)\\}"
#endregion CONSTANTS

#region STATE
var emails_by_id: Dictionary = {}
## thread_id -> email_id of the email delivered there that the player has not read yet
var unread_email_by_thread: Dictionary = {}
## event_id -> thread_id the email of that event was delivered in today
var thread_by_event: Dictionary = {}
## boleto_id -> boleto of today, as made by the BoletosDirector
var boletos: Dictionary = {}
## Threads waiting on a follow-up (an NPC thanking for the task done), which they do not end before
var threads_awaiting_follow_up: Dictionary = {}

var _boleto_placeholder := RegEx.create_from_string(BOLETO_PLACEHOLDER)
#endregion STATE

#region SETUP
## Sets up emails from JSON roots (called by StoryDirector)
##
## boletos_today: boleto_id -> boleto of today, whose fields fill the emails delivered
func setup_from_json_roots(json_roots: Array, boletos_today: Dictionary = {}) -> void:
	emails_by_id.clear()
	unread_email_by_thread.clear()
	thread_by_event.clear()
	threads_awaiting_follow_up.clear()
	boletos = boletos_today

	for root in json_roots:
		_register_emails_from_root(root)

	_queue_today_emails()
#endregion SETUP

#region REGISTER EMAILS
## Registers emails from a JSON root Variant
func _register_emails_from_root(root: Variant) -> void:
	# Our email files are array[Dictionary]: [ { ... }, { ... } ]
	assert(typeof(root) == TYPE_ARRAY)

	for email_dict in root:
		if typeof(email_dict) != TYPE_DICTIONARY:
			continue
		_register_one_email(email_dict)

## Registers a single email given its dictionary
func _register_one_email(email_dict: Dictionary) -> void:
	var thread_id := str(email_dict["thread_id"]).strip_edges()
	assert(thread_id != "")

	# If an email with this subject already exists, we can only append to its thread
	# This allow us to consider one email as head of a thread, and subsequent emails as replies
	var allow_append := bool(email_dict.get("append", false))

	## If no append flag, it will fail fast on duplicates
	if emails_by_id.has(thread_id):
		assert(allow_append)
		var thread: Array = emails_by_id[thread_id]
		thread.append(email_dict)
		emails_by_id[thread_id] = thread
		return

	emails_by_id[thread_id] = [email_dict]

## Whether an email registered is in the given thread
func has_email(thread_id: String, email_id: String) -> bool:
	return emails_by_id.get(thread_id, []).any(
		func(email: Dictionary) -> bool: return email.get("email_id") == email_id
	)
## Address an email registered is sent from, empty when there is no such email
func get_sender(thread_id: String, email_id: String) -> String:
	for email in emails_by_id.get(thread_id, []):
		if email.get("email_id") == email_id:
			return str(email.get("sender", "")).strip_edges()
	return ""

## Emails the story sends on a day, the random ones have no day of their own
func get_emails_of_day(day: int) -> Array:
	var emails: Array = []
	for thread in emails_by_id.values():
		for email in thread:
			if email.has("day") and int(email["day"]) == day:
				emails.append(email)
	return emails
#endregion REGISTER EMAILS

#region SCHEDULING TODAY
## Queues today's emails for all registered email threads
func _queue_today_emails() -> void:
	for id in emails_by_id.keys():
		var thread: Array = emails_by_id[id]

		for email in thread:
			var email_id = email.get("email_id", "")
			assert(email_id != "")

			if int(email.get("day", -999)) != int(GameData.current_day):
				continue

			var relative_due_time: float = float(email.get("relative_due_time", INF))
			assert(relative_due_time != INF)

			var absolute_due_time := int(relative_due_time) + int(GameData.starting_hours_minutes)
			var requires: Array = email.get("requires", [])

			var event_id = email.get("event_id", "")

			schedule_entry_requested.emit({
				"thread_id": id,
				"email_id": email_id,
				"due_at": absolute_due_time,
				"requires": requires,
				"event_id": event_id,
			})
#endregion SCHEDULING TODAY

#region DELIVERY (CALLED DOWN BY STORYDIRECTOR)
## Delivers a scheduled email entry
##
## The email after it in its thread, when it has no day of its own, is its follow-up: it is queued
## at once and comes as soon as its requirements are met (the NPC thanks once the task is done).
## The thread waits for it, and ends once it is delivered, without waiting for it to be read.
func deliver_scheduled_entry(schedule_entry: Dictionary, current_minutes: int) -> void:
	var thread_id := str(schedule_entry["thread_id"])
	var email_id := str(schedule_entry["email_id"])

	var thread: Array = emails_by_id[thread_id]
	var email_index := thread.find_custom(func(email): return email.get("email_id") == email_id)
	var email_dict: Dictionary = thread[email_index]

	var attachments: Array = email_dict.get("attachments", []).map(_resolve_attachment)

	var delivered_email: Dictionary = {
		# payload
		"thread_id": thread_id,
		"email_id": email_id,
		"sender": email_dict.get("sender"),
		"subject": _resolve_boleto_fields(str(email_dict.get("subject"))),
		"content": _resolve_boleto_fields(str(email_dict.get("content"))),
		"attachments": attachments,
		"day": email_dict.get("day"),
		# When it really arrived, a chat in progress may have held it past its due time
		"relative_due_time": float(current_minutes - GameData.starting_hours_minutes),
	}

	var event_id := str(schedule_entry.get("event_id", ""))
	if not event_id.is_empty():
		thread_by_event[event_id] = thread_id

	var is_follow_up := threads_awaiting_follow_up.has(thread_id)
	threads_awaiting_follow_up.erase(thread_id)
	var follow_up: Dictionary = {}
	if email_index + 1 < thread.size() and not thread[email_index + 1].has("day"):
		follow_up = thread[email_index + 1]
		threads_awaiting_follow_up[thread_id] = true

	email_received.emit(delivered_email)
	if is_follow_up and follow_up.is_empty():
		thread_finished.emit(thread_id)
	else:
		unread_email_by_thread[thread_id] = email_id

	if not follow_up.is_empty():
		schedule_entry_requested.emit({
			"thread_id": thread_id,
			"email_id": str(follow_up.get("email_id", "")),
			"due_at": current_minutes,
			"requires": follow_up.get("requires", []),
			"event_id": "",
			"continues": true,
		})

## Turns a boleto attachment ({"type": "boleto", "boleto_id"}) into the boleto of today, the way
## it is printed, so the email keeps showing the same boleto once saved. Other attachments are
## kept as they are
func _resolve_attachment(attachment: Variant) -> Variant:
	if not attachment is Dictionary or attachment.get("type", "") != "boleto":
		return attachment

	var boleto_id := str(attachment.get("boleto_id", ""))
	if not boletos.has(boleto_id):
		push_error("Boleto attached to an email not found: %s" % boleto_id)
		return attachment

	var boleto: Dictionary = boletos[boleto_id]
	return {
		"type": "boleto",
		"boleto_id": boleto_id,
		"name": str(attachment.get("name", "Boleto %s.pdf" % boleto["code"])),
		"code": boleto["code"],
		"printed": boleto["printed"].duplicate(),
	}

## Fills the "{boleto:<boleto_id>.<field>}" of a text with the boleto of today, as printed
##
## field: "code", "value" (in R$) or any other printed field ("payee", "bank", "due_date"...)
func _resolve_boleto_fields(text: String) -> String:
	for match_result in _boleto_placeholder.search_all(text):
		var boleto_id := match_result.get_string(1)
		var field := match_result.get_string(2)
		if not boletos.has(boleto_id):
			push_error("Boleto written in an email not found: %s" % boleto_id)
			continue

		var boleto: Dictionary = boletos[boleto_id]
		var printed: Dictionary = boleto["printed"]
		var value: String
		match field:
			"code":
				value = str(boleto["code"])
			"value":
				value = GameData.format_brl(float(printed["value"]))
			_:
				value = str(printed.get(field, ""))
		text = text.replace(match_result.get_string(), value)
	return text
#endregion DELIVERY

#region DELETION
## Offers to delete the thread a blocked scam was sent in today, if it came by email
##
## Called down from the events director's scam_event_blocked, through the game screen
func offer_delete(event_id: String) -> void:
	if thread_by_event.has(event_id):
		delete_offered.emit(thread_by_event[event_id])

## Ends a thread the player deleted, so the StoryDirector can move on to the next chat
func on_thread_deleted(thread_id: String) -> void:
	unread_email_by_thread.erase(thread_id)
	thread_closed.emit(thread_id)
#endregion DELETION

#region CLOCK
## Called by StoryDirector every tick: finishes the threads whose email the player read, unless they
## still wait on a follow-up
func _on_clock_tick() -> void:
	for thread_id in unread_email_by_thread.keys():
		if GameData.read_emails.has(unread_email_by_thread[thread_id]):
			unread_email_by_thread.erase(thread_id)
			if not threads_awaiting_follow_up.has(thread_id):
				thread_finished.emit(thread_id)
#endregion CLOCK
