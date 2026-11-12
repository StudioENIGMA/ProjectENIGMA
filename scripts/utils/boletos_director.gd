extends Node
## Makes the boletos of the day out of data/bank/boletos.json
##
## A boleto has two faces: the one printed on the PDF attached to an email, which a scammer
## controls, and the one registered at the bank, where the money really goes. A true boleto shows
## its payee as data/bank/boletos.json registers it on both faces. A forged one changes a field on
## either face, and the rule that field breaks becomes a discrepancy of its event, so reporting the
## boleto matches the rules the player already has (a name imitated, another institution, a bank
## not accepted, a code out of the pattern...).
##
## Every boleto is made again each day from the seed of the game, the day and its id: the same day
## always makes the same boleto, with the same code, whenever it is played again.

#region CONSTANTS
## Who pays every boleto
const PAYER := "Enigma Ltda"
## Forgery ("<field>" or "<field>:<mode>") -> rule it breaks, see data/rules/rules.json
const FORGERY_RULES := {
	"payee:lookalike": "lookalike_sender",
	"payee:other": "ticket_payee",
	"cnpj": "ticket_payee",
	"agency": "ticket_payee",
	"bank": "ticket_bank",
	"code:format": "pix_code_format",
	"value": "payment_value",
	"reason": "valid_reason",
}
## Face a forgery shows on when the boleto does not say: "printed", "bank" or "both"
const DEFAULT_FACES := {
	"payee:lookalike": "both",
	"payee:other": "bank",
	"cnpj": "both",
	"agency": "both",
	"bank": "both",
	"code:format": "both",
	"value": "bank",
	"reason": "both",
}
## Mode of a forged field when the boleto does not say
const DEFAULT_MODES := {"payee": "other", "code": "format"}
## Section of the boleto document each field is pointed at in
const BOLETO_SECTIONS := {
	"payee": "boleto_payee",
	"cnpj": "boleto_cnpj",
	"agency": "boleto_agency",
	"bank": "boleto_bank",
	"code": "boleto_code",
	"value": "boleto_value",
	"reason": "boleto_reason",
}
## Section of the bank payment screen each field is pointed at in
const BANK_SECTIONS := {
	"payee": "ticket_payee",
	"cnpj": "ticket_cnpj",
	"agency": "ticket_agency",
	"bank": "ticket_bank",
	"code": "ticket_code",
	"value": "value",
	"reason": "reason",
}
## How the day summary names a scam given away by a forged boleto
const FORGERY_DESCRIPTIONS := {
	"payee:lookalike": "Boleto com nome imitado",
	"payee:other": "Boleto de outra instituição",
	"cnpj": "Boleto com o CNPJ de outra empresa",
	"agency": "Boleto com a agência de outra conta",
	"bank": "Boleto de um banco não aceito",
	"code:format": "Boleto com código fora do padrão",
	"value": "Boleto com valor alterado",
	"reason": "Boleto com motivo fora da lista",
}
## Letters a scammer swaps for a look-alike digit
const LOOKALIKE_DIGITS := {"a": "4", "e": "3", "i": "1", "o": "0", "s": "5"}
#endregion CONSTANTS

#region STATES
## boleto_id -> boleto of today: "boleto_id", "code", "printed" and "registered" (the two faces:
## "payee", "cnpj", "bank", "bank_code", "agency", "value", "reason", "due_date", "payer"),
## "forgeries" (what was forged, as FORGERY_RULES keys), "discrepancies" and "event_id"
var boletos_today: Dictionary = {}

## bank id -> {"name", "code"}
var _banks: Dictionary = {}
## payee id -> {"name", "cnpj", "bank", "agency"}
var _payees: Dictionary = {}
## Forged values to pick from: "payee", "bank" (bank ids) and "reason"
var _forgery_pools: Dictionary = {}
## rule id -> day the rule is released on
var _rule_days: Dictionary = {}
## Banks the company accepts today, a forged bank is picked outside of them
var _accepted_banks: Array = []
## Codes already given (to a Pix, a static boleto or a boleto of today)
var _taken_codes: Dictionary = {}
#endregion STATES

#region SETUP
## Makes every boleto of data/bank/boletos.json for today
##
## boletos_json: The whole file: "banks", "payees", "forgery_pools" and "boletos"
## rules: Every rule of data/rules/rules.json, a random forgery only breaks a rule released today
## accepted_banks: Banks the company accepts today (data/notes/board.json)
## reserved_codes: Codes the bank already knows, which no boleto may take
func setup(
	boletos_json: Dictionary, rules: Array, accepted_banks: Array, reserved_codes: Array
) -> void:
	boletos_today.clear()
	_banks = boletos_json.get("banks", {})
	_payees = boletos_json.get("payees", {})
	_forgery_pools = boletos_json.get("forgery_pools", {})
	_accepted_banks = accepted_banks
	_rule_days.clear()
	for rule in rules:
		_rule_days[str(rule.get("id", ""))] = int(rule.get("day", 0))

	var definitions: Dictionary = boletos_json.get("boletos", {})
	_taken_codes.clear()
	for code in reserved_codes:
		_taken_codes[str(code)] = true
	# Codes fixed in the data are taken before any is made up
	for definition in definitions.values():
		if definition.has("code"):
			_taken_codes[str(definition["code"])] = true

	for boleto_id in definitions:
		boletos_today[boleto_id] = _make_boleto(str(boleto_id), definitions[boleto_id])

## Gives the events waiting on a boleto the code it got today and the discrepancies it was forged
## with. A forged boleto makes its event a scam.
##
## events: Every event of data/events/events.json, changed in place. A "payment" requirement or a
## "bank" place naming a "boleto_id" gets its code; the discrepancies of a forged boleto are merged
## into its event, into the discrepancy of the same rule when there is one
func bind_events(events: Dictionary) -> void:
	for event in events.values():
		for requirement in event.get("requires", []):
			if requirement.has("boleto_id"):
				requirement["payment_id"] = get_code(str(requirement["boleto_id"]))
		for discrepancy in event.get("discrepancies", []):
			for place in discrepancy.get("found_at", []):
				if place.get("source", "") == "bank" and place.has("boleto_id"):
					place["payment_code"] = get_code(str(place["boleto_id"]))
					place.erase("boleto_id")

	for boleto in boletos_today.values():
		var event_id := str(boleto["event_id"])
		if event_id.is_empty() or boleto["forgeries"].is_empty():
			continue
		if not events.has(event_id):
			push_error("Event of a boleto not found: %s" % event_id)
			continue

		var event: Dictionary = events[event_id]
		if event.get("type", "") != "scam":
			event["type"] = "scam"
			event["description"] = FORGERY_DESCRIPTIONS[boleto["forgeries"][0]]
		_merge_discrepancies(event, boleto["discrepancies"])
#endregion SETUP

#region QUERIES
## Code a boleto got today, empty when there is no such boleto
func get_code(boleto_id: String) -> String:
	return str(boletos_today.get(boleto_id, {}).get("code", ""))

## The registered face of every boleto of today, as the bank reads it: code -> "institution",
## "cnpj", "bank", "agency", "value", "reason" and "boleto_id"
func get_registered_codes() -> Dictionary:
	var codes: Dictionary = {}
	for boleto in boletos_today.values():
		var registered: Dictionary = boleto["registered"]
		codes[boleto["code"]] = {
			"institution": registered["payee"],
			"cnpj": registered["cnpj"],
			"bank": registered["bank"],
			"agency": registered["agency"],
			"value": registered["value"],
			"reason": registered["reason"],
			"boleto_id": boleto["boleto_id"],
		}
	return codes

## Events showing a real bank the company does not accept today as true information, on a boleto
## of today or a static one: a task would look like a scam, and a scam would give away a
## discrepancy it does not declare. The fake banks (forgery_pools) are always false information,
## so they never hold an event back. Neither does the bank of a static boleto a scam declares as
## not accepted ("ticket_bank"), which holds it back on the days the company accepts that bank
##
## events: Every event of data/events/events.json, after bind_events() gave them their codes
## tickets: The static boletos of data/bank/ticket_codes_data.json, code -> "bank" among others
func get_events_with_unaccepted_banks(events: Dictionary, tickets: Dictionary) -> Array:
	if _accepted_banks.is_empty():
		return []

	var fake_banks: Array = []
	for bank_id in _forgery_pools.get("bank", []):
		fake_banks.append(str(_banks.get(bank_id, {}).get("name", "")))

	# code -> banks the payment shows, on both faces of a boleto of today
	var banks_by_code: Dictionary = {}
	for code in tickets:
		banks_by_code[str(code)] = [str(tickets[code].get("bank", ""))]
	for boleto in boletos_today.values():
		banks_by_code[boleto["code"]] = [boleto["printed"]["bank"], boleto["registered"]["bank"]]

	var is_unaccepted := func(bank: String) -> bool:
		return not bank.is_empty() and not _accepted_banks.has(bank) and not fake_banks.has(bank)
	var refused: Array = []
	for event_id in events:
		var event: Dictionary = events[event_id]
		var false_bank_codes := _get_false_bank_codes(event)
		for code in _get_payment_codes(event):
			var is_refused: bool
			if false_bank_codes.has(code) and tickets.has(code):
				is_refused = _accepted_banks.has(str(tickets[code].get("bank", "")))
			else:
				is_refused = banks_by_code.get(code, []).any(is_unaccepted)
			if is_refused:
				refused.append(event_id)
				break
	return refused

## Payment codes the "ticket_bank" discrepancies of an event point at, a bank the company does not
## accept being the false information there
func _get_false_bank_codes(event: Dictionary) -> Array:
	var codes: Array = []
	for discrepancy in event.get("discrepancies", []):
		if str(discrepancy.get("rule", "")) != "ticket_bank":
			continue
		for place in discrepancy.get("found_at", []):
			if place.has("payment_code"):
				codes.append(str(place["payment_code"]))
	return codes

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
#endregion QUERIES

#region MAKING
func _make_boleto(boleto_id: String, definition: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameData.run_seed, GameData.current_day, boleto_id])

	var payee: Dictionary = _payees.get(str(definition.get("payee", "")), {})
	if payee.is_empty():
		push_error("Payee of boleto %s not found: %s" % [boleto_id, definition.get("payee")])
	var bank: Dictionary = _banks.get(str(payee.get("bank", "")), {})
	var truth := {
		"payee": str(payee.get("name", "")),
		"cnpj": str(payee.get("cnpj", "")),
		"bank": str(bank.get("name", "")),
		"bank_code": str(bank.get("code", "")),
		"agency": str(payee.get("agency", "")),
		"value": float(definition.get("value", 0.0)),
		"reason": str(definition.get("reason", "")),
		"due_date": _get_due_date(),
		"payer": PAYER,
	}
	var printed := truth.duplicate()
	var registered := truth.duplicate()

	var code := str(definition.get("code", ""))
	var forgeries := _roll_forgeries(definition, rng)
	var forged: Array = []
	for forgery in forgeries:
		var field := str(forgery.get("field", ""))
		var key := _get_forgery_key(forgery)
		if not FORGERY_RULES.has(key):
			push_error("Unknown forgery of boleto %s: %s" % [boleto_id, forgery])
			continue
		var faces := str(forgery.get("on", DEFAULT_FACES[key]))

		# The code is the same on both faces, it is how the bank finds the boleto
		if field == "code":
			if code.is_empty():
				code = _make_forged_code(rng)
		else:
			var forged_value = forgery.get("value", _forge_value(key, truth, rng))
			for face in _get_faces(faces, printed, registered):
				_set_field(face, field, forged_value)
		forged.append({"key": key, "field": field, "faces": faces})

	if code.is_empty():
		code = _make_code(rng)

	var discrepancies: Array = []
	var keys: Array = []
	for forgery in forged:
		keys.append(forgery["key"])
		discrepancies.append(_make_discrepancy(boleto_id, code, forgery))

	return {
		"boleto_id": boleto_id,
		"code": code,
		"printed": printed,
		"registered": registered,
		"forgeries": keys,
		"discrepancies": discrepancies,
		"event_id": str(definition.get("event_id", "")),
	}

## What a boleto is forged with today
##
## A boleto with a "scam_chance" is forged only that often (and with a random forgery if it lists
## none). A forgery with the field "random" becomes any forgery whose rule is released today.
func _roll_forgeries(definition: Dictionary, rng: RandomNumberGenerator) -> Array:
	var forgeries: Array = definition.get("forge", []).duplicate(true)
	if definition.has("scam_chance"):
		if rng.randf() >= float(definition["scam_chance"]):
			return []
		if forgeries.is_empty():
			forgeries = [{"field": "random"}]

	var rolled: Array = []
	for forgery in forgeries:
		if str(forgery.get("field", "")) != "random":
			rolled.append(forgery)
			continue
		var taken_keys: Array = forgeries.map(_get_forgery_key)
		var released := FORGERY_RULES.keys().filter(
			func(key: String) -> bool:
				return not taken_keys.has(key) \
					and _rule_days.get(FORGERY_RULES[key], 999) <= GameData.current_day
		)
		if released.is_empty():
			continue
		var key: String = released[rng.randi_range(0, released.size() - 1)]
		var parts := key.split(":")
		var picked := {"field": parts[0]}
		if parts.size() > 1:
			picked["mode"] = parts[1]
		rolled.append(picked)
	return rolled

## "<field>:<mode>", or just the field for the forgeries that have a single mode
func _get_forgery_key(forgery: Dictionary) -> String:
	var field := str(forgery.get("field", ""))
	var mode := str(forgery.get("mode", DEFAULT_MODES.get(field, "")))
	return field if mode.is_empty() else "%s:%s" % [field, mode]

func _get_faces(faces: String, printed: Dictionary, registered: Dictionary) -> Array:
	match faces:
		"printed":
			return [printed]
		"bank":
			return [registered]
	return [printed, registered]

## Writes a forged value on a face. A forged bank carries its code along with its name
func _set_field(face: Dictionary, field: String, value: Variant) -> void:
	if field == "bank" and value is Dictionary:
		face["bank"] = str(value.get("name", ""))
		face["bank_code"] = str(value.get("code", ""))
		return
	if field == "bank" and _find_bank_by_name(str(value)).size() > 0:
		face["bank_code"] = str(_find_bank_by_name(str(value)).get("code", ""))
	face[field] = float(value) if field == "value" else str(value)

## Makes up the forged value of a field, different from the true one
func _forge_value(key: String, truth: Dictionary, rng: RandomNumberGenerator) -> Variant:
	match key:
		"payee:lookalike":
			return _make_lookalike(str(truth["payee"]), rng)
		"payee:other":
			return _pick(_forgery_pools.get("payee", []), str(truth["payee"]), rng)
		"cnpj":
			return _change_digits(str(truth["cnpj"]), 2, rng)
		"agency":
			var agency := str(truth["agency"])
			while agency == str(truth["agency"]):
				agency = "%04d-%d" % [rng.randi_range(100, 9999), rng.randi_range(0, 9)]
			return agency
		"bank":
			var outside: Array = []
			for bank_id in _forgery_pools.get("bank", _banks.keys()):
				var bank: Dictionary = _banks.get(bank_id, {})
				if not bank.is_empty() and not _accepted_banks.has(bank["name"]) \
						and bank["name"] != truth["bank"]:
					outside.append(bank)
			if outside.is_empty():
				push_error("No bank left to forge a boleto with")
				return {"name": truth["bank"], "code": truth["bank_code"]}
			return outside[rng.randi_range(0, outside.size() - 1)]
		"value":
			var value := float(truth["value"])
			return value * 10.0 if rng.randf() < 0.5 else value + rng.randi_range(3, 9) * 100.0
		"reason":
			return _pick(_forgery_pools.get("reason", []), str(truth["reason"]), rng)
	return null

## A name copied badly: a letter swapped for a look-alike digit, doubled, swapped with the next one
## or left out
func _make_lookalike(name: String, rng: RandomNumberGenerator) -> String:
	var letter_positions: Array = []
	for index in name.length():
		if name[index].to_lower() != name[index].to_upper():
			letter_positions.append(index)
	if letter_positions.is_empty():
		return name + "."

	for attempt in 10:
		var index: int = letter_positions[rng.randi_range(0, letter_positions.size() - 1)]
		var letter := name[index]
		var lookalike := name
		match rng.randi_range(0, 3):
			0:
				if not LOOKALIKE_DIGITS.has(letter.to_lower()):
					continue
				lookalike = name.substr(0, index) + LOOKALIKE_DIGITS[letter.to_lower()] \
					+ name.substr(index + 1)
			1:
				lookalike = name.insert(index, letter)
			2:
				if index + 1 >= name.length() or name[index + 1] == letter or name[index + 1] == " ":
					continue
				lookalike = name.substr(0, index) + name[index + 1] + letter + name.substr(index + 2)
			3:
				if letter_positions.size() <= 4:
					continue
				lookalike = name.substr(0, index) + name.substr(index + 1)
		if lookalike != name:
			return lookalike
	# Doubling a letter always works
	var last: int = letter_positions.back()
	return name.insert(last, name[last])

## Swaps some digits of a number for others, keeping its punctuation
func _change_digits(number: String, amount: int, rng: RandomNumberGenerator) -> String:
	var digit_positions: Array = []
	for index in number.length():
		if number[index].is_valid_int():
			digit_positions.append(index)
	if digit_positions.is_empty():
		return number + "0"

	var changed := number
	for change in amount:
		var index: int = digit_positions[rng.randi_range(0, digit_positions.size() - 1)]
		var digit := int(changed[index])
		changed = changed.substr(0, index) + str((digit + rng.randi_range(1, 9)) % 10) \
			+ changed.substr(index + 1)
	return changed

func _pick(options: Array, avoid: String, rng: RandomNumberGenerator) -> String:
	var others := options.filter(func(option) -> bool: return str(option) != avoid)
	if others.is_empty():
		push_error("No forged value left to pick besides: %s" % avoid)
		return avoid
	return str(others[rng.randi_range(0, others.size() - 1)])

func _find_bank_by_name(bank_name: String) -> Dictionary:
	for bank in _banks.values():
		if bank.get("name", "") == bank_name:
			return bank
	return {}

## A code in the pattern of the company: 6 digits, given to no one else
func _make_code(rng: RandomNumberGenerator) -> String:
	var code := ""
	while code.is_empty() or _taken_codes.has(code):
		code = "%06d" % rng.randi_range(0, 999999)
	_taken_codes[code] = true
	return code

## A code out of the pattern: 5 or 7 digits, or the letter O in place of a zero
func _make_forged_code(rng: RandomNumberGenerator) -> String:
	var code := ""
	while code.is_empty() or _taken_codes.has(code):
		match rng.randi_range(0, 2):
			0:
				code = "%05d" % rng.randi_range(0, 99999)
			1:
				code = "%07d" % rng.randi_range(0, 9999999)
			2:
				var digits := "%06d" % rng.randi_range(0, 999999)
				var index := rng.randi_range(1, 5)
				code = digits.substr(0, index) + "O" + digits.substr(index + 1)
	_taken_codes[code] = true
	return code

## The discrepancy a forgery adds to its event, pointed at on the faces it shows on
func _make_discrepancy(boleto_id: String, code: String, forgery: Dictionary) -> Dictionary:
	var field: String = forgery["field"]
	var faces: String = "both" if field == "code" else forgery["faces"]
	var places: Array = []
	if faces != "bank":
		places.append({"source": "boleto", "boleto_id": boleto_id, "section": BOLETO_SECTIONS[field]})
	if faces != "printed":
		places.append({"source": "bank", "payment_code": code, "section": BANK_SECTIONS[field]})
	return {
		"id": "boleto_%s" % forgery["key"].replace(":", "_"),
		"rule": FORGERY_RULES[forgery["key"]],
		"found_at": places,
	}

## Adds the discrepancies of a boleto to its event, into the one of the same rule when there is one
func _merge_discrepancies(event: Dictionary, discrepancies: Array) -> void:
	if not event.has("discrepancies"):
		event["discrepancies"] = []
	for discrepancy in discrepancies:
		var same_rule: Dictionary = {}
		for existing in event["discrepancies"]:
			if existing.get("rule", "") == discrepancy["rule"]:
				same_rule = existing
				break
		if same_rule.is_empty():
			event["discrepancies"].append(discrepancy.duplicate(true))
			continue
		if not same_rule.has("found_at"):
			same_rule["found_at"] = []
		for place in discrepancy["found_at"]:
			if not same_rule["found_at"].has(place):
				same_rule["found_at"].append(place.duplicate())

## Boletos are due on the day they arrive, "Quinta, 14 de março"
func _get_due_date() -> String:
	var date_dict := GameData.get_current_date_dict()
	return "%s, %d de %s" % [
		GameData.weekday_name(date_dict), int(date_dict.get("day", 1)), GameData.month_name(date_dict)
	]
#endregion MAKING
