extends Control
## The company board: what the player checks a message, email or payment against
##
## Lists the sections of today's board (see NotesBoard), each opening what it says in the
## NOTESSECTION subscreen. Rebuilt each time the app opens.

signal subscreen_open_requested(subscreen: GameData.App, section: Dictionary)

const SECTION_ROW_SCENE := preload("res://scenes/apps/notes/notes_section_row.tscn")

@export var subtitle_label: Label
@export var sections_list: VBoxContainer
@export var scroll: ScrollContainer


## Rebuilds the board for today
func setup() -> void:
	for child in sections_list.get_children():
		sections_list.remove_child(child)
		child.queue_free()

	subtitle_label.text = "Confira aqui antes de denunciar · Dia %d" % GameData.current_day

	for section in NotesBoard.new().get_sections():
		var row := SECTION_ROW_SCENE.instantiate()
		sections_list.add_child(row)
		row.setup(section)
		row.open_requested.connect(_on_section_open_requested)

	scroll.scroll_vertical = 0


func _on_section_open_requested(section: Dictionary) -> void:
	subscreen_open_requested.emit(GameData.App.NOTESSECTION, section)
