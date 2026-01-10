extends Node

#region SIGNALS
signal email_received(email_data: Dictionary)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var emails_dir_path: String = "res://data/emails"
@export var email_app_home: Node
#endregion CHILDREN NODES REFERENCES

#region STATE
# subject -> Array[Dictionary] (email thread messages in order)
var emails_by_subject: Dictionary = {}

# Queue entries:
# {"subject":String, "thread_index":int, "due_at":int, "seq":int, "requires":Array}
var email_queue: Array[Dictionary] = []
var enqueue_seq: int = 0
#endregion STATE

#region INITIALIZATION
func _ready() -> void:
	_load_emails_from_directory()
	_queue_today_emails()
#endregion INITIALIZATION

#region LOADING EMAILS
func _load_emails_from_directory() -> void:
	emails_by_subject.clear()

	var opened_dir := DirAccess.open(emails_dir_path)
	if opened_dir == null:
		push_error("EmailsDirector: Failed to open dir: %s" % emails_dir_path)
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

		_load_one_json_file(emails_dir_path.path_join(file_name), file_name)

	opened_dir.list_dir_end()

func _load_one_json_file(path: String, source_name: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("EmailsDirector: Failed to open file: %s" % path)
		return

	var json_parser := JSON.new()
	var parse_error := json_parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
      "EmailsDirector: JSON parse error (%s) in %s" % [json_parser.get_error_message(), path]
    )
		return

	var root: Variant = json_parser.data

	# Supported shapes:
	# - [ {email}, {email} ]
	if typeof(root) == TYPE_ARRAY:
		_register_email_list(root as Array, source_name)
	else:
		push_error("EmailsDirector: Unexpected JSON shape in %s" % path)

func _register_email_list(email_list: Array, source_name: String) -> void:
	for i in range(email_list.size()):
		if typeof(email_list[i]) != TYPE_DICTIONARY:
			continue
		_register_one_email(email_list[i] as Dictionary, source_name, i)

func _register_one_email(email_dict: Dictionary, source_name: String, index_in_file: int) -> void:
	var subject := str(email_dict.get("subject", "")).strip_edges()
	if subject == "":
		push_error("EmailsDirector: Missing subject in %s (index %d)" % [source_name, index_in_file])
		return

	var allow_append := bool(email_dict.get("append", false))

	if emails_by_subject.has(subject):
		if not allow_append:
			push_warning(
				"EmailsDirector: Duplicate subject '%s' in %s (index %d). " %
				[subject, source_name, index_in_file] +
				"Set 'append': true to add to the same thread."
			)
			return

		# Append to existing thread
		var thread_emails: Array = emails_by_subject[subject]
		thread_emails.append(email_dict)
		emails_by_subject[subject] = thread_emails
		return

	# First email for this subject => start a new thread
	emails_by_subject[subject] = [email_dict]
#endregion LOADING EMAILS

#region QUEUING EMAILS
func _queue_today_emails() -> void:
	email_queue.clear()
	enqueue_seq = 0

	for subject in emails_by_subject.keys():
		var thread_emails: Array = emails_by_subject[subject]

		for thread_index in range(thread_emails.size()):
			var email_dict: Dictionary = thread_emails[thread_index]

			if int(email_dict.get("day", -999)) != int(GameData.data.current_day):
				continue

			var relative_due_time: float = float(email_dict.get("relative_due_time", INF))
			if relative_due_time == INF:
				continue

			var absolute_due_time := int(relative_due_time) + int(GameData.starting_hours_minutes)
			var requires: Array = email_dict.get("requires", [])

			_enqueue_queue_entry(subject, thread_index, absolute_due_time, requires)

func _enqueue_queue_entry(
  subject: String,
  thread_index: int,
  absolute_due_time: int,
  requires: Array = []
) -> void:
	var queue_entry: Dictionary = {
		"subject": subject,
		"thread_index": thread_index,
		"due_at": absolute_due_time,
		"seq": enqueue_seq,
		"requires": requires,
	}
	enqueue_seq += 1
	_insert_sorted_by_due(queue_entry)

func _insert_sorted_by_due(queue_entry: Dictionary) -> void:
	var due_at := int(queue_entry.get("due_at", 0))
	var seq := int(queue_entry.get("seq", 0))

	for i in range(email_queue.size()):
		var existing := email_queue[i]
		var existing_due := int(existing.get("due_at", 0))

		if existing_due > due_at:
			email_queue.insert(i, queue_entry)
			return

		if existing_due == due_at and int(existing.get("seq", 0)) > seq:
			email_queue.insert(i, queue_entry)
			return

	email_queue.append(queue_entry)
#endregion QUEUING EMAILS

#region DELIVERY OF EMAILS
func on_clock_tick(current_minutes: int) -> void:
	if email_queue.is_empty():
		return

	var head: Dictionary = email_queue[0]
	if current_minutes < int(head.get("due_at", 0)):
		return

	var index := 0
	while index < email_queue.size():
		var entry: Dictionary = email_queue[index]

		if current_minutes < int(entry.get("due_at", 0)):
			break

		if not _requirements_met(entry.get("requires", [])):
			entry["due_at"] = current_minutes + 1
			email_queue.remove_at(index)
			_insert_sorted_by_due(entry)
			return

		_deliver_queue_entry(entry, current_minutes)
		email_queue.remove_at(index)
		return

func _deliver_queue_entry(queue_entry: Dictionary, current_minutes: int) -> void:
	var subject := str(queue_entry.get("subject", ""))
	var thread_index := int(queue_entry.get("thread_index", -1))

	var thread_emails: Array = emails_by_subject.get(subject, [])
	if thread_index < 0 or thread_index >= thread_emails.size():
		return

	var email_dict: Dictionary = thread_emails[thread_index]

	if not _requirements_met(email_dict.get("requires", [])):
		queue_entry["due_at"] = current_minutes + 1
		_insert_sorted_by_due(queue_entry)
		return

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
		"annex": (
			attachments[0]
			if (attachments.size() > 0 and typeof(attachments[0]) == TYPE_DICTIONARY)
			else {}
		),
		"day": int(email_dict.get("day", 0)),
		"delivered_at": int(queue_entry.get("due_at", current_minutes)),
	}

	if email_app_home != null:
		if email_app_home.has_method("receive_email"):
			email_app_home.call("receive_email", delivered_email)
		elif email_app_home.has_method("add_email"):
			email_app_home.call("add_email", delivered_email)
		else:
			email_received.emit(delivered_email)
	else:
		email_received.emit(delivered_email)
#endregion DELIVERY OF EMAILS

#region REQUIREMENTS
func _requirements_met(requirements: Array) -> bool:
	if requirements.is_empty():
		return true

	for requirement in requirements:
		if typeof(requirement) != TYPE_DICTIONARY:
			continue

		var flag := str(requirement.get("flag", ""))
		var expected := bool(requirement.get("is", true))
		var evaluation := _evaluate_flag(flag)

		if evaluation != expected:
			return false

	return true

func _evaluate_flag(flag: String) -> bool:
	if flag in GameData.apps_name.keys():
		return GameData.downloaded_apps.has(GameData.apps_name[flag])
	return false
#endregion REQUIREMENTS
