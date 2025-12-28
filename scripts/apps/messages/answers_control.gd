extends HBoxContainer

signal message_answered(answer_id:int)

signal request_message_creation_on_answer(
	name:String,
	message:String,
	sender:GameData.Sender,
	time:int
)

const ANSWER_OPTION_SCENE := preload("res://scenes/apps/messages/answer_option.tscn")

var pending:Array[Dictionary] = []
var active_conversation_name:String = ""

func _ready() -> void:
	EventBus.delete_answers.connect(_on_delete_answers)

func set_active_conversation(npc_name:String) -> void:
	active_conversation_name = npc_name

func clear_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

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

	# iterate backwards so removal is safe
	for i in range(pending.size() - 1, -1, -1):
		var opt := pending[i]
		if now_minutes < opt["due_at"]:
			continue

		# Store option into conversation data only if it is "new"
		# (your convention: -2 means “already stored, just render it”)
		if opt["time"] >= -1:
			EventBus.storage_answer.emit(
				opt["name"],
				opt["message"],
				opt["title"],
				opt["reputation_points"],
				opt["answer_id"]
			)

		# Only render if this chat is currently open
		if opt["name"] == active_conversation_name:
			var node := ANSWER_OPTION_SCENE.instantiate()
			node.message_answered.connect(message_answered.emit) # Propagate signal to chat app
			node.request_message_creation_on_answer.connect(
				request_message_creation_on_answer.emit # Propagate signal to chat app
			)
			add_child(node)
			node.setup(opt["name"], opt["title"], opt["message"], opt["answer_id"])

		pending.remove_at(i)

func _on_delete_answers(npc_name:String) -> void:
	# Remove pending options for this npc
	for i in range(pending.size() - 1, -1, -1):
		if pending[i]["name"] == npc_name:
			pending.remove_at(i)

	# Clear UI if this is the active conversation
	if npc_name == active_conversation_name:
		clear_ui()
