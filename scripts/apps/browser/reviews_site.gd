extends Control

@export var v_box_container: VBoxContainer
@export var scroll_container: ScrollContainer

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

## A company counts as seen ("review:<name>", see GameData.seen_info) once the score on its card
## shows whole on screen
func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return

	var screen_rect := scroll_container.get_global_rect()
	for card in v_box_container.get_children():
		if card.is_queued_for_deletion() or not "company_name" in card:
			continue
		if screen_rect.encloses(card.score_label.get_global_rect()):
			GameData.mark_seen("review:%s" % card.company_name)
