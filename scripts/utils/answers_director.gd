extends Node

#region SIGNALS
## contact: The conversation the answer belongs to, see messages_director._get_contact()
signal request_answer_option(
	contact: Dictionary,
	message: String,
	title: String,
	reputation_points: int,
	time: int,
	answer_id: int
)

# Emitted upward to MessagesDirector when an answer is chosen.
signal answer_committed(
	conversation_id: String,
	choice: Dictionary,
)

signal delete_conversation(conversation_id: String)
#endregion SIGNALS


#region STATE
# answer_id -> {"conversation_id":..., "choice":...}
var answer_state_by_id: Dictionary = {}
var next_answer_id: int = 1
#endregion STATE


#region PUBLIC API
## Presents choice options for a message node. Creates answer_ids and emits request_answer_option.
func present_choices(
	contact: Dictionary,
	choices: Array,
	current_minutes: int
) -> void:
	if choices.is_empty():
		return

	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue

		var answer_id := _new_answer_id()
		_register_answer_state(answer_id, str(contact["id"]), choice)

		var player_text := str(choice.get("player_text", ""))
		var title := str(choice.get("title", player_text))
		var rep_points := int(choice.get("reputation_points", 0))

		request_answer_option.emit(
			contact,
			player_text,
			title,
			rep_points,
			current_minutes,
			answer_id
		)

## Called by UI (or whoever) when the player picks an answer option.
func on_message_answered(answer_id: int) -> void:
	if not answer_state_by_id.has(answer_id):
		return

	var state: Dictionary = answer_state_by_id[answer_id]
	answer_state_by_id.erase(answer_id)

	var conversation_id := str(state.get("conversation_id", ""))
	var choice: Dictionary = state.get("choice", {})

	_apply_choice_effects(conversation_id, choice)

	answer_committed.emit(conversation_id, choice)

## Useful when reloading messages/day to avoid stale UI answers.
func clear_pending_answers() -> void:
	answer_state_by_id.clear()
	next_answer_id = 1
#endregion PUBLIC API


#region INTERNAL HELPERS
func _new_answer_id() -> int:
	var created_id := next_answer_id
	next_answer_id += 1
	return created_id

func _register_answer_state(
	answer_id: int,
	conversation_id: String,
	choice: Dictionary,
) -> void:
	answer_state_by_id[answer_id] = {
		"conversation_id": conversation_id,
		"choice": choice,
	}
#endregion INTERNAL HELPERS


#region EFFECTS
func _apply_choice_effects(conversation_id: String, choice: Dictionary) -> void:
	var rep_points := int(choice.get("reputation_points", 0))
	if rep_points != 0:
		GameData.reputation_points += rep_points

	var player_text := str(choice.get("player_text", ""))
	GameData.options_chose[player_text] = true

	# If choice has an event_id, do what is expected from it
	var event_id = choice.get("event_id", null)
	if event_id != null:
		match event_id:
			"block_and_report":
				# Delete the conversation the choice was answered in
				delete_conversation.emit(conversation_id)
#endregion EFFECTS
