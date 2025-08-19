extends Node

var game_timer : Timer
var hours_minutes : String
var daily_reputation_points : int = 0

var data = {
	"current_day": 0,
  	"reputation_points": 0,
  	"virus_info": {
	"has_virus": false,
	"viruses_quantity" : 0,
	"virus_time": 0
  	},
  	"OS_version": "0",
  	"passwords": {}
}

func load_game() -> void:
	var file_path = "res://data/save.json"
	
	var save_file = FileAccess.open(file_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var save_json = JSON.new()
		var parse_result = save_json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", save_json.get_error_message())
			return 
		
		var save_data = save_json.data 
		data = save_data

func save_game() -> void:
	var file_path = "res://data/save.json"
	
	var json_string = JSON.stringify(data)
	print(json_string)
	
	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(json_string)
		save_file.close()
	
