extends Node

var game_timer : Timer
var hours_minutes : String
var daily_reputation_points : int = 0

func now() -> float:
	if is_instance_valid(game_timer):
		return game_timer.wait_time - game_timer.time_left
	else:
		return 0

var data = {
	"current_day": 1,
  	"reputation_points": 0,
   	"random_send_amplitude_max" : 480,
	"max_game_time" : 600,
  	"virus_info": {
		"has_virus": false,
		"viruses_quantity" : 0,
		"virus_time": 0
  	},
  	"OS_version": "0",
  	"passwords": {
		"Ajustes" : "",
		"Mensagens" : "",
		"Loja" : "",
		"Navegador" : "",
		"Email" : "",
		"Loja Alternativa" : "",
	},
	"downloaded_apps": ["mensagens", "settings"],
  	"has_store": true,
   	"has_fake_store": true,
	"has_browser": true,
	"has_mail": true,
	"has_settings": true
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
