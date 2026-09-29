class_name DiscrepancyInspector
extends RefCounted
## Keeps the discrepancy targets of one screen in step: armed together, at most one selected
##
## A screen that can be inspected (messages chat, email thread) holds one, registers every
## target it renders and forwards its picked signal upward.

## Emitted when the player picks one of the targets
signal picked(section: Dictionary)

var is_armed := false

var _targets: Array[DiscrepancyTarget] = []


## Starts tracking a target, already armed if the player is inspecting
##
## target: The overlay covering the section, with its section dictionary already filled
func add(target: DiscrepancyTarget) -> void:
	target.armed = is_armed
	# A target that outlives the screen's content (like a header) is added again on every setup
	if not target.picked.is_connected(_on_target_picked):
		target.picked.connect(_on_target_picked)
	if not _targets.has(target):
		_targets.append(target)


## Forgets every target, for when the screen frees what it rendered
func forget_all() -> void:
	_targets.clear()


## Arms or disarms every target, dropping the selection when disarming
func set_armed(armed: bool) -> void:
	is_armed = armed
	for target in _targets:
		if is_instance_valid(target):
			target.armed = armed


## Targets still alive, for the screen to hand over when they are lit through the dim
func get_targets() -> Array[DiscrepancyTarget]:
	var alive: Array[DiscrepancyTarget] = []
	for target in _targets:
		if is_instance_valid(target):
			alive.append(target)
	return alive


## Unmarks the selected target, leaving every target armed
func clear_selection() -> void:
	for target in _targets:
		if is_instance_valid(target):
			target.selected = false


func _on_target_picked(target: DiscrepancyTarget) -> void:
	clear_selection()
	target.selected = true
	picked.emit(target.section)
