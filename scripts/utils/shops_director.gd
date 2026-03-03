extends Node

#region DEFINITIONS
var enum_to_string = {
	GameData.App.BROWSERAMAZONIASHOP : "amazonia",
	GameData.App.BROWSEREMILIASHOP: "emilia_bolos"
}
#endregion DEFINITIONS

#region STATE
var shops_dictionary: Dictionary
#endregion STATE

#region SETUP
## Sets up emails from JSON roots (called by StoryDirector)
func setup_from_json_file(json_dict: Dictionary) -> void:
	shops_dictionary = json_dict
#endregion SETUP

func get_shop_items_array(app: GameData.App) -> Array:
	var shop_items_array : Array
	var key : String = enum_to_string.get(app)
	if shops_dictionary.has(key):
		shop_items_array = shops_dictionary.get(key).duplicate(true)
	return shop_items_array
