extends Node

#region SIGNALS
signal schedule_message(story_entry: Dictionary)
#endregion SIGNALS

#region CONSTANTS
const random_tasks_delay = [0, 30, 30, 30, 30, 30, 30]

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

#region SETUP
func setup_from_json_array(random_tasks: Array, random_scams: Array) -> void:
	var tasks_list = random_tasks
	var scams_list = random_scams
	define_events_list(tasks_list, scams_list)
#endregion SETUP

#region FUNCTIONS
func define_events_list(tasks_list: Array, scams_list: Array) -> void:
	if(GameData.current_day == 0):
		return

	const MAX_ATTEMPTS = 100
	var attempts = 0

	var random_tasks = get_random_list(tasks_list.duplicate(true), number_of_events[GameData.current_day].tasks)
	var random_scams = get_random_list(scams_list.duplicate(true), number_of_events[GameData.current_day].scams)

	var is_task_valid = evaluate_requirements(random_tasks)
	var is_scams_valid = evaluate_requirements(random_scams)

	while((!is_task_valid or !is_scams_valid) and attempts <= MAX_ATTEMPTS):
		if(!is_task_valid):
			random_tasks = get_random_list(tasks_list.duplicate(true), number_of_events[GameData.current_day].tasks)
			is_task_valid = evaluate_requirements(random_tasks)
		if(!is_scams_valid):
			random_scams = get_random_list(scams_list.duplicate(true), number_of_events[GameData.current_day].scams)
			is_scams_valid = evaluate_requirements(random_scams)
		attempts += 1

	if(!is_task_valid or !is_scams_valid):
		push_warning("It was impossible to pick random events for the day: %d" % GameData.current_day)
		return

	var events_list = random_tasks + random_scams
	schedule_events(events_list)

func get_random_list(events_list, number_of_elements) -> Array:
	var elements_factor = 1.4 if GameData.downloaded_apps.has(GameData.App.FAKESTORE) else 1.0
	events_list.shuffle()
	return events_list.slice(0, ceili(number_of_elements * elements_factor))

func evaluate_requirements(events_list) -> bool:
	var senders_ids = {}

	for event in events_list:
		var event_branch = event.get("branch")
		if(GameData.random_events_history.has(event_branch)):
			return false

		var app_id = event.get("required_app", "")
		var app = GameData.apps_name.get(app_id, null)
		if(!GameData.downloaded_apps.has(app)):
			return false
		
		var thread_id = event.get("thread_id")
		if senders_ids.has(thread_id):
			return false
		senders_ids[thread_id] = true
	return true

func schedule_events(events_list: Array) -> void:
	events_list.shuffle()

	var events_due_times = get_spaced_times(events_list.size())
	assert(events_due_times.size() == events_list.size())

	for i in range(events_list.size()):
		GameData.random_events_history.append(events_list[i].get("branch"))
		schedule_message.emit({
				"thread_id": events_list[i].get("thread_id"),
				"branch": events_list[i].get("branch"),
				"index": 0,
				"due_at": events_due_times[i],
				"requires": [],
			})

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
		var num = randf_range(start_of_range, end_of_range)
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