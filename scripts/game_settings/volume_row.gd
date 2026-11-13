extends VBoxContainer

## One volume row of the game settings screen. Keeps the percentage readout and
## the muted styling in step with the slider and the mute toggle, and mirrors
## both onto the audio bus the row controls. What the player leaves is kept for
## the next games, see GameData.save_audio_setting().

const MUTED_ALPHA: float = 0.4

@export var bus_name: StringName = &"Master"
@export var slider: HSlider
@export var value_label: Label
@export var mute_button: Button

var _bus_index: int = -1

func _ready() -> void:
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index >= 0:
		slider.set_value_no_signal(GameData.db_to_volume(AudioServer.get_bus_volume_db(_bus_index)))
		mute_button.set_pressed_no_signal(AudioServer.is_bus_mute(_bus_index))

	slider.value_changed.connect(_on_slider_value_changed)
	mute_button.toggled.connect(_on_mute_button_toggled)

	_on_slider_value_changed(slider.value)
	_on_mute_button_toggled(mute_button.button_pressed)

## Saved once the screen closes, not on every step of a drag
func _exit_tree() -> void:
	if _bus_index >= 0:
		GameData.save_audio_setting(bus_name, slider.value, mute_button.button_pressed)

func _on_slider_value_changed(value: float) -> void:
	value_label.text = "%d%%" % roundi(value)
	if _bus_index >= 0:
		AudioServer.set_bus_volume_db(_bus_index, GameData.volume_to_db(value))

func _on_mute_button_toggled(toggled_on: bool) -> void:
	mute_button.text = "SILENCIADO" if toggled_on else "SILENCIAR"
	slider.modulate.a = MUTED_ALPHA if toggled_on else 1.0
	value_label.modulate.a = MUTED_ALPHA if toggled_on else 1.0
	if _bus_index >= 0:
		AudioServer.set_bus_mute(_bus_index, toggled_on)
