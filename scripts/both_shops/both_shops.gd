extends Control
class_name  both_shops

var button : Button
var matches = []


@onready var apps = $Panel/VBoxContainer.get_children()

func _ready() -> void:
	button = get_node("%Exit_shop")

func _on_search_bar_text_changed(new_text:String) -> void:
	new_text = new_text.to_lower()
	
	if new_text == "":
		for i in apps:
			i.show()
		return
	matches.clear()	
	
	for i in apps:
		var scene_text = i.get_node("Label_Margin_Container/Label").text
		if new_text in scene_text.to_lower():
			matches.append(i)
	
	for i in apps:
		if i in matches:
			i.show()
		else:
			i.hide()


func _on_exit_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
