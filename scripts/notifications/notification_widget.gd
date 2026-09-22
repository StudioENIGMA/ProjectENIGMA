extends PanelContainer

## Home-screen widget listing the newest notifications of the notification center
##
## Mirrors the center's list (the center stays the single owner of the entries) and shows the
## MAX_PILLS newest ones as pills. Tapping a pill opens its app, tapping anywhere else on the
## widget pulls the full notification center down.

## Emitted when the player taps a notification pill to jump into its app
signal app_open_requested(app: GameData.App)
## Emitted when the player taps the widget itself, to open the full notification center
signal center_open_requested

const NOTIFICATION_PILL = preload("res://scenes/notifications/notification_pill.tscn")
const MAX_PILLS: int = 3
const PRESSED_TINT = Color(0.85, 0.85, 0.85)

#region CHILDREN NODES REFERENCES
@export var pills_container: VBoxContainer
@export var count_label: Label
@export var count_badge: Control
@export var empty_state: Control
#endregion CHILDREN NODES REFERENCES

func _ready() -> void:
	show_entries([])

## Redraws the widget from the notification center's entries, newest first
func show_entries(entries: Array) -> void:
	for child in pills_container.get_children():
		pills_container.remove_child(child)
		child.queue_free()

	for entry in entries.slice(0, MAX_PILLS):
		var pill = NOTIFICATION_PILL.instantiate()
		pills_container.add_child(pill)
		pill.setup(entry)
		pill.pressed.connect(app_open_requested.emit.bind(entry.app))

	empty_state.visible = entries.is_empty()
	count_badge.visible = not entries.is_empty()
	count_label.text = str(entries.size())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Dim while held, like a pressed button
		modulate = PRESSED_TINT if event.pressed else Color.WHITE
		if not event.pressed:
			accept_event()
			center_open_requested.emit()
