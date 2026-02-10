extends Control

@export var v_box_container: VBoxContainer

var company_card_scene = preload("res://scenes/apps/browser/reviews_site/company_card.tscn")
var companies_array: Array

func _ready() -> void:
	parse_company_data()

	for company_data in companies_array:
		create_company_card(company_data)

func create_company_card(company_data: Dictionary) -> void:
	var company_card = company_card_scene.instantiate()
	company_card.setup(company_data["score"], company_data["name"], company_data["summary"])

	v_box_container.add_child(company_card)
	var child_idx = v_box_container.get_child_count() - 2
	v_box_container.move_child(company_card, child_idx)

func parse_company_data():
	var file_path = "res://data/browser/reviewed_companies.json"
	var file = FileAccess.open(file_path, FileAccess.READ)

	if !file:
		return

	var json_string = file.get_as_text()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_ARRAY:
			companies_array = data
		else:
			print("JSON data is not an array.")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
