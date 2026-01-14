extends Node

#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
signal email_received(email_data: Dictionary)
#endregion SIGNALS

#region STATE
var emails_by_subject: Dictionary = {}
#endregion STATE

#region SETUP
## Sets up emails from JSON roots (called by StoryDirector)
func setup_from_json_roots(json_roots: Array) -> void:
	emails_by_subject.clear()

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
	var subject := str(email_dict["subject"]).strip_edges()
	assert(subject != "")

	# If an email with this subject already exists, we can only append to its thread
	# This allow us to consider one email as head of a thread, and subsequent emails as replies
	var allow_append := bool(email_dict.get("append", false))

	## If no append flag, it will fail fast on duplicates
	if emails_by_subject.has(subject):
		assert(allow_append)
		var thread: Array = emails_by_subject[subject]
		thread.append(email_dict)
		emails_by_subject[subject] = thread
		return

	emails_by_subject[subject] = [email_dict]
#endregion REGISTER EMAILS

#region SCHEDULING TODAY
## Queues today's emails for all registered email threads
func _queue_today_emails() -> void:
	for subject in emails_by_subject.keys():
		var thread: Array = emails_by_subject[subject]

		for thread_index in range(thread.size()):
			var email_dict: Dictionary = thread[thread_index]

			if int(email_dict.get("day", -999)) != int(GameData.current_day):
				continue

			var relative_due_time: float = float(email_dict.get("relative_due_time", INF))
			assert(relative_due_time != INF)

			var absolute_due_time := int(relative_due_time) + int(GameData.starting_hours_minutes)
			var requires: Array = email_dict.get("requires", [])

			schedule_entry_requested.emit({
				"subject": subject,
				"thread_index": thread_index,
				"due_at": absolute_due_time,
				"requires": requires,
			})
#endregion SCHEDULING TODAY

#region DELIVERY (CALLED DOWN BY STORYDIRECTOR)
## Delivers a scheduled email entry
func deliver_scheduled_entry(schedule_entry: Dictionary, _current_minutes: int) -> void:
	var subject := str(schedule_entry["subject"])
	var thread_index := int(schedule_entry["thread_index"])

	var thread: Array = emails_by_subject[subject]
	var email_dict: Dictionary = thread[thread_index]

	var attachments: Array = email_dict.get("attachments", [])

	var delivered_email: Dictionary = {
		# payload
		"sender": email_dict.get("sender"),
		"subject": subject,
		"content": email_dict.get("content"),
		"attachments": attachments,
		"day": email_dict.get("day"),
		"relative_due_time": float(email_dict.get("relative_due_time", 0.0)),
	}

	email_received.emit(delivered_email)
#endregion DELIVERY
