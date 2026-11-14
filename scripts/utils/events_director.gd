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
## result: "verdict" ("found", "duplicate", "late", "wrong", "false", "early" or "stale"),
## "title" and "subtitle" for the stamp, and "points" won or lost
signal report_evaluated(result: Dictionary)
## Emitted when a report blocks a scam, with the conversations that take no more answers
signal scam_blocked(conversation_ids: Array)
## Emitted right after scam_blocked with the event blocked, for the emails it was sent in
signal scam_event_blocked(event_id: String)
## Emitted when the player falls for a scam, with its conversations, kept to be compared later
signal scam_fallen(conversation_ids: Array)
## Emitted when a task (not a scam) is done, so its sender can answer, see emails_director
signal task_completed(event_id: String)
## Emitted when the player falls for a scam, judged by the difficulty: "fall" (how many scams were
## fallen for today), "free_falls" (how many a day the difficulty forgives) and "points" (lost at
## the end of the day, 0 while the fall is forgiven)
signal scam_fall_judged(fall: Dictionary)
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
## email_id of every email whose installer the player ran today, for the "installer_opened" and
## "payment_or_installer" requirements
var opened_installers: Array[String] = []
## Random tasks and scams lost today, see lose_event()
var lost_events: Array[String] = []
## What the lost events are on (their chat, emails and payments), as a report points at it
var _lost_pieces: Array[Dictionary] = []
## event_id -> ids of the discrepancies of that event found today
var found_discrepancies: Dictionary = {}
## event_id -> {store: {item_id: quantity}} bought for that event today, see _hand_out_purchases()
var purchase_credits: Dictionary = {}
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
	opened_installers = []
	lost_events = []
	_lost_pieces = []
	found_discrepancies = {}
	purchase_credits = {}
	_report_entries = {}
	_wrong_reports_entry = {}
	GameData.events_log.clear()
	GameData.daily_reputation_points = 0
	GameData.options_chose.clear()
	GameData.read_emails.clear()
	GameData.seen_info.clear()
	GameData.blocked_conversations.clear()
	GameData.blocked_payment_codes.clear()
	GameData.lost_conversations.clear()
	GameData.lost_threads.clear()
	GameData.lost_payment_codes.clear()
	GameData.purchased_items.clear()
	GameData.scam_conversations.clear()
	for event in events_dict.values():
		if event.get("type", "") == "scam":
			GameData.scam_conversations.append_array(_get_conversations(event))

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

## Whether an event delivered today is still to be done: a task not completed yet, or a scam
## neither fallen for nor blocked
func is_event_pending(event_id: String) -> bool:
	return events_to_check.has(event_id)

## Runs an installer attached to an email: the phone is hacked at once, even on a fall the
## difficulty forgives, and the scam that sent it is fallen for on the next tick
func on_installer_opened(email_id: String) -> void:
	if not opened_installers.has(email_id):
		opened_installers.append(email_id)
	hack_requested.emit()

## Loses a random task or scam whose contact went offline before it was done: it can no longer be
## done, fallen for or reported and its payments are refused. It costs no points, it only shows up
## in the day summary
##
## pieces: What it was on besides its payments, as a report points at it: {"source": "messages",
## "conversation"} for a chat, {"source": "email", "email_id"} for each email of a thread
func lose_event(event_id: String, pieces: Array) -> void:
	if not events_to_check.has(event_id):
		return
	events_to_check.erase(event_id)
	lost_events.append(event_id)
	_lost_pieces.append_array(pieces)

	var event: Dictionary = events_dict.get(event_id, {})
	for code in _get_payment_codes(event):
		_lost_pieces.append({"source": "bank", "payment_code": code})
		GameData.lost_payment_codes.append(code)

	GameData.events_log.append({
		"type": "lost",
		"description": "Contato perdido: %s" % event.get("description", ""),
		"reputation_points": 0,
	})

## Payment codes an event waits on or points its discrepancies at
func _get_payment_codes(event: Dictionary) -> Array:
	var codes: Array = []
	for requirement in event.get("requires", []):
		if requirement.has("payment_id"):
			codes.append(str(requirement["payment_id"]))
		for code in requirement.get("payment_array", []):
			codes.append(str(code))
	for discrepancy in event.get("discrepancies", []):
		for place in discrepancy.get("found_at", []):
			if place.has("payment_code"):
				codes.append(str(place["payment_code"]))
	return codes

## Whether a section is on a random task or scam lost today
func _is_lost_section(section: Dictionary) -> bool:
	return _lost_pieces.any(func(piece: Dictionary) -> bool: return _is_same_piece(piece, section))

func _on_clock_tick() -> void:
	_hand_out_purchases()
	# Iterates over a copy, completed events are erased from the list meanwhile
	for event_id in events_to_check.duplicate():
		var event = events_dict.get(event_id, null)
		if event == null:
			events_to_check.erase(event_id)
			continue
		var is_event_completed: bool = evaluate_requirements(event, event_id)
		if is_event_completed:
			events_to_check.erase(event_id)

			var event_type = event.get("type", "")
			var reputation_points = TYPE_TO_RP.get(event_type, 0)
			var log_entry: Dictionary = event

			if event_type == "scam":
				fallen_events.append(event_id)
				var fall := _judge_fall()
				reputation_points = fall["points"]
				# The line of the day summary tells the fall apart, the event is shared by every day
				log_entry = event.duplicate()
				log_entry["reputation_points"] = reputation_points
				if reputation_points == 0:
					log_entry["description"] = "%s · sem consequência (%d/%d)" % [
						event.get("description", ""), fall["fall"], fall["free_falls"]
					]
				else:
					# A forgiven fall goes without its consequence too: nothing negative happens
					_apply_consequence(event.get("consequence", {}))
				scam_fallen.emit(_get_conversations(event))
				scam_fall_judged.emit(fall)

			GameData.events_log.append(log_entry)
			if event_type != "scam":
				task_completed.emit(event_id)
			GameData.daily_reputation_points += reputation_points

func evaluate_requirements(event: Dictionary, event_id: String) -> bool:
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
			return has_purchased(event_id, requirement.get("items", []))
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
			if not GameData.options_chose.has(choice):
				return false
			# A scam only takes the answer given in its own chat, an answer shared by several
			# scams ("$bank_password") is left to the scam of the chat it was picked in
			# ponytail: tasks have no chat in events.json and take it from any chat, their
			# answers are unique
			var chosen_in := str(GameData.options_chose[choice])
			var conversations := _get_conversations(event)
			if chosen_in != "" and not conversations.is_empty() and not conversations.has(chosen_in):
				return false
			GameData.options_chose.erase(choice)
			return true
		elif flag == "email_read":
			return GameData.read_emails.has(requirement.get("email_id", ""))
		elif flag == "installer_opened":
			return opened_installers.has(str(requirement.get("email_id", "")))
		# A scam sending a boleto and an installer: paying it or running it, either is a fall
		elif flag == "payment_or_installer":
			return GameData.completed_payments.has(requirement.get("payment_id", "")) \
				or opened_installers.has(str(requirement.get("email_id", "")))
	return false

## Hands the orders paid since the last tick (GameData.purchased_items) out to the events waiting on
## them, tasks before scams, each taking only what it still lacks. An order thus counts once and only
## for what was already asked: it neither completes a task delivered later nor makes the player fall
## for a scam asking the same as a task, unless more than the task asked was bought
func _hand_out_purchases() -> void:
	var is_scam := func(event_id: String) -> bool:
		return events_dict.get(event_id, {}).get("type", "") == "scam"
	var waiting: Array = events_to_check.filter(func(id): return not is_scam.call(id)) \
		+ events_to_check.filter(is_scam)

	for store in GameData.purchased_items:
		for item_id in GameData.purchased_items[store]:
			var left := int(GameData.purchased_items[store][item_id])
			for event_id in waiting:
				var credits: Dictionary = purchase_credits.get_or_add(event_id, {}).get_or_add(store, {})
				var had := int(credits.get(int(item_id), 0))
				var taken := clampi(_get_asked_quantity(event_id, store, int(item_id)) - had, 0, left)
				credits[int(item_id)] = had + taken
				left -= taken
	# ponytail: what no event asked for is dropped, it was bought for nothing delivered yet
	GameData.purchased_items.clear()

## How many of an item the purchase requirements of an event ask for in a store
func _get_asked_quantity(event_id: String, store: int, item_id: int) -> int:
	var asked := 0
	for requirement in events_dict.get(event_id, {}).get("requires", []):
		for item in requirement.get("items", []):
			var store_ids = item.get("store", [])
			if typeof(store_ids) == TYPE_STRING:
				store_ids = [store_ids]
			var stores: Array = store_ids.map(
				func(store_name): return GameData.shop_string_to_enum.get(store_name)
			)
			if int(item.get("item_id", -1)) == item_id and stores.has(store):
				asked += int(item.get("quantity", 0))
	return asked

## Whether the items were bought for the event, each in one of the stores it names, see
## _hand_out_purchases(). Chats ask it too, for the thanks of the NPC once the event is done
func has_purchased(event_id: String, items: Array) -> bool:
	var credits: Dictionary = purchase_credits.get(event_id, {})
	for item in items:
		var store_ids = item.get("store", [])
		if typeof(store_ids) == TYPE_STRING:
			store_ids = [store_ids]
		var is_item_bought := false
		for store_name in store_ids:
			var store = GameData.shop_string_to_enum.get(store_name, null)
			var bought := int(credits.get(store, {}).get(int(item.get("item_id", -1)), 0))
			if bought >= int(item.get("quantity", 0)):
				is_item_bought = true
		if not is_item_bought:
			return false
	return true

## Whether the scam just fallen for costs points: the difficulty forgives the first ones of the day
func _judge_fall() -> Dictionary:
	var free_falls := GameData.get_free_scam_falls()
	var fall := fallen_events.size()
	return {
		"fall": fall,
		"free_falls": free_falls,
		"points": 0 if fall <= free_falls else TYPE_TO_RP["scam"],
	}

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

	# A lost contact is gone, nothing of it can be reported anymore
	if _is_lost_section(section):
		report_evaluated.emit(
			_verdict("lost", "CONTATO PERDIDO", "O tempo para resolver acabou", 0)
		)
		return

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

	# A scam of today given away by a rule not released yet is not the player's job either
	for event_id in initiated_events:
		for discrepancy in events_dict.get(event_id, {}).get("discrepancies", []):
			for place in discrepancy.get("found_at", []):
				if _is_same_piece(place, section):
					report_evaluated.emit(
						_verdict("early", "AINDA NÃO", "Essa regra ainda não vale hoje", 0)
					)
					return

	# A scam of another day is left alone, it is no longer the player's job
	for event_id in events_dict:
		if initiated_events.has(event_id):
			continue
		for discrepancy in events_dict[event_id].get("discrepancies", []):
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

	var conversations := _get_conversations(event)
	for discrepancy in event.get("discrepancies", []):
		for place in discrepancy.get("found_at", []):
			if place.has("payment_code"):
				GameData.blocked_payment_codes.append(str(place["payment_code"]))
	for requirement in event.get("requires", []):
		if requirement.has("payment_id"):
			GameData.blocked_payment_codes.append(str(requirement["payment_id"]))
		for code in requirement.get("payment_array", []):
			GameData.blocked_payment_codes.append(str(code))

	GameData.blocked_conversations.append_array(conversations)
	scam_blocked.emit(conversations)
	scam_event_blocked.emit(event_id)

## Conversations a scam is carried out in, as named by the places of its discrepancies
func _get_conversations(event: Dictionary) -> Array:
	var conversations: Array = []
	for discrepancy in event.get("discrepancies", []):
		for place in discrepancy.get("found_at", []):
			if place.has("conversation") and not conversations.has(place["conversation"]):
				conversations.append(place["conversation"])
	return conversations

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
