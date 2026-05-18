extends Control

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

@export var list_container: VBoxContainer
@export var info_title: Label
@export var info_meta: Label
@export var info_description: RichTextLabel
@export var empty_label: Label
@export var save_button: Button
@export var back_button: Button
@export var restart_hint: Label

var _checkbox_by_id: Dictionary = {}
var _initial_enabled: Dictionary = {}
var _selected_id: String = ""


func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	restart_hint.visible = false

	for id in ModLoader.enabled_mod_ids:
		_initial_enabled[id] = true

	_populate_list()


func _populate_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var mods: Array = ModLoader.available_mods
	if mods.is_empty():
		empty_label.visible = true
		_clear_info()
		return

	empty_label.visible = false

	for desc in mods:
		var row := _build_mod_row(desc)
		list_container.add_child(row)

	# Auto-select first mod for the info panel
	_show_info(mods[0])


func _build_mod_row(desc) -> Control:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.custom_minimum_size = Vector2(0, 56)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	var info_btn := Button.new()
	info_btn.flat = true
	info_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_btn.clip_text = true
	var meta_suffix := " • built-in" if desc.is_builtin else ""
	info_btn.text = "%s\n%s • v%s%s" % [desc.display_name, _format_authors(desc), desc.version, meta_suffix]
	info_btn.pressed.connect(_on_row_pressed.bind(desc))
	hbox.add_child(info_btn)

	var toggle := CheckButton.new()
	toggle.button_pressed = ModLoader.is_enabled(desc.id)
	toggle.custom_minimum_size = Vector2(64, 40)
	toggle.toggled.connect(_on_mod_toggled.bind(desc.id))
	_checkbox_by_id[desc.id] = toggle
	hbox.add_child(toggle)

	return row


func _format_authors(desc) -> String:
	if desc.authors.is_empty():
		return "(autor desconhecido)"
	var parts: Array[String] = []
	for a in desc.authors:
		parts.append(str(a))
	return ", ".join(parts)


func _on_row_pressed(desc) -> void:
	_show_info(desc)


func _show_info(desc) -> void:
	_selected_id = desc.id
	info_title.text = desc.display_name
	info_meta.text = "id: %s • v%s • por %s" % [desc.id, desc.version, _format_authors(desc)]
	info_description.text = desc.description if desc.description != "" else "(sem descrição)"


func _clear_info() -> void:
	_selected_id = ""
	info_title.text = ""
	info_meta.text = ""
	info_description.text = ""


func _on_mod_toggled(_pressed_state: bool, _mod_id: String) -> void:
	restart_hint.visible = _has_changes()


func _has_changes() -> bool:
	var current := _current_selection_set()
	if current.size() != _initial_enabled.size():
		return true
	for id in current:
		if not _initial_enabled.has(id):
			return true
	return false


func _current_selection_set() -> Dictionary:
	var set := {}
	for id in _checkbox_by_id:
		if _checkbox_by_id[id].button_pressed:
			set[id] = true
	return set


func _on_save_pressed() -> void:
	var ids := PackedStringArray()
	for id in _checkbox_by_id:
		if _checkbox_by_id[id].button_pressed:
			ids.append(id)
	ModLoader.save_enabled_list(ids)
	_initial_enabled.clear()
	for id in ids:
		_initial_enabled[id] = true
	restart_hint.text = "Salvo. Reinicie para aplicar."
	restart_hint.visible = true


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
