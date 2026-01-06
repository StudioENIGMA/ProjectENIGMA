# res://scripts/story/messages/answers_director.gd
extends Node

signal request_answer_option(
	npc_name: String,
	message: String,
	title: String,
	reputation_points: int,
	time: int,
	answer_id: int
)

# Emitted upward to MessagesDirector (its parent) when an answer is chosen.
signal answer_committed(
	thread_id: String,
	choice: Dictionary,
	origin_branch: String,
	origin_index: int,
	priority: int
)

# answer_id -> {"thread_id":..., "choice":..., "origin":..., "priority":...}
var answer_state_by_id: Dictionary = {}
var next_answer_id: int = 1


func present_choices(
	thread_id: String,
	origin_branch: String,
	origin_index: int,
	priority: int,
	node: Dictionary,
	choices: Array,
	current_minutes: int
) -> void:
	var npc_name := str(node.get("sender", thread_id))

	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue

		var answer_id := _new_answer_id()
		answer_state_by_id[answer_id] = {
			"thread_id": thread_id,
			"choice": choice,
			"origin_branch": origin_branch,
			"origin_index": origin_index,
			"priority": priority,
		}

		var player_text := str(choice.get("player_text", ""))
		var title := str(choice.get("title", player_text))
		var rep_points := int(choice.get("reputation_points", 0))

		request_answer_option.emit(
			npc_name,
			player_text,
			title,
			rep_points,
			current_minutes,
			answer_id
		)


func on_message_answered(answer_id: int) -> void:
	if not answer_state_by_id.has(answer_id):
		return

	var state: Dictionary = answer_state_by_id[answer_id]
	answer_state_by_id.erase(answer_id)

	var thread_id := str(state.get("thread_id", ""))
	var choice: Dictionary = state.get("choice", {})
	var origin_branch := str(state.get("origin_branch", ""))
	var origin_index := int(state.get("origin_index", 0))
	var priority := int(state.get("priority", 0))

	_apply_choice_effects(choice)

	answer_committed.emit(thread_id, choice, origin_branch, origin_index, priority)


func _new_answer_id() -> int:
	var created_id := next_answer_id
	next_answer_id += 1
	return created_id


func _apply_choice_effects(choice: Dictionary) -> void:
	var rep_points := int(choice.get("reputation_points", 0))
	if rep_points != 0:
		GameData.data["reputation_points"] = int(GameData.data.get("reputation_points", 0)) + rep_points
