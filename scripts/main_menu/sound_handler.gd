extends Node

@export var sfx_player   : AudioStreamPlayer2D
@export var music_player : AudioStreamPlayer2D

@export var startup_sound : AudioStream
@export var main_theme    : AudioStream

func _ready() -> void:
	music_player.stream = startup_sound
	music_player.play()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), convert_float_to_db(50.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), convert_float_to_db(50.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), convert_float_to_db(100.0))

func _process(_delta: float) -> void:
	if not music_player.playing:
		if music_player.stream != main_theme:
			music_player.stream = main_theme
			music_player.play()


func _on_mute_sfx_check_box_toggled(toggled_on:bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), toggled_on)

func _on_mute_music_check_box_toggled(toggled_on:bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), toggled_on)

func _on_mute_master_check_box_toggled(toggled_on:bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)


func _on_sfx_volume_h_slider_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), convert_float_to_db(value))

func _on_music_volume_h_slider_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), convert_float_to_db(value))

func _on_master_volume_h_slider_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), convert_float_to_db(value))

func convert_float_to_db(value:float) -> float:
	var ret : float
	if value <= 0.1:
		ret = -100.0
	else:
		ret = 0.16 * value - 16.0
	return ret
