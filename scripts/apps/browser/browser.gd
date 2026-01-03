extends Control

signal subscreen_open_requested(subscreen_name:GameData.App)

func _on_open_browser(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name)


