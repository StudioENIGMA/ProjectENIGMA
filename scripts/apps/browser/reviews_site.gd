extends Control

@export var v_box_container: VBoxContainer

var company_card_scene = preload("res://scenes/apps/browser/reviews_site/company_card.tscn")
var companies_array: Array

func setup(data_array: Array) -> void:
	for child in v_box_container.get_children():
		child.queue_free()

	companies_array = data_array
	for company_data in companies_array:
		create_company_card(company_data)

func create_company_card(company_data: Dictionary) -> void:
	var company_card = company_card_scene.instantiate()
	company_card.setup(company_data)

	v_box_container.add_child(company_card)
	var child_idx = v_box_container.get_child_count() - 2
	v_box_container.move_child(company_card, child_idx)
