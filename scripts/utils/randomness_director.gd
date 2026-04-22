extends Node

#region SIGNALS
signal schedule_message(story_entry: Dictionary)
#endregion SIGNALS

#region CONSTANTS
const number_of_events = [
	{
		"scams": 0,
		"hacks": 0	
	},
	{
		"scams": 2,
		"hacks": 2	
	},
	{
		"scams": 3,
		"hacks": 4	
	},
	{
		"scams": 7,
		"hacks": 5	
	},
	{
		"scams": 10,
		"hacks": 6	
	},
	{
		"scams": 11,
		"hacks": 8	
	},
	{
		"scams": 12,
		"hacks": 9	
	},
]
#endregion CONSTANTS

#region STATE
var tasks_list: Array
var scams_list: Array
#endregion STATE

#region SETUP
func setup_from_json_array(random_tasks: Array, random_scams: Array) -> void:
	tasks_list = random_tasks
	scams_list = random_scams
#endregion SETUP

#region FUNCTIONS
func define_events_list() -> void:
	var random_tasks
	var random_scams

	

#endregion FUNCTION
