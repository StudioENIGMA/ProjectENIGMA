extends Control
## Row of the Notes board for one section, which opens what the section says

signal open_requested(section: Dictionary)

@export var open_button: Button
@export var title_label: Label
@export var summary_label: Label
## The "NOVO" pill of a section shown for the first time today
@export var new_tag: PanelContainer

var _section: Dictionary

func _ready() -> void:
	open_button.pressed.connect(func() -> void: open_requested.emit(_section))

## Names the section and what it is about
##
## section: The section, as NotesBoard.get_sections() gives it
func setup(section: Dictionary) -> void:
	_section = section
	title_label.text = section["title"]
	summary_label.text = section["summary"]
	new_tag.visible = int(section["day"]) == GameData.current_day
