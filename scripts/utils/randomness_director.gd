extends Node
## Feeds the random lane of the StoryDirector with the random tasks and scams of the day
##
## There is no amount per day: whenever the random lane is free the StoryDirector asks for the
## next event, so they come one after another from the start to the end of the day, each sender
## once a day. A sender by message is a person, told apart by the contact name: the conversations
## sharing a name are one chat to the player, so a person brings one of them a day at most, and none
## on a day the story itself writes as them.

#region SIGNALS
signal schedule_message(story_entry: Dictionary)
signal schedule_email(story_entry: Dictionary)
#endregion SIGNALS

#region CONSTANTS
## The tutorial (day 0) and the last day never get random events
const DAYS_WITHOUT_RANDOM_EVENTS = [0, 7]
#endregion CONSTANTS

#region STATES
var tasks_list: Array
var scams_list: Array
## Senders that already sent a random event today, see _get_sender_id()
var senders_today: Dictionary = {}
## conversation_id -> contact_name of every conversation, see MessagesDirector.get_contact_names()
var contact_names: Dictionary = {}
## Every event of data/events/events.json, to know which discrepancies a scam declares
var events_dict: Dictionary = {}
## rule id -> day the rule is released on
var rule_days: Dictionary = {}
## Events showing a bank not accepted today as true information, which are not sent today, see
## BoletosDirector.get_events_with_unaccepted_banks()
var unaccepted_bank_events: Array = []
## DEBUG: senders send more than one random event a day, so every event of the day comes
var debug_every_event: bool = false
#endregion STATES


#region SETUP
func setup_from_json_roots(
	random_tasks: Array,
	random_scams: Array,
	events: Dictionary,
	rules: Array,
	events_with_unaccepted_banks: Array = [],
	p_contact_names: Dictionary = {},
	contact_names_in_story: Array = [],
) -> void:
	tasks_list.clear()
	for root in random_tasks:
		tasks_list.append_array(root)
	scams_list.clear()
	for root in random_scams:
		scams_list.append_array(root)
	events_dict = events
	rule_days.clear()
	for rule in rules:
		rule_days[str(rule.get("id", ""))] = int(rule.get("day", 0))
	unaccepted_bank_events = events_with_unaccepted_banks
	contact_names = p_contact_names
	senders_today.clear()
	# A contact the story writes as today already has its chat of the day
	for contact_name in contact_names_in_story:
		senders_today[_get_contact_sender_id(str(contact_name))] = true
#endregion SETUP

#region FUNCTIONS
## Schedules the next random event of the day, due at once, if the player can get one
##
## Called by StoryDirector whenever the random lane is free. An event waiting on an app the player
## has not installed yet is left for a later call.
func schedule_next_event(current_minutes: int) -> void:
	if DAYS_WITHOUT_RANDOM_EVENTS.has(GameData.current_day):
		return

	var available_events := (tasks_list + scams_list).filter(
		func(event: Dictionary) -> bool:
			return (debug_every_event or not senders_today.has(_get_sender_id(event))) 				and evaluate_requirements(event)
	)
	if available_events.is_empty():
		return

	var event: Dictionary = available_events.pick_random()
	var event_id := _get_event_id(event)
	mark_sender(event)
	GameData.random_events_history.append(event_id)

	if event.has("email_id"):
		schedule_email.emit({
			"thread_id": event.get("thread_id"),
			"email_id": event_id,
			"event_id": event_id,
			"due_at": current_minutes,
			"requires": [],
		})
	else:
		schedule_message.emit({
			"conversation_id": event.get("conversation_id"),
			"branch": event_id,
			"event_id": event_id,
			"index": 0,
			"due_at": current_minutes,
			"requires": [],
		})

## Keeps the sender of a random event (or of a payload scheduled for one) from sending another today
func mark_sender(event: Dictionary) -> void:
	senders_today[_get_sender_id(event)] = true

## Who sends a random event: the email thread_id, or the contact name of the messages conversation
func _get_sender_id(event: Dictionary) -> String:
	if event.has("email_id"):
		return str(event.get("thread_id"))
	var conversation_id := str(event.get("conversation_id"))
	return _get_contact_sender_id(str(contact_names.get(conversation_id, conversation_id)))

## Sender id of a contact by message, kept apart from the email thread ids
func _get_contact_sender_id(contact_name: String) -> String:
	return "messages:" + contact_name

## Id of a random event: the email_id, or the branch of the conversation
func _get_event_id(event: Dictionary) -> String:
	assert(event.has("email_id") or event.has("branch"))
	if event.has("email_id"):
		return str(event.get("email_id"))
	return str(event.get("branch"))

func evaluate_requirements(event: Dictionary) -> bool:
	var event_id := _get_event_id(event)
	if GameData.random_events_history.has(event_id):
		return false

	var app = GameData.apps_name.get(event.get("required_app", ""), null)
	if not GameData.downloaded_apps.has(app):
		return false

	if event.has("email_id") and not GameData.downloaded_apps.has(GameData.App.EMAIL):
		return false

	# Its boleto would show as true a bank the company does not accept today
	if unaccepted_bank_events.has(event_id):
		return false

	return _has_released_discrepancy(event_id)

## Whether the player can already report the event: it declares no discrepancy (a task), or at
## least one of its discrepancies breaks a rule released by today
func _has_released_discrepancy(event_id: String) -> bool:
	var discrepancies: Array = events_dict.get(event_id, {}).get("discrepancies", [])
	if discrepancies.is_empty():
		return true
	for discrepancy in discrepancies:
		if rule_days.get(str(discrepancy.get("rule", "")), 999) <= GameData.current_day:
			return true
	return false
#endregion FUNCTIONS
