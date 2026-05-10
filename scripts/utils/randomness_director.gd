extends Node

#region SIGNALS
signal schedule_message(story_entry: Dictionary)
signal schedule_email(story_entry: Dictionary)
#endregion SIGNALS

#region CONSTANTS
const random_tasks_delay = [0, 60, 30, 30, 30, 30, 30]

const number_of_events = [
	{
		"tasks": 0,
		"scams": 0
	},
	{
		"tasks": 2,
		"scams": 2
	},
	{
		"tasks": 3,
		"scams": 4
	},
	{
		"tasks": 7,
		"scams": 5
	},
	{
		"tasks": 10,
		"scams": 6
	},
	{
		"tasks": 11,
		"scams": 8
	},
	{
		"tasks": 12,
		"scams": 9
	},
]
#endregion CONSTANTS

#region STATES
var tasks_list: Array
var scams_list: Array
var events_scheduled: bool
var clock_counter: int = 0
#endregion STATES


#region SETUP
func setup_from_json_roots(random_tasks: Array, random_scams: Array) -> void:
	tasks_list = random_tasks[0] + random_tasks[1]
	scams_list = random_scams[0] + random_scams[1]
	events_scheduled = false
	define_events_list()
#endregion SETUP

#region FUNCTIONS
func _on_clock_tick() -> void:
	if (events_scheduled or GameData.current_day == 0 or GameData.current_day == 7):
		return

	clock_counter += 1
	if (clock_counter == 1):
		clock_counter = 0
		define_events_list()

func define_events_list() -> void:
	if (GameData.current_day == 0 or GameData.current_day == 7):
		return

	var randomized_tasks = tasks_list.duplicate(true)
	var randomized_scams = scams_list.duplicate(true)

	randomized_tasks.shuffle()
	randomized_scams.shuffle()

	var number_of_tasks_required = number_of_events[GameData.current_day].tasks
	var number_of_scams_required = number_of_events[GameData.current_day].scams

	if GameData.downloaded_apps.has(GameData.App.FAKESTORE):
		number_of_scams_required = ceili(number_of_scams_required * 1.4)
		number_of_tasks_required = ceili(number_of_tasks_required * 1.4)

	var chosen_tasks = []
	var tasks_sender_ids = {}
	for task in randomized_tasks:
		if len(chosen_tasks) >= number_of_tasks_required:
			break

		if not evaluate_requirements(task):
			continue

		var thread_id = task.get("thread_id")
		if tasks_sender_ids.has(thread_id):
			continue

		tasks_sender_ids.set(thread_id, true)
		chosen_tasks.append(task)
	
	var chosen_scams = []
	var scams_sender_ids = {}
	for scam in randomized_scams:
		if len(chosen_scams) >= number_of_scams_required:
			break

		if not evaluate_requirements(scam):
			continue

		var thread_id = scam.get("thread_id")
		if scams_sender_ids.has(thread_id):
			continue

		scams_sender_ids.set(thread_id, true)
		chosen_scams.append(scam)

	if (len(chosen_tasks) != number_of_tasks_required or len(chosen_scams) != number_of_scams_required):
		push_warning("It wasn't possible to pick random events, trying again in 10 seconds")
		return

	var events_list = chosen_tasks + chosen_scams
	schedule_events(events_list)

func evaluate_requirements(event) -> bool:
	var event_id = null

	if event.has("branch"):
		event_id = event.get("branch")
	elif event.has("email_id"):
		event_id = event.get("email_id")
		event["is_email"] = true
	assert(event_id != null)

	if (GameData.random_events_history.has(event_id)):
		return false

	var app_id = event.get("required_app", "")
	var app = GameData.apps_name.get(app_id, null)

	if (!GameData.downloaded_apps.has(app)):
		return false

	if (event.get("is_email", false) and not GameData.downloaded_apps.has(GameData.App.EMAIL)):
		return false

	return true

func schedule_events(events_list: Array) -> void:
	events_list.shuffle()

	var events_due_times = get_spaced_times(events_list.size())
	assert(events_due_times.size() == events_list.size())

	for i in range(events_list.size()):
		var event_id = null
		if events_list[i].get("is_email", false):
			event_id = events_list[i].get("email_id")
			schedule_email.emit({
				"thread_id": events_list[i].get("thread_id"),
				"email_id": event_id,
				"event_id": event_id,
				"due_at": events_due_times[i],
				"requires": [],
			})
		else:
			event_id = events_list[i].get("branch")
			schedule_message.emit({
					"thread_id": events_list[i].get("thread_id"),
					"branch": event_id,
					"event_id": event_id,
					"index": 0,
					"due_at": events_due_times[i],
					"requires": [],
				})
		GameData.random_events_history.append(event_id)
	
	events_scheduled = true

func get_spaced_times(number_of_times: int) -> Array:
	var times = []
	var attempts = 0
	var max_attempts = number_of_times * 200

	var start_of_range = GameData.starting_hours_minutes + random_tasks_delay[GameData.current_day]
	var end_of_range = GameData.max_hours_minutes - 30

	var min_dist = 30
	# Verifies if min distance at 30s is possible
	if (number_of_times * min_dist >= end_of_range - start_of_range):
		min_dist = floori(((end_of_range - start_of_range) / number_of_times) * 0.8)

	while times.size() < number_of_times and attempts < max_attempts:
		var num = randi_range(start_of_range, end_of_range)
		var is_valid = true

		for existing_num in times:
			if abs(num - existing_num) < min_dist:
				is_valid = false
				break

		if is_valid:
			times.append(num)

		attempts += 1

	if times.size() < number_of_times:
		push_warning("Não foi possível encontrar números espaçados o suficiente.")
		return []

	times.sort()
	return times
#endregion FUNCTION
