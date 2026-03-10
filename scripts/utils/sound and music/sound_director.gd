extends Node

@export var sound_signaler : SoundSignaler

@export var main_theme : AudioStream

@export_group("SFX")
@export var sfx_player    : AudioStreamPlayer2D
@export var startup_sound : AudioStream

@export_group("Music")
@export var current_music         : Music
@export var musics                : Array[Music]
@export var should_generate_music : bool = false
var stop_music_next_frame         : bool = false

const bar_size : int = 436
var current_stem = -1
var current_stem_per_instrument : Array[int]
var max_stem_amount : int = 10000
var tick : int = 0

@export_subgroup("Instruments")
@export var instruments  : Array[Instrument]
var half_bar_instruments : Array[Instrument]
var full_bar_instruments : Array[Instrument]

var instrument_changed_this_frame : Array[bool] = [true, true, true]

@export_subgroup("Sound Players")
@export var synth_player     : AudioStreamPlayer2D
@export var modulated_player : AudioStreamPlayer2D
@export var chord_player     : AudioStreamPlayer2D
@export var bass_player      : AudioStreamPlayer2D

@export_subgroup("Double Tempo")
var double_tempo               : bool = false
var next_double_tempo          : bool = false
var should_change_double_tempo : bool = false

@export_subgroup("Melody Modulation")
var angle                   : float = PI / 2.0
var modulate_melody_enabled : bool = false
var is_cutoff_in_transition : bool = false
var is_cutoff_decreasing    : bool = false

var cutoff_hz : float = 4400.0
@export var cutoff_hz_midpoint  : float = 4400.0
@export var cutoff_hz_amplitude : float = 3600.0
@export var modulation_speed    : float = 1.0


func _ready() -> void:
	# melody_player.stream = startup_sound
	# melody_player.play()
	sound_signaler.connect("set_melody_modulation", set_melody_modulation)
	sound_signaler.connect("set_instrument", set_instrument)
	sound_signaler.connect("set_double_tempo", set_double_tempo)
	sound_signaler.connect("set_music", set_music)
	sound_signaler.connect("set_should_generate_music", set_should_generate_music)
	sound_signaler.connect("start_music_early", on_start_music_early)

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), convert_float_to_db(50.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), convert_float_to_db(50.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), convert_float_to_db(100.0))

	reset_melody_modulation()
	calculate_max_stem_amount()
	check_for_music()

func _process(delta: float) -> void:
	## ======================================================
	##                     DEBUG CODE
	## ======================================================
	## The code bellow is only for debugging and testing musics
	if Input.is_action_just_released("cycle_instruments"):
		instrument_changed_this_frame = [false, false, false]
	if Input.is_action_pressed("cycle_instruments"): # SPACE BAR + 1/2/3/4
		if Input.is_key_pressed(KEY_1) and not instrument_changed_this_frame[0]:
			instrument_changed_this_frame[0] = true
			set_instrument(0, not instruments[0].state)
			print(instruments[0].state)

		elif Input.is_key_pressed(KEY_2) and not instrument_changed_this_frame[1]:
			instrument_changed_this_frame[1] = true
			set_instrument(1, not instruments[1].state)
			print(instruments[1].state)

		elif Input.is_key_pressed(KEY_3) and not instrument_changed_this_frame[2]:
			instrument_changed_this_frame[2] = true
			set_instrument(2, not instruments[2].state)
			print(instruments[2].state)

	if Input.is_action_just_pressed("toggle_melody_modulation"): # M
		if not is_cutoff_in_transition and modulate_melody_enabled == false:
			is_cutoff_in_transition = true
		set_melody_modulation(not modulate_melody_enabled)
		print(modulate_melody_enabled)

	if Input.is_action_just_pressed("reset"): # R
		reset_melody_modulation()
		print(modulate_melody_enabled)

	if Input.is_action_just_pressed("toggle_double_tempo"): # D
		should_change_double_tempo = true
		next_double_tempo = not next_double_tempo

	if Input.is_action_just_pressed("lock_modulation"): # L
		lock_modulation()

	## ======================================================
	##                     DEBUG CODE
	## ======================================================

	modulate_melody(modulate_melody_enabled, delta)


func _physics_process(_delta: float) -> void:
	play_music()

	tick += 1
	tick %= bar_size


func play_music():
	if tick == 0:
		change_double_tempo_value()

	if tick == 0 or (double_tempo and tick == int((bar_size - 1) / 2.0)):
		# print("change")
		current_stem += 1
		current_stem %= max_stem_amount
		organize_instruments()

		# print("play")
		update_half_bar_stems()
		# if not double_tempo:
		update_full_bar_stems()
	elif tick == int(bar_size / 2.0):
		update_half_bar_stems()

	if stop_music_next_frame:
		current_music = null
		check_for_music()
		calculate_max_stem_amount()
		stop_music_next_frame = false

	if not should_generate_music and current_stem == max_stem_amount - 1:
		stop_music_next_frame = true

func check_for_music():
	if current_music != null:
		set_should_generate_music(false)
		return

	current_stem = 0
	if not musics.is_empty():
		current_music = musics.pop_front()
		set_double_tempo(current_music.double_tempo)
		set_melody_modulation(current_music.modulated_melody)
		set_should_generate_music(false)
	else:
		set_double_tempo(false)
		set_melody_modulation(false)
		set_should_generate_music(true)

func on_start_music_early():
	stop_music_next_frame = true

func set_music(music : Music):
	current_music = music

func set_should_generate_music(value : bool):
	should_generate_music = value


func calculate_max_stem_amount():
	if current_music != null:
		max_stem_amount = current_music.stem_sequence.get(current_music.stem_sequence.keys()[0]).size()

	var synth_polyphony : int = 0
	var modulated_polyphony : int = 0
	var bass_polyphony : int = 0

	for instrument in instruments:
		if current_music == null and instrument.stems.size() < max_stem_amount:
			max_stem_amount = instrument.stems.size()

		match instrument.type:
			Instrument.TYPE.SYNTH:
				synth_polyphony += 1
			Instrument.TYPE.MODULATED_SYNTH:
				modulated_polyphony += 1
			Instrument.TYPE.BASS:
				bass_polyphony += 1

	synth_player.max_polyphony = synth_polyphony
	modulated_player.max_polyphony = modulated_polyphony
	bass_player.max_polyphony = bass_polyphony


func organize_instruments():
	half_bar_instruments.clear()
	full_bar_instruments.clear()
	if should_generate_music:
		for instrument in instruments:
			if instrument.stems[current_stem].get_length() < bar_size / 100.0:
				half_bar_instruments.append(instrument)
			else:
				full_bar_instruments.append(instrument)
	else:
		for instrument in current_music.stem_sequence.keys():
			if instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]].get_length() < bar_size / 100.0:
				half_bar_instruments.append(instrument)
			else:
				full_bar_instruments.append(instrument)


func update_full_bar_stems():
	if should_generate_music:
		for instrument in full_bar_instruments:
			if instrument.state == true:
				match instrument.type:
					Instrument.TYPE.SYNTH:
						synth_player.stream = instrument.stems[current_stem]
						synth_player.play()
					Instrument.TYPE.MODULATED_SYNTH:
						modulated_player.stream = instrument.stems[current_stem]
						modulated_player.play()
					Instrument.TYPE.CHORD_SYNTH:
						chord_player.stream = instrument.stems[current_stem]
						chord_player.play()
					Instrument.TYPE.BASS:
						bass_player.stream = instrument.stems[current_stem]
						bass_player.play()
	else:
		for instrument in full_bar_instruments:
			if instrument.state == true:
				match instrument.type:
					Instrument.TYPE.SYNTH:
						synth_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						synth_player.play()
					Instrument.TYPE.MODULATED_SYNTH:
						modulated_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						modulated_player.play()
					Instrument.TYPE.CHORD_SYNTH:
						chord_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						chord_player.play()
					Instrument.TYPE.BASS:
						bass_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						bass_player.play()

func update_half_bar_stems():
	if should_generate_music:
		for instrument in half_bar_instruments:
			if instrument.state == true:
				match instrument.type:
					Instrument.TYPE.SYNTH:
						synth_player.stream = instrument.stems[current_stem]
						synth_player.play()
					Instrument.TYPE.MODULATED_SYNTH:
						modulated_player.stream = instrument.stems[current_stem]
						modulated_player.play()
					Instrument.TYPE.BASS:
						bass_player.stream = instrument.stems[current_stem]
						bass_player.play()
	else:
		for instrument in half_bar_instruments:
			if instrument.state == true:
				match instrument.type:
					Instrument.TYPE.SYNTH:
						synth_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						synth_player.play()
					Instrument.TYPE.MODULATED_SYNTH:
						modulated_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						modulated_player.play()
					Instrument.TYPE.CHORD_SYNTH:
						chord_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						chord_player.play()
					Instrument.TYPE.BASS:
						bass_player.stream = instrument.stems[current_music.stem_sequence.get(instrument)[current_stem]]
						bass_player.play()


func set_double_tempo(value : bool):
	next_double_tempo = value
	should_change_double_tempo = true

func change_double_tempo_value():
	if should_change_double_tempo:
		should_change_double_tempo = false
		double_tempo = next_double_tempo
		print(double_tempo)


func set_instrument(instrument : int, value : bool):
	instruments[instrument].state = value


func set_melody_modulation(value : bool):
	modulate_melody_enabled = value

func set_melody_modulation_value(value : float):
	AudioServer.get_bus_effect(AudioServer.get_bus_index("Modulated"), 0).set("cutoff_hz", value)

func lock_modulation():
	modulate_melody_enabled = false
	is_cutoff_in_transition = false

func reset_melody_modulation():
	modulate_melody_enabled = false
	is_cutoff_in_transition = false
	cutoff_hz = cutoff_hz_midpoint + cutoff_hz_amplitude
	angle = PI / 2.0
	AudioServer.get_bus_effect(AudioServer.get_bus_index("Modulated"), 0).set("cutoff_hz", cutoff_hz)

func modulate_melody(enabled : bool, time : float):
	var holder = cutoff_hz

	if enabled:
		angle += time
		cutoff_hz = cutoff_hz_midpoint + (sin(angle * modulation_speed) * cutoff_hz_amplitude)
		if holder > cutoff_hz:
			is_cutoff_decreasing = true
		else:
			is_cutoff_decreasing = false
		AudioServer.get_bus_effect(AudioServer.get_bus_index("Modulated"), 0).set("cutoff_hz", cutoff_hz)

	elif is_cutoff_in_transition:
		if AudioServer.get_bus_effect(AudioServer.get_bus_index("Modulated"), 0).get("cutoff_hz") >= cutoff_hz_midpoint + cutoff_hz_amplitude - 10.0:
			is_cutoff_in_transition = false

		if is_cutoff_decreasing:
			angle -= time
		else:
			angle += time

		cutoff_hz = cutoff_hz_midpoint + (sin(5.0 * angle * modulation_speed) * cutoff_hz_amplitude)
		AudioServer.get_bus_effect(AudioServer.get_bus_index("Modulated"), 0).set("cutoff_hz", cutoff_hz)



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
	var ret:float
	if value <= 0.1:
		ret = -100.0
	else:
		ret = 0.16 * value - 16.0
	return ret


## ======================================================
##                     DEBUG CODE
## ======================================================
## The code bellow is only for debugging and testing musics

func toggle_double_tempo():
	if should_change_double_tempo:
		should_change_double_tempo = false
		next_double_tempo = not next_double_tempo
		print(double_tempo)

func toggle_instrument(instrument : int):
	instruments[instrument].state = not instruments[instrument].state

func toggle_melody_modulation():
	modulate_melody_enabled = !modulate_melody_enabled
