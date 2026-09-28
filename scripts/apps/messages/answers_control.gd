extends PanelContainer

signal message_answered(answer_id:int)

signal request_message_creation_on_answer(
	name:String,
	message:String,
	annex:Dictionary,
	sender:GameData.Sender,
	time:int
)

signal storage_answer(
	name:String,
	message:String,
	title:String,
	reputation_points:int,
	answer_id:int
)

signal delete_answers(npc_name:String)

## Report that the bar changed height, so the host can make room for it
##
## The composer stays on screen the whole time, it is the reply cards below it
## and the reply picked that grow the bar and take room from the conversation.
##
## has_options: Whether at least one answer option is on screen
signal options_changed(has_options:bool)

const ANSWER_OPTION_SCENE := preload("res://scenes/apps/messages/answer_option.tscn")

@export var options_list:VBoxContainer
@export var choices_section:VBoxContainer
@export var draft_label:Label
@export var send_button:Button

var pending:Array[Dictionary] = []
var active_conversation_name:String = ""

## Keeps a single card picked at a time
var _option_group := ButtonGroup.new()
## The reply waiting to be sent, empty while the player has not picked one
var _draft:Dictionary = {}

func _ready() -> void:
	_clear_draft()

func set_active_conversation(npc_name:String) -> void:
	active_conversation_name = npc_name

func clear_ui() -> void:
	for child in options_list.get_children():
		options_list.remove_child(child)
		child.queue_free()

	_clear_draft()
	choices_section.visible = false
	options_changed.emit(false)

func create_answer_option(
	npc_name:String,
	message:String,
	title:String,
	reputation_points:int,
	time:int,
	answer_id:int
) -> void:
	# Interpret `time` as "due minute". Negative values = immediate.
	var due_at = GameData.hours_minutes if time < 0 else time

	pending.append({
		"name": npc_name,
		"message": message,
		"title": title,
		"reputation_points": reputation_points,
		"time": time,          # keep original for the storage rule
		"due_at": due_at,
		"answer_id": answer_id
	})

func _process(_delta: float) -> void:
	if pending.is_empty():
		return

	var now_minutes = GameData.hours_minutes
	var due:Array[Dictionary] = []

	# iterate backwards so removal is safe, keeping the order the options were written in
	for i in range(pending.size() - 1, -1, -1):
		if now_minutes < pending[i]["due_at"]:
			continue

		due.push_front(pending[i])
		pending.remove_at(i)

	for opt in due:
		# Store option into conversation data only if it is "new"
		# (your convention: -2 means “already stored, just render it”)
		if opt["time"] >= -1:
			storage_answer.emit(
				opt["name"],
				opt["message"],
				opt["title"],
				opt["reputation_points"],
				opt["answer_id"]
			)

		# Only render if this chat is currently open
		if opt["name"] == active_conversation_name:
			var node := ANSWER_OPTION_SCENE.instantiate()
			node.option_selected.connect(_on_option_selected)
			options_list.add_child(node)
			node.set_option_group(_option_group)
			node.setup(opt["name"], opt["title"], opt["message"], opt["answer_id"])
			choices_section.visible = true
			options_changed.emit(true)

## Writes the reply the player picked on the composer, ready to be sent
##
## npc_name: The NPC the answer is addressed to
## message: The message that goes to the conversation once the answer is sent
## answer_id: The identifier of the answer, used to advance the story
func _on_option_selected(npc_name:String, message:String, answer_id:int) -> void:
	_draft = {
		"name": npc_name,
		"message": message,
		"answer_id": answer_id
	}

	draft_label.text = message
	send_button.disabled = false

	# The composer grew around the reply picked, the host has to make room for it
	options_changed.emit(true)

func _on_send_button_pressed() -> void:
	if _draft.is_empty():
		return

	var npc_name:String = _draft["name"]

	request_message_creation_on_answer.emit(
		npc_name,
		_draft["message"],
		{},
		GameData.Sender.PLAYER,
		GameData.hours_minutes
	)
	message_answered.emit(_draft["answer_id"])

	_on_delete_answers(npc_name)
	delete_answers.emit(npc_name) # Propagate signal to app chat

func _on_delete_answers(npc_name:String) -> void:
	# Remove pending options for this npc
	for i in range(pending.size() - 1, -1, -1):
		if pending[i]["name"] == npc_name:
			pending.remove_at(i)

	# Clear UI if this is the active conversation
	if npc_name == active_conversation_name:
		clear_ui()

## Empties the composer, leaving the pill blank and nothing to send
func _clear_draft() -> void:
	_draft = {}
	draft_label.text = ""
	send_button.disabled = true
