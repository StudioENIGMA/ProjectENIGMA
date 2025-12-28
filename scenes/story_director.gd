extends Node2D

signal npc_message_created(
	npc_name:String,
	message:String,
	sender:GameData.Sender,
	time:int
)

signal request_answer_option(
	npc_name:String,
	message:String,
	title:String,
	reputation_points:int,
	time:int,
	answer_id:int
)

@export var ui:Control

@export var all_messages:Array[Message] = []
@export var event_handler:Node2D

## Queue of messages to be delivered, sorted by due time
var message_queue:Array[Dictionary] = []

## Mapping of answer IDs to their corresponding Message instances
var answers_by_id:Dictionary = {}

## Mapping of answer IDs to lists of Message instances to unlock upon answering
var unlock_on_answer:Dictionary = {}

var _answer_id_counter := 1

## Initializes the story director by connecting to necessary signals and queuing today's messages
func _ready() -> void:
	ui.message_answered.connect(_on_message_answered)
	event_handler.clock_tick.connect(_on_clock_tick)

	_queue_today_messages()

## Queues messages that are scheduled for the current day
func _queue_today_messages() -> void:
	message_queue.clear()

	for message in all_messages:
		if message.day != GameData.data.current_day:
			continue
		if message.is_answer or message.is_next:
			continue

		_queue_message(message, _delay_for_priority(message.priority))

## Determines a delay based on message priority
##
## priority: The priority level of the message
func _delay_for_priority(priority:int) -> int:
	if priority <= 0:
		return 0
	return randi_range(2, 4)

## Queues a message to be delivered after a specified delay
##
## message: The Message instance to be queued
## delay_minutes: The delay in in-game minutes before delivery
func _queue_message(message:Message, delay_minutes:int) -> void:
	var due_at_minutes:int = GameData.hours_minutes + max(delay_minutes, 0)
	var queue_entry := { "message": message, "due_at": due_at_minutes }

	_insert_sorted_by_due(queue_entry)

## Inserts a message into the queue sorted by its due time
##
## queue_entry: Dictionary containing the message and its due time
func _insert_sorted_by_due(queue_entry:Dictionary) -> void:
	var index := 0

	# Insert in sorted order
	while index < message_queue.size() and message_queue[index].due_at <= queue_entry.due_at:
		index += 1
	message_queue.insert(index, queue_entry)

## Handles the clock tick event to deliver due messages
##
## Called every in-game 'minute' (1 second real time)
## It will always attempt to deliver messages that are due
## starting from the head of the queue
##
## current_minutes: The current in-game time in minutes
func _on_clock_tick(current_minutes:int) -> void:
	if message_queue.is_empty():
		return

	var head := message_queue[0]
	if current_minutes < head.due_at:
		return

	var message:Message = head.message

	# If conditions not met, postpone instead of blocking everything forever
	if not _conditions_met(message):
		message_queue.pop_front()
		# small backoff (1 minute) so we don't spin every tick
		_insert_sorted_by_due({ "message": message, "due_at": current_minutes + 1 })
		return

	# send it
	message_queue.pop_front()
	_deliver_message(message)

## Delivers a message by emitting the appropriate event and enqueuing follow-ups
##
## message: The Message instance to be delivered
func _deliver_message(message:Message) -> void:
	npc_message_created.emit(
		message.sender,
		message.text,
		GameData.Sender.NPC,
		GameData.hours_minutes
	)

	_enqueue_followups(message)

## Enqueues follow-up messages based on the provided message's answers and next message
##
## message: The Message instance whose follow-ups are to be enqueued
func _enqueue_followups(message:Message) -> void:
	var has_answers := not message.answers.is_empty()

	if has_answers:
		for answer_resource in message.answers.keys():
			var answer:Message = (answer_resource.duplicate(true) as Message)
			answer.priority = message.priority

			var answer_id := _new_answer_id()
			answers_by_id[answer_id] = answer

			# Show answer option
			request_answer_option.emit(
				message.sender,
				answer.text,
				answer.text,
				message.answers[answer_resource],
				GameData.hours_minutes,
				answer_id
			)

			# Track follow-ups for this answer
			if not unlock_on_answer.has(answer_id):
				unlock_on_answer[answer_id] = []

			# Follow-up that depends on THIS answer
			if answer.next_message != null:
				unlock_on_answer[answer_id].append(answer.next_message)

			# Follow-up that happens after ANY answer
			if message.next_message != null:
				unlock_on_answer[answer_id].append(message.next_message)

	else:
		if message.next_message != null:
			_queue_message(message.next_message, _delay_for_priority(message.priority))

func _new_answer_id() -> int:
	_answer_id_counter += 1
	return _answer_id_counter

## Handles the event when a message answer is selected by the player
##
## answer_id: The unique identifier for the answer option chosen
func _on_message_answered(answer_id:int) -> void:
	if unlock_on_answer.has(answer_id):
		for next_message:Message in unlock_on_answer[answer_id]:
			_queue_message(next_message, 0)
		unlock_on_answer.erase(answer_id)

	# ignore tasks for now
	if answers_by_id.has(answer_id):
		_process_answer_task(answers_by_id[answer_id])
		answers_by_id.erase(answer_id)

## Processes any tasks associated with the player's answer
##
## answer_message: The Message instance representing the player's answer
func _process_answer_task(_answer_message:Message) -> void:
	pass

## Checks if the conditions for delivering a message are met
##
## message: The Message instance to check conditions for
func _conditions_met(message:Message) -> bool:
	var downloaded_apps = GameData.downloaded_apps

	if message.conditions.has("settings"):
		var has_app = downloaded_apps.has(GameData.App.SETTINGS)
		if has_app != message.conditions["settings"]:
			return false
	if message.conditions.has("browser"):
		var has_app = downloaded_apps.has(GameData.App.BROWSER)
		if has_app != message.conditions["browser"]:
			return false
	if message.conditions.has("mail"):
		var has_app = downloaded_apps.has(GameData.App.EMAIL)
		if has_app != message.conditions["mail"]:
			return false
	if message.conditions.has("fake_store"):
		var has_app = downloaded_apps.has(GameData.App.FAKESTORE)
		if has_app != message.conditions["fake_store"]:
			return false
	if message.conditions.has("store"):
		var has_app = downloaded_apps.has(GameData.App.STORE)
		if has_app != message.conditions["store"]:
			return false

	return true
