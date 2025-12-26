extends Node2D

@export var all_messages:Array[Message] = []
@export var event_handler:Node2D

var pending_messages:Array[Message] = []
var next_message_due_at:int = -1

var messages_waiting_answers:Dictionary = {}      # Message -> Array[int]
var answers_waiting_response:Dictionary = {}      # int -> Message

func _ready() -> void:
	EventBus.message_answered.connect(_on_message_answered)
	event_handler.clock_tick.connect(_on_clock_tick)

	_build_today_queue()
	_schedule_next_message()

func _build_today_queue() -> void:
	pending_messages.clear()
	for message in all_messages:
		if message.day == GameData.data.current_day and not message.is_answer and not message.is_next:
			pending_messages.append(message)

	pending_messages.sort_custom(_sort_by_priority)

func _schedule_next_message() -> void:
	if pending_messages.is_empty():
		next_message_due_at = 999999999
		return

	var next_message:Message = pending_messages[0]
	if next_message.priority <= 0:
		next_message_due_at = GameData.hours_minutes
	else:
		# rough equivalent of your old random delay timer
		next_message_due_at = GameData.hours_minutes + randi_range(2, 4)

func _on_clock_tick(current_minutes:int) -> void:
	if pending_messages.is_empty():
		return
	if current_minutes < next_message_due_at:
		return

	var next_message:Message = pending_messages[0]

	# keep waiting until conditions become true
	if not _conditions_met(next_message):
		return

	# consume + deliver
	pending_messages.pop_front()
	_deliver_message(next_message)

	# schedule the next one
	_schedule_next_message()

func _deliver_message(message:Message) -> void:
	# NPC message -> go through EventHandler signal path you already have wired to MessagesApp
	event_handler.npc_message_created.emit(
		message.sender,
		message.text,
		EventBus.Sender.OTHER,
		str(GameData.hours_minutes)
	)

	# After delivering, unlock answers / next messages (this is your old add_depedencies_to_queue)
	_enqueue_followups(message)

func _enqueue_followups(message:Message) -> void:
	var answer_ids:Array[int] = []
	var has_answers:bool = not message.answers.is_empty()

	if has_answers:
		for answer_resource in message.answers.keys():
			var answer:Message = answer_resource
			var generated_id:int = Resource.generate_scene_unique_id().to_int()
			answer.id = generated_id
			answer.priority = message.priority
			answer_ids.append(generated_id)

			answers_waiting_response[generated_id] = answer

			# Show as an answer option (this is what your old message_instance did via EventBus.answer_option)
			EventBus.answer_option.emit(
				answer.sender,
				answer.text,
				answer.text,
				1000,
				GameData.hours_minutes,
				generated_id
			)

	if message.next_message == null:
		return

	message.next_message.priority = message.priority

	if has_answers:
		messages_waiting_answers[message.next_message] = answer_ids
	else:
		_add_message_to_pending(message.next_message)

func _on_message_answered(answer_id:int) -> void:
	# 1) Unlock waiting messages
	for waiting_message in messages_waiting_answers.keys():
		var ids:Array = messages_waiting_answers[waiting_message]
		if ids.has(answer_id):
			_add_message_to_pending(waiting_message)

	# 2) Process answer side-effects (your old process_answers)
	if answers_waiting_response.has(answer_id):
		var answered_message:Message = answers_waiting_response[answer_id]
		_process_answer_task(answered_message)

func _process_answer_task(answer_message:Message) -> void:
	if answer_message.task_type == Message.TaskType.INSTALL:
		AppsControl.download_app(answer_message.installer)

func _add_message_to_pending(message:Message) -> void:
	pending_messages.append(message)
	pending_messages.sort_custom(_sort_by_priority)
	# if we were idle / waiting far in the future, reschedule sooner
	_schedule_next_message()

func _sort_by_priority(a:Message, b:Message) -> bool:
	return a.priority < b.priority

func _conditions_met(message:Message) -> bool:
	var downloaded_apps = AppsControl.get_downloaded_apps()

	# same keys you used in message_instance.gd
	if message.conditions.has("settings") and (downloaded_apps.has(AppControl.App.SETTINGS) != message.conditions["settings"]):
		return false
	if message.conditions.has("browser") and (downloaded_apps.has(AppControl.App.BROWSER) != message.conditions["browser"]):
		return false
	if message.conditions.has("mail") and (downloaded_apps.has(AppControl.App.EMAIL) != message.conditions["mail"]):
		return false
	if message.conditions.has("fake_store") and (downloaded_apps.has(AppControl.App.FAKESTORE) != message.conditions["fake_store"]):
		return false
	if message.conditions.has("store") and (downloaded_apps.has(AppControl.App.STORE) != message.conditions["store"]):
		return false

	return true
