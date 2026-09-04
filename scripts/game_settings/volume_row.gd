extends VBoxContainer

## One volume row of the game settings screen. Keeps the percentage readout and
## the muted styling in step with the slider and the mute toggle, and mirrors
## both onto the audio bus the row controls.

const MUTED_ALPHA: float = 0.4

@export var bus_name: StringName = &"Master"
@export var slider: HSlider
@export var value_label: Label
@export var mute_button: Button

var _bus_index: int = -1

func _ready() -> void:
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index >= 0:
		slider.set_value_no_signal(_db_to_volume(AudioServer.get_bus_volume_db(_bus_index)))
		mute_button.set_pressed_no_signal(AudioServer.is_bus_mute(_bus_index))

	slider.value_changed.connect(_on_slider_value_changed)
	mute_button.toggled.connect(_on_mute_button_toggled)

	_on_slider_value_changed(slider.value)
	_on_mute_button_toggled(mute_button.button_pressed)

func _on_slider_value_changed(value: float) -> void:
	value_label.text = "%d%%" % roundi(value)
	if _bus_index >= 0:
		AudioServer.set_bus_volume_db(_bus_index, _volume_to_db(value))

func _on_mute_button_toggled(toggled_on: bool) -> void:
	mute_button.text = "SILENCIADO" if toggled_on else "SILENCIAR"
	slider.modulate.a = MUTED_ALPHA if toggled_on else 1.0
	value_label.modulate.a = MUTED_ALPHA if toggled_on else 1.0
	if _bus_index >= 0:
		AudioServer.set_bus_mute(_bus_index, toggled_on)

## Mirrors sound_director.convert_float_to_db so both paths drive the buses the
## same way.
static func _volume_to_db(value: float) -> float:
	if value <= 0.1:
		return -100.0
	return 0.16 * value - 16.0

static func _db_to_volume(volume_db: float) -> float:
	return clampf((volume_db + 16.0) / 0.16, 0.0, 100.0)
