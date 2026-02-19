extends Control

signal subscreen_open_requested(subscreen_name:String)

const DEFAULT_PASSWORDS_BUTTON = preload("res://assets/icons/pass_manager_card.png")
const HOLVER_PASSWORDS_BUTTON = preload("res://assets/icons/pass_manager_card_hover.png")

const DEFAULT_UPDATE_OS_BUTTON = preload("res://assets/icons/update_os_card.png")
const HOLVER_UPDATE_OS_BUTTON = preload("res://assets/icons/update_os_card_hover.png")
const LOCKED_UPDATE_OS_BUTTON = preload("res://assets/icons/update_os_locked_card.png")

const DEFAULT_SCANNER_BUTTON = preload("res://assets/icons/bug_card.png")
const HOLVER_SCANNER_BUTTON = preload("res://assets/icons/bug_card_hover.png")
const LOCKED_SCANNER_BUTTON = preload("res://assets/icons/bug_unlocked_card.png")

@export var passwords_manager_gui: Control
@export var update_os_gui: Control
@export var virus_scanner_gui: Control

func _ready() -> void:
	var day = GameData.current_day

	passwords_manager_gui.setup(DEFAULT_PASSWORDS_BUTTON, HOLVER_PASSWORDS_BUTTON)
	update_os_gui.setup(DEFAULT_UPDATE_OS_BUTTON, HOLVER_UPDATE_OS_BUTTON)
	virus_scanner_gui.setup(DEFAULT_SCANNER_BUTTON, HOLVER_SCANNER_BUTTON)

	passwords_manager_gui.settings_gui_pressed.connect(
		_on_sub_app_pressed.bindv([GameData.App.PASSWORDMANAGER])
	)

	# Hide certain settings based on the current day
	if day < 2:
		update_os_gui.change_gui_lock_texture(LOCKED_UPDATE_OS_BUTTON)
		virus_scanner_gui.change_gui_lock_texture(LOCKED_SCANNER_BUTTON)

func _on_sub_app_pressed(app:GameData.App) -> void:
	emit_signal("subscreen_open_requested", app)
