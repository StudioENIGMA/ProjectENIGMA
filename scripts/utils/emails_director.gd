extends Node

#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
signal email_received(email_data: Dictionary)
#endregion SIGNALS

#region STATE
var emails_by_id: Dictionary = {}
#endregion STATE

#region SETUP
## Sets up emails from JSON roots (called by StoryDirector)
func setup_from_json_roots(json_roots: Array) -> void:
	emails_by_id.clear()

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

			schedule_entry_requested.emit({
				"thread_id": id,
				"email_id": email_id,
				"due_at": absolute_due_time,
				"requires": requires,
			})
#endregion SCHEDULING TODAY

#region DELIVERY (CALLED DOWN BY STORYDIRECTOR)
## Delivers a scheduled email entry
func deliver_scheduled_entry(schedule_entry: Dictionary, _current_minutes: int) -> void:
	var thread_id := str(schedule_entry["thread_id"])
	var email_id := str(schedule_entry["email_id"])

	var thread: Array = emails_by_id[thread_id]
	var email_dict: Dictionary = thread.filter(func(email): return email.get("email_id") == email_id)[0]

	var attachments: Array = email_dict.get("attachments", [])

	var delivered_email: Dictionary = {
		# payload
		"thread_id": thread_id,
		"sender": email_dict.get("sender"),
		"subject": email_dict.get("subject"),
		"content": email_dict.get("content"),
		"attachments": attachments,
		"day": email_dict.get("day"),
		"relative_due_time": float(email_dict.get("relative_due_time", 0.0)),
	}

	email_received.emit(delivered_email)
#endregion DELIVERY
