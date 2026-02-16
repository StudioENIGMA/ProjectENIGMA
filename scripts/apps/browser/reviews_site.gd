extends Control

signal request_companies_array()

@export var v_box_container: VBoxContainer

var company_card_scene = preload("res://scenes/apps/browser/reviews_site/company_card.tscn")
var companies_array: Array

func _ready() -> void:
	request_companies_array.emit.call_deferred()

func _on_companies_array_received(json_array: Array) -> void:
	companies_array = json_array
	for company_data in companies_array:
		create_company_card(company_data)

func create_company_card(company_data: Dictionary) -> void:
	var company_card = company_card_scene.instantiate()
	company_card.setup(company_data)

	v_box_container.add_child(company_card)
	var child_idx = v_box_container.get_child_count() - 2
	v_box_container.move_child(company_card, child_idx)
