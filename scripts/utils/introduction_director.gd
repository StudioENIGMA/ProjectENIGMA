extends Node

#region STATE
var introductions_array: Array
#endregion STATE

#region SETUP
func setup_from_json_file(json_array: Array):
	introductions_array = json_array
#endregion SETU

func set_introductions_content() -> void:
	for item in introductions_array:
		var introduction = GameData.Introduction.new()
		introduction.description = item.description
		introduction.rules = item.rules
		introduction.footer = item.footer
		GameData.introductions.append(introduction)

	print(GameData.introductions)
