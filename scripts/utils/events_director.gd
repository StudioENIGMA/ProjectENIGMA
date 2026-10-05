extends Node
## Keeps the events of the day: completes them when their requirements are met and judges the
## scams the player reports
##
## A scam lists its discrepancies in data/events/events.json, each a rule it breaks and the
## sections it can be pointed at ("found_at", possibly in several apps). Reporting any of those
## places finds the discrepancy once: pointing at the same one in another app finds nothing new.
## The first discrepancy found blocks the scam, each other one found only adds points.

## Emitted once a report is judged, for the phone to stamp the verdict
##
## result: "verdict" ("found", "duplicate", "late", "wrong", "false" or "stale"), "title" and
## "subtitle" for the stamp, and "points" won or lost
signal report_evaluated(result: Dictionary)
## Emitted when a report blocks a scam, with the conversations that take no more answers
signal scam_blocked(conversation_ids: Array)
## Emitted when the player falls for a scam whose consequence is being hacked
signal hack_requested()

#region CONSTANTS
const TYPE_TO_RP = {
	"conversation": 10,
	"random-task": 15,
	"main-task": 20,
	"scam": - 10,
}
## Points of the first discrepancy found in a scam, which blocks it
const FIRST_FIND_RP := 10
## Points of every other discrepancy found in the same scam
const EXTRA_FIND_RP := 5
## Points of reporting a badly reviewed store
const STORE_FIND_RP := 5
## Points of a report on a scam that names the wrong rule or section
const WRONG_REPORT_RP := -2
## Points of a report on something that is not a scam
const FALSE_REPORT_RP := -5
#endregion CONSTANTS

#region STATES
var events_dict: Dictionary
var events_to_check: Array[String]
## Events delivered today, the ones a report is judged against
var initiated_events: Array[String] = []
## Scams the player fell for today
var fallen_events: Array[String] = []
## event_id -> ids of the discrepancies of that event found today
var found_discrepancies: Dictionary = {}
## rule id -> rule, as read from data/rules/rules.json
var rules_by_id: Dictionary = {}
## event_id -> its line in the day summary, kept to be updated as more is found
var _report_entries: Dictionary = {}
## Single line of the day summary gathering every report that was wrong
var _wrong_reports_entry: Dictionary = {}
#endregion STATES

#region SETUP
func setup_from_json_file(events_json: Variant, rules: Array) -> void:
	assert(typeof(events_json) == TYPE_DICTIONARY)
	events_dict = events_json
	events_to_check = []
	initiated_events = []
	fallen_events = []
	found_discrepancies = {}
	_report_entries = {}
	_wrong_reports_entry = {}
	GameData.events_log.clear()
	GameData.daily_reputation_points = 0
	GameData.options_chose.clear()
	GameData.read_emails.clear()
	GameData.blocked_conversations.clear()
	GameData.blocked_payment_codes.clear()

	rules_by_id.clear()
	for rule in rules:
		rules_by_id[str(rule.get("id", ""))] = rule

	# Some events are always there to be reported, like a badly reviewed store
	for event_id in events_dict.keys():
		if events_dict[event_id].get("always_active", false):
			initiated_events.append(event_id)
#endregion SETUP

#region FUNCTIONS
func _on_event_initiated(event_id: String) -> void:
	if event_id == "":
		return
	if not initiated_events.has(event_id):
		initiated_events.append(event_id)
	if not events_to_check.has(event_id):
		events_to_check.append(event_id)

func _on_clock_tick() -> void:
	# Iterates over a copy, completed events are erased from the list meanwhile
	for event_id in events_to_check.duplicate():
		var event = events_dict.get(event_id, null)
		if event == null:
			events_to_check.erase(event_id)
			continue
		var is_event_completed: bool = evaluate_requirements(event)
		if is_event_completed:
			GameData.events_log.append(event)
			events_to_check.erase(event_id)

			var event_type = event.get("type", "")
			var reputation_points = TYPE_TO_RP.get(event_type, 0)
			GameData.daily_reputation_points += reputation_points

			if event_type == "scam":
				fallen_events.append(event_id)
				_apply_consequence(event.get("consequence", {}))

func evaluate_requirements(event: Dictionary) -> bool:
	if event == null:
		return false
	for requirement in event.get("requires"):
		var flag = requirement.get("flag", "")
		assert(flag != "")
		if flag == "app_installed":
			var app_id = requirement.get("app_id", "")
			var app = GameData.apps_name.get(app_id, null)
			return GameData.downloaded_apps.has(app)
		elif flag == "purchase":
			var items = requirement.get("items", [])
			for item in items:
				var item_id = item.get("item_id", "")
				var quantity = int(item.get("quantity", 0))
				var store_ids = item.get("store", [])

				if typeof(store_ids) == TYPE_STRING:
					store_ids = [store_ids]

				var is_item_valid = false

				for store_name in store_ids:
					var store = GameData.shop_string_to_enum.get(store_name, null)

					if not GameData.purchased_items.has(store):
						continue
					var store_purchases = GameData.purchased_items[store]
					if not store_purchases.has(item_id):
						continue
					if store_purchases[item_id] < quantity:
						continue
					is_item_valid = true

				if not is_item_valid:
					return false
			return true
		elif flag == "payment":
			var payment_id = requirement.get("payment_id", "")
			return GameData.completed_payments.has(payment_id)
		elif flag == "payment_multitype":
			var payment_array = requirement.get("payment_array", [])
			for code in payment_array:
				if GameData.completed_payments.has(code):
					return true
			return false
		elif flag == "option":
			var choice = requirement.get("choice", "")
			var was_chosen = GameData.options_chose.get(choice, false)
			GameData.options_chose[choice] = false
			return was_chosen
		elif flag == "email_read":
			return GameData.read_emails.has(requirement.get("email_id", ""))
	return false

## What falling for a scam costs besides reputation
##
## consequence: "hack" (the phone is hacked at once) and "bank_loss" (money taken)
func _apply_consequence(consequence: Dictionary) -> void:
	if consequence.get("hack", false):
		hack_requested.emit()
	if consequence.has("bank_loss"):
		GameData.bank_balance -= float(consequence["bank_loss"])
#endregion FUNCTIONS

#region REPORTS
## Judges a report of the player and emits report_evaluated with the verdict
##
## report: "section" (what was pointed at: "source", "section", the id of what it belongs to
## and "excerpt") and "rule" (the rule picked, as read from data/rules/rules.json)
func evaluate_report(report: Dictionary) -> void:
	var section: Dictionary = report.get("section", {})
	var rule_id := str(report.get("rule", {}).get("id", ""))

	# The scam delivered today that the section belongs to, if any
	var scam_of_section := ""
	for event_id in initiated_events:
		var event: Dictionary = events_dict.get(event_id, {})
		for discrepancy in _get_released_discrepancies(event):
			for place in discrepancy.get("found_at", []):
				if not _is_same_piece(place, section):
					continue
				scam_of_section = event_id
				if str(discrepancy.get("rule", "")) == rule_id and _is_same_section(place, section):
					report_evaluated.emit(_on_discrepancy_found(event_id, discrepancy))
					return

	if scam_of_section != "":
		if fallen_events.has(scam_of_section):
			report_evaluated.emit(_verdict("late", "TARDE DEMAIS", "Você já caiu nesse golpe", 0))
			return
		_add_wrong_report(WRONG_REPORT_RP)
		report_evaluated.emit(
			_verdict("wrong", "NÃO CONFERE", "Confira a regra e a seção", WRONG_REPORT_RP)
		)
		return

	# A scam of another day is left alone, it is no longer the player's job
	for event in events_dict.values():
		for discrepancy in event.get("discrepancies", []):
			for place in discrepancy.get("found_at", []):
				if _is_same_piece(place, section):
					report_evaluated.emit(
						_verdict("stale", "FORA DO DIA", "Esse golpe não é de hoje", 0)
					)
					return

	_add_wrong_report(FALSE_REPORT_RP)
	report_evaluated.emit(
		_verdict("false", "DENÚNCIA FALSA", "Isso não é golpe", FALSE_REPORT_RP)
	)

## Counts a discrepancy found, blocking the scam on the first one
func _on_discrepancy_found(event_id: String, discrepancy: Dictionary) -> Dictionary:
	var event: Dictionary = events_dict[event_id]
	var found: Array = found_discrepancies.get(event_id, [])
	var total := _get_released_discrepancies(event).size()
	var progress := "%d de %d discrepâncias" % [found.size(), total]

	if found.has(discrepancy.get("id")):
		return _verdict("duplicate", "JÁ ANOTADA", progress, 0)
	if fallen_events.has(event_id):
		return _verdict("late", "TARDE DEMAIS", "Você já caiu nesse golpe", 0)

	found.append(discrepancy.get("id"))
	found_discrepancies[event_id] = found
	progress = "%d de %d discrepâncias" % [found.size(), total]
	var is_first := found.size() == 1

	var points: int
	var title: String
	if event.get("type", "") == "store":
		points = STORE_FIND_RP
		title = "LOJA DENUNCIADA"
	else:
		points = FIRST_FIND_RP if is_first else EXTRA_FIND_RP
		title = "GOLPE BLOQUEADO" if is_first else "DISCREPÂNCIA ANOTADA"
		if is_first:
			_block_scam(event_id)

	GameData.daily_reputation_points += points
	_log_report(event_id, points)
	return _verdict("found", title, progress, points)

## Stops a scam from going on: its conversations take no more answers, its payments are refused
## and it can no longer be fallen for
func _block_scam(event_id: String) -> void:
	events_to_check.erase(event_id)
	var event: Dictionary = events_dict[event_id]

	var conversations: Array = []
	for discrepancy in event.get("discrepancies", []):
		for place in discrepancy.get("found_at", []):
			if place.has("conversation") and not conversations.has(place["conversation"]):
				conversations.append(place["conversation"])
			if place.has("payment_code"):
				GameData.blocked_payment_codes.append(str(place["payment_code"]))
	for requirement in event.get("requires", []):
		if requirement.has("payment_id"):
			GameData.blocked_payment_codes.append(str(requirement["payment_id"]))
		for code in requirement.get("payment_array", []):
			GameData.blocked_payment_codes.append(str(code))

	GameData.blocked_conversations.append_array(conversations)
	scam_blocked.emit(conversations)

## Writes (or updates) the line of the day summary of a reported event, naming what was missed
func _log_report(event_id: String, points: int) -> void:
	var event: Dictionary = events_dict[event_id]
	var entry: Dictionary = _report_entries.get(event_id, {})
	if entry.is_empty():
		entry = {"type": "report", "reputation_points": 0}
		_report_entries[event_id] = entry
		GameData.events_log.append(entry)
	entry["reputation_points"] += points

	var found: Array = found_discrepancies.get(event_id, [])
	var released := _get_released_discrepancies(event)
	var missed: Array = []
	for discrepancy in released:
		if not found.has(discrepancy.get("id")):
			var rule: Dictionary = rules_by_id.get(str(discrepancy.get("rule", "")), {})
			missed.append(str(rule.get("title", discrepancy.get("rule", ""))))

	var prefix := "Loja denunciada" if event.get("type", "") == "store" else "Golpe bloqueado"
	var description := "%s: %s · %d de %d" % [
		prefix, event.get("description", ""), found.size(), released.size()
	]
	if not missed.is_empty():
		description += " (faltou: %s)" % ", ".join(missed)
	entry["description"] = description

## Adds a wrong report to the single line gathering them in the day summary
func _add_wrong_report(points: int) -> void:
	GameData.daily_reputation_points += points
	if _wrong_reports_entry.is_empty():
		_wrong_reports_entry = {"type": "report", "reputation_points": 0, "count": 0}
		GameData.events_log.append(_wrong_reports_entry)
	_wrong_reports_entry["count"] += 1
	_wrong_reports_entry["reputation_points"] += points
	_wrong_reports_entry["description"] = "Denúncias erradas (%d)" % _wrong_reports_entry["count"]

## Discrepancies of an event whose rule the player already has
func _get_released_discrepancies(event: Dictionary) -> Array:
	return event.get("discrepancies", []).filter(
		func(discrepancy: Dictionary) -> bool:
			var rule: Dictionary = rules_by_id.get(str(discrepancy.get("rule", "")), {})
			return not rule.is_empty() and int(rule.get("day", 0)) <= GameData.current_day
	)

## Whether a place of a discrepancy is on the same thing (conversation, email, payment,
## document or store) the section pointed at belongs to, whatever its section
func _is_same_piece(place: Dictionary, section: Dictionary) -> bool:
	for key in place.keys():
		if key == "section" or key == "contains":
			continue
		if str(place[key]) != str(section.get(key, "")):
			return false
	return true

## Whether the section pointed at is the one of the place, holding its text if it asks for one
func _is_same_section(place: Dictionary, section: Dictionary) -> bool:
	if str(place.get("section", "")) != str(section.get("section", "")):
		return false
	var contains := str(place.get("contains", ""))
	return contains.is_empty() or str(section.get("excerpt", "")).containsn(contains)

func _verdict(verdict: String, title: String, subtitle: String, points: int) -> Dictionary:
	return {"verdict": verdict, "title": title, "subtitle": subtitle, "points": points}
#endregion REPORTS
