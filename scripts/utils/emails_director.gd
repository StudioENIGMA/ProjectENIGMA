# res://scripts/story/emails/emails_controller.gd
extends Node

#region SIGNALS
signal schedule_entry_requested(schedule_entry: Dictionary)
signal email_received(email_data: Dictionary)
#endregion SIGNALS

#region STATE
# subject -> Array[Dictionary]
var emails_by_subject: Dictionary = {}
#endregion STATE

#region SETUP
func setup_from_json_roots(json_roots: Array) -> void:
	emails_by_subject.clear()

	for root in json_roots:
		_register_emails_from_root(root)

	_queue_today_emails()
#endregion SETUP

#region REGISTER EMAILS
func _register_emails_from_root(root: Variant) -> void:
	# Your current email files are arrays: [ { ... }, { ... } ]
	assert(typeof(root) == TYPE_ARRAY)

	for email_dict in root:
		if typeof(email_dict) != TYPE_DICTIONARY:
			continue
		_register_one_email(email_dict)

func _register_one_email(email_dict: Dictionary) -> void:
	var subject := str(email_dict["subject"]).strip_edges()
	assert(subject != "")

	var allow_append := bool(email_dict.get("append", false))

	if emails_by_subject.has(subject):
		assert(allow_append)
		var thread: Array = emails_by_subject[subject]
		thread.append(email_dict)
		emails_by_subject[subject] = thread
		return

	emails_by_subject[subject] = [email_dict]
#endregion REGISTER EMAILS

#region SCHEDULING TODAY
func _queue_today_emails() -> void:
	for subject in emails_by_subject.keys():
		var thread: Array = emails_by_subject[subject]

		for thread_index in range(thread.size()):
			var email_dict: Dictionary = thread[thread_index]

			if int(email_dict.get("day", -999)) != int(GameData.data.current_day):
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
func deliver_scheduled_entry(schedule_entry: Dictionary, _current_minutes: int) -> void:
	var subject := str(schedule_entry["subject"])
	var thread_index := int(schedule_entry["thread_index"])

	var thread: Array = emails_by_subject[subject]
	var email_dict: Dictionary = thread[thread_index]

	var attachments: Array = email_dict.get("attachments", [])

	var delivered_email: Dictionary = {
		# thread identity
		"thread_subject": subject,
		"thread_index": thread_index,

		# payload
		"sender_name": str(email_dict.get("sender", "")),
		"subject": subject,
		"content": str(email_dict.get("content", "")),
		"attachments": attachments,
		"day": int(email_dict.get("day", 0)),
		"relative_due_time": float(email_dict.get("relative_due_time", 0.0)),
	}

	# Signal outward; UI sibling (EmailAppHome) listens and instantiates UI.
	email_received.emit(delivered_email)
#endregion DELIVERY
