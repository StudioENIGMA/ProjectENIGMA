extends Node

#region SETUP
## Builds GameData.introductions from the JSON roots of data/introduction, one per file
func setup_from_json_roots(json_roots: Array) -> void:
	# Reloaded at the start of every day, so start over instead of piling up copies
	GameData.introductions.clear()

	for root in json_roots:
		_register_introduction(root)
#endregion SETUP

#region REGISTER INTRODUCTIONS
## Registers a single introduction given its JSON root
func _register_introduction(root: Variant) -> void:
	# Each introduction file is a Dictionary: { "day": 1, "description": ..., "rules": [...], "footer": ... }
	assert(typeof(root) == TYPE_DICTIONARY)
	assert(root.has("day"))

	var introduction := GameData.Introduction.new()
	introduction.day = int(root["day"])
	introduction.description = str(root.get("description", ""))
	# JSON arrays come untyped, assign() converts them into the typed Array[String]
	introduction.rules.assign(root.get("rules", []))
	introduction.footer = str(root.get("footer", ""))
	GameData.introductions.append(introduction)
#endregion REGISTER INTRODUCTIONS
