extends Node


@export var intensity : int = 0
var last_intensity : int = 0

@export var animation_player : AnimationPlayer


@export_category("Audio Streams")
@export var KeysMelodyWeak        : AudioStreamPlayer
@export var KeysMelodyMid         : AudioStreamPlayer
@export var KeysMelodyIntense     : AudioStreamPlayer

@export var KeysAccompanimentWeak : AudioStreamPlayer
@export var KeysAccompanimentMid  : AudioStreamPlayer

@export var Bass                  : AudioStreamPlayer
@export var BassBridge            : AudioStreamPlayer

@export var Drums                 : AudioStreamPlayer


var bridge_timer : Timer
var bridge_cooldown_timer : Timer
var bridge_duration_secs : float
@export var is_in_bridge : bool = false
@export var bridge_cooldown_time : float


func _ready() -> void:
	last_intensity = intensity
	bridge_duration_secs = KeysMelodyWeak.stream.get_length() / 4.0

	bridge_timer = Timer.new()
	bridge_timer.autostart = false
	bridge_timer.one_shot = true
	bridge_timer.connect("timeout", end_bridge)
	bridge_timer.wait_time = bridge_duration_secs
	self.add_child(bridge_timer)

	bridge_cooldown_timer = Timer.new()
	bridge_cooldown_timer.autostart = false
	bridge_cooldown_timer.one_shot = true
	bridge_cooldown_timer.wait_time = bridge_cooldown_time
	self.add_child(bridge_cooldown_timer)

	# KeysMelodyWeak.volume_db = -100.0
	# KeysMelodyMid.volume_db = -100.0
	# KeysMelodyIntense.volume_db = -100.0
	# KeysAccompanimentWeak.volume_db = -100.0
	# KeysAccompanimentMid.volume_db = -100.0
	# Bass.volume_db = -100.0
	# BassBridge.volume_db = -100.0
	# Drums.volume_db = -100.0

	stem_change()

func _process(_delta: float) -> void:
	if intensity > 0 and last_intensity <= 0:
		stem_change()
		last_intensity = intensity

	if intensity >= 10 and last_intensity < 10 and last_intensity >= 7 and bridge_cooldown_timer.is_stopped():
		bridge_cooldown_timer.start()
		is_in_bridge = true
	else:
		is_in_bridge = false


func force_bridge_next_stem():
	bridge_cooldown_timer.start()
	is_in_bridge = true


func end_bridge():
	is_in_bridge = false
	animation_player.stop()
	stem_change()


func stem_change() -> void:
	animation_player.stop()

	if is_in_bridge:
		last_intensity = intensity
		bridge_timer.start()
		animation_player.get_animation("Music").track_set_enabled(0, false) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, false) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, false) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, false) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, false) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, false) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, true) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, false) # Drums

	elif intensity <= 0:
		last_intensity = intensity

		animation_player.get_animation("Music").track_set_enabled(0, false) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, false) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, false) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, false) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, false) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, false) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, false) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, false) # Drums

	elif intensity <= 1:
		last_intensity = intensity
		animation_player.get_animation("Music").track_set_enabled(0, false) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, false) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, false) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, true) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, false) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, false) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, false) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, false) # Drums

	elif intensity <= 3:
		last_intensity = intensity
		animation_player.get_animation("Music").track_set_enabled(0, true) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, false) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, false) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, true) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, false) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, false) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, false) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, false) # Drums

	elif intensity <= 5:
		last_intensity = intensity
		animation_player.get_animation("Music").track_set_enabled(0, false) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, true) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, false) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, true) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, false) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, true) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, false) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, true) # Drums

	elif intensity <= 7:
		last_intensity = intensity
		animation_player.get_animation("Music").track_set_enabled(0, false) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, false) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, true) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, true) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, false) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, true) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, false) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, true) # Drums

	elif intensity <= 10:
		animation_player.get_animation("Music").track_set_enabled(0, false) # Melody Weak
		animation_player.get_animation("Music").track_set_enabled(1, false) # Melody Mid
		animation_player.get_animation("Music").track_set_enabled(2, true) # Melody Intense
		animation_player.get_animation("Music").track_set_enabled(3, false) # Acomp Weak
		animation_player.get_animation("Music").track_set_enabled(4, true) # Acomp Mid
		animation_player.get_animation("Music").track_set_enabled(5, true) # Bass
		animation_player.get_animation("Music").track_set_enabled(6, false) # Bass Bridge
		animation_player.get_animation("Music").track_set_enabled(7, true) # Drums

	if intensity > 0: animation_player.play("Music")


func _on_increase_music_intensity():
	intensity = min(intensity + 1, 10.0)


func _on_decrease_music_intensity():
	intensity = max(intensity - 1, 0.0)


# 	if is_in_bridge:
# 		KeysMelodyWeak.volume_db = -100.0
# 		KeysMelodyMid.volume_db = -100.0
# 		KeysMelodyIntense.volume_db = -100.0
# 		KeysAccompanimentWeak.volume_db = -100.0
# 		KeysAccompanimentMid.volume_db = -100.0
# 		Bass.volume_db = -100.0
# 		BassBridge.volume_db = 0.0
# 		Drums.volume_db = -100.0
#
# 	elif intensity <= 0:
# 		KeysMelodyWeak.volume_db = -100.0
# 		KeysMelodyMid.volume_db = -100.0
# 		KeysMelodyIntense.volume_db = -100.0
# 		KeysAccompanimentWeak.volume_db = -100.0
# 		KeysAccompanimentMid.volume_db = -100.0
# 		Bass.volume_db = -100.0
# 		BassBridge.volume_db = -100.0
# 		Drums.volume_db = -100.0
#
# 	elif intensity <= 1:
# 		KeysMelodyWeak.volume_db = -100.0
# 		KeysMelodyMid.volume_db = -100.0
# 		KeysMelodyIntense.volume_db = -100.0
# 		KeysAccompanimentWeak.volume_db = 0.0
# 		KeysAccompanimentMid.volume_db = -100.0
# 		Bass.volume_db = -100.0
# 		BassBridge.volume_db = -100.0
# 		Drums.volume_db = -100.0
#
# 	elif intensity <= 3:
# 		KeysMelodyWeak.volume_db = 0.0
# 		KeysMelodyMid.volume_db = -100.0
# 		KeysMelodyIntense.volume_db = -100.0
# 		KeysAccompanimentWeak.volume_db = 0.0
# 		KeysAccompanimentMid.volume_db = -100.0
# 		Bass.volume_db = -100.0
# 		BassBridge.volume_db = -100.0
# 		Drums.volume_db = -100.0
#
# 	elif intensity <= 5:
# 		KeysMelodyWeak.volume_db = -100.0
# 		KeysMelodyMid.volume_db = 0.0
# 		KeysMelodyIntense.volume_db = -100.0
# 		KeysAccompanimentWeak.volume_db = 0.0
# 		KeysAccompanimentMid.volume_db = -100.0
# 		Bass.volume_db = -100.0
# 		BassBridge.volume_db = -100.0
# 		Drums.volume_db = 0.0
#
# 	elif intensity <= 7:
# 		KeysMelodyWeak.volume_db = -100.0
# 		KeysMelodyMid.volume_db = -100.0
# 		KeysMelodyIntense.volume_db = 0.0
# 		KeysAccompanimentWeak.volume_db = 0.0
# 		KeysAccompanimentMid.volume_db = -100.0
# 		Bass.volume_db = 0.0
# 		BassBridge.volume_db = -100.0
# 		Drums.volume_db = 0.0
#
# 	elif intensity <= 10:
# 		KeysMelodyWeak.volume_db = -100.0
# 		KeysMelodyMid.volume_db = -100.0
# 		KeysMelodyIntense.volume_db = 0.0
# 		KeysAccompanimentWeak.volume_db = -100.0
# 		KeysAccompanimentMid.volume_db = 0.0
# 		Bass.volume_db = 0.0
# 		BassBridge.volume_db = -100.0
# 		Drums.volume_db = 0.0
