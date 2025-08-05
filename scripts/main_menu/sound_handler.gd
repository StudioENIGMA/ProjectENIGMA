extends Node

@export var sfx_player   : AudioStreamPlayer2D
@export var music_player : AudioStreamPlayer2D

@export var startup_sound : AudioStream
@export var main_theme    : AudioStream

func _ready() -> void:
	music_player.stream = startup_sound
	music_player.play()

func _process(_delta: float) -> void:
	if not music_player.playing:
		if music_player.stream != main_theme:
			music_player.stream = main_theme
			music_player.play()
