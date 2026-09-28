extends Control

## Emitted when the player, inspecting, points at a section of the thread as a scam discrepancy
##
## section: "source", "section" ("subject", "sender", "content" or "attachment"),
## "email_id" and "excerpt"
signal discrepancy_picked(section: Dictionary)

const EMAIL_MESSAGE_INSTANCE_SCENE = preload("res://scenes/apps/email/email_message_instance.tscn")

#region CHILDREN NODES REFERENCES
@export var subject_label: Label
@export var thread_size_label: Label
@export var email_messages_container: VBoxContainer
@export var scroll_container: ScrollContainer
## Lets the subject of the thread be pointed at as a scam discrepancy
@export var subject_target: DiscrepancyTarget
#endregion CHILDREN NODES REFERENCES

## Keeps the sections of the thread that can be pointed at as a discrepancy in step
var _inspector := DiscrepancyInspector.new()

func _ready() -> void:
	_inspector.picked.connect(discrepancy_picked.emit) # Propagate signal to base app

func setup(email_data: Array) -> void:
	# Clear previous messages
	for child in email_messages_container.get_children():
		email_messages_container.remove_child(child)
		child.queue_free()
	_inspector.forget_all()

	# Set up the top bar with the first email data
	var starting_email = email_data[0]
	subject_label.text = starting_email.get("subject")
	subject_target.section = {
		"source": "email",
		"email_id": str(starting_email.get("email_id", "")),
		"section": "subject",
		"excerpt": str(starting_email.get("subject")),
	}
	_inspector.add(subject_target)
	thread_size_label.text = "Caixa de entrada · %d %s" % [
		email_data.size(), "mensagem" if email_data.size() == 1 else "mensagens"
	]

	# Iterate through emails and create email_message_instances
	for email_message_data in email_data:
		var email_message_instance = EMAIL_MESSAGE_INSTANCE_SCENE.instantiate()
		email_message_instance.setup(email_message_data)
		email_messages_container.add_child(email_message_instance)
		for target in email_message_instance.discrepancy_targets:
			_inspector.add(target)

	# Opens the thread showing the latest email, once the messages just added are
	# accounted for by the containers
	scroll_container.jump_to_bottom()

## Arms every section of the thread so the player can point at the one giving the scam away
func set_inspection_mode(is_on: bool) -> void:
	_inspector.set_armed(is_on)

## Sections that can be pointed at, lit while the rest of the phone is dimmed
func get_discrepancy_targets() -> Array[DiscrepancyTarget]:
	return _inspector.get_targets()

## Unmarks the section picked, the others stay armed
func clear_discrepancy_selection() -> void:
	_inspector.clear_selection()
