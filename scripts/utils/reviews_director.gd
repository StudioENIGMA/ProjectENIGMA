extends Node

signal send_companies_array(companies_array: Array)

#region STATE
var companies_array: Array
#endregion STATE

#region SETUP
## Sets up emails from JSON roots (called by StoryDirector)
func setup_from_json_array(json_array: Array) -> void:
	companies_array = json_array
#endregion SETUP

func _on_companies_array_requested() -> void:
	emit_signal("send_companies_array", companies_array)
