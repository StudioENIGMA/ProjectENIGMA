extends Control
## One section of the company board, opened from its row in the Notes app

@export var title_label: Label
@export var subtitle_label: Label
@export var body: VBoxContainer
@export var scroll: ScrollContainer


## Fills the screen with what the section says today
##
## section: The section, as NotesBoard.get_sections() gives it
func setup(section: Dictionary) -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()

	title_label.text = section["title"]
	subtitle_label.text = section["summary"]
	NotesBoard.new().build_section(section["id"], body)

	scroll.scroll_vertical = 0
