extends TextureButton

signal open_pause_menu(app_id: GameData.App)

func _on_pressed() -> void:
	open_pause_menu.emit(GameData.App.PAUSEMENU)
