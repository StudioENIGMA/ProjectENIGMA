extends CanvasLayer
## ======================================================
##                     DEBUG CODE
## ======================================================
## Fires any single event of data/events/events.json on demand, to test the tasks one by one
## without playing through the days. Added by the StoryDirector in debug builds only.
##
## F9 shows or hides the list. "Disparar" delivers the chat or email of the event right away,
## through the StoryDirector, skipping its day, its requirements and the chat in progress.
## "Completar" sets the flags the event requires, so the EventsDirector completes it on the next
## clock tick. "Pular p/ dia" starts the given day as the morning paper would.
## tools/task_checklist/task_checklist.html fires an event the same way, see CHECKLIST BRIDGE.

const StoryDirector := preload("res://scripts/utils/story_director.gd")
const TOGGLE_KEY := KEY_F9
const BRIDGE_PORT := 8765

## Every event that can be fired: "event_id", "type", "description", "day" (-1 when unknown),
## "random" (from the random pools) and "payload" (the schedule entry to deliver, empty when no
## chat or email delivers the event)
var catalog: Array[Dictionary] = []

var story: Node
var filter_edit: LineEdit
var item_list: ItemList
var day_spin: SpinBox
var status_label: Label
var server := TCPServer.new()
var peers: Array[StreamPeerTCP] = []


func _ready() -> void:
	story = get_parent()
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	if server.listen(BRIDGE_PORT, "127.0.0.1") != OK:
		push_warning("[DebugTaskLauncher] porta %d ocupada, checklist não dispara" % BRIDGE_PORT)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != TOGGLE_KEY:
		return
	visible = not visible
	if visible:
		# Built on opening: the directors are set up by then, and again on every new day
		_build_catalog()
		_refresh_list()
		day_spin.value = GameData.current_day
		filter_edit.grab_focus()
	get_viewport().set_input_as_handled()


#region CATALOG
## Gathers every event and what delivers it: the random pools of every day, the conversations
## and the emails of the story, and lastly the events nothing delivers
func _build_catalog() -> void:
	catalog.clear()
	var events: Dictionary = story.events_director.events_dict
	var seen: Dictionary = {}

	for day_path in story._list_subdirectory_paths(story.random_dir_path):
		var day := int(day_path.get_file().trim_prefix("day_"))
		for pool in ["tasks", "scams"]:
			for root in story._load_json_roots_from_directory(day_path.path_join(pool)):
				for event in root:
					var event_id := str(event.get("email_id", event.get("branch", "")))
					var payload := {"event_id": event_id, "requires": []}
					if event.has("email_id"):
						payload.merge({"thread_id": event["thread_id"], "email_id": event_id})
					else:
						payload.merge({
							"conversation_id": event["conversation_id"], "branch": event_id, "index": 0
						})
					_add(seen, events, event_id, day, true, payload)

	for conversation_id in story.messages_director.conversations_by_id:
		var conversation: Dictionary = story.messages_director.conversations_by_id[conversation_id]
		var day_by_branch: Dictionary = {}
		for entry in conversation.get("entry_points", []):
			day_by_branch[str(entry.get("branch", ""))] = int(entry.get("day", -1))
			if str(entry.get("event_id", "")) != "":
				_add(seen, events, str(entry["event_id"]), int(entry.get("day", -1)), false, {
					"conversation_id": conversation_id, "branch": str(entry["branch"]), "index": 0,
					"event_id": str(entry["event_id"]), "requires": [],
				})
		var branches: Dictionary = conversation.get("branches", {})
		for branch in branches:
			var nodes: Array = branches[branch]
			for index in nodes.size():
				var event_id := str(nodes[index].get("event_id", ""))
				if event_id == "":
					continue
				# The branch is delivered from its start, the event comes with its own message
				_add(seen, events, event_id, day_by_branch.get(branch, -1), false, {
					"conversation_id": conversation_id, "branch": branch, "index": 0,
					"event_id": event_id if index == 0 else "", "requires": [],
				})

	for thread_id in story.emails_director.emails_by_id:
		for email in story.emails_director.emails_by_id[thread_id]:
			var event_id := str(email.get("event_id", ""))
			if event_id != "":
				_add(seen, events, event_id, int(email.get("day", -1)), false, {
					"thread_id": thread_id, "email_id": str(email["email_id"]),
					"event_id": event_id, "requires": [],
				})

	for event_id in events:
		_add(seen, events, event_id, -1, false, {})

	# By day (no day last), the story of the day before its random events, then by id
	catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var day_a: int = a["day"] if a["day"] >= 0 else 99
		var day_b: int = b["day"] if b["day"] >= 0 else 99
		if day_a != day_b:
			return day_a < day_b
		if a["random"] != b["random"]:
			return b["random"]
		# task2 before task10
		return str(a["event_id"]).naturalnocasecmp_to(b["event_id"]) < 0
	)

## Adds an event to the catalog, the first thing found delivering it wins
func _add(
	seen: Dictionary, events: Dictionary, event_id: String, day: int, random: bool,
	payload: Dictionary
) -> void:
	# Answers like "block_and_report" carry an event_id that is not an event
	if seen.has(event_id) or not events.has(event_id):
		return
	seen[event_id] = true
	var event: Dictionary = events[event_id]
	catalog.append({
		"event_id": event_id,
		"type": str(event.get("type", "?")),
		"description": str(event.get("description", "")),
		"day": day,
		"random": random,
		"payload": payload,
	})
#endregion CATALOG

#region ACTIONS
## Delivers the event selected right away, as the StoryDirector would once its turn came
func _on_fire_pressed() -> void:
	var entry := _get_selected()
	if not entry.is_empty():
		_fire(entry)

func _fire(entry: Dictionary) -> void:
	var event_id: String = entry["event_id"]
	var now := int(GameData.hours_minutes)
	var payload: Dictionary = entry["payload"].duplicate()
	if payload.is_empty():
		story.events_director._on_event_initiated(event_id)
		_set_status("%s: nada o entrega, só registrado no EventsDirector" % event_id)
		return

	payload["due_at"] = now
	var channel := "emails" if payload.has("thread_id") else "messages"
	var chat_id := str(payload.get("thread_id", payload.get("conversation_id", "")))
	if entry["random"]:
		# As RandomnessDirector.schedule_next_event() does, so it is not picked again today
		story.randomness_director.senders_today[chat_id] = true
		if not GameData.random_events_history.has(event_id):
			GameData.random_events_history.append(event_id)

	# Taking the turn of the chat in progress, if any, whose next messages wait in the queue
	story._deliver({
		"channel": channel,
		"owner": story._get_owner(channel, chat_id),
		"lane": StoryDirector.Lane.RANDOM if entry["random"] else StoryDirector.Lane.MAIN,
		"continues": false,
		"due_at": now,
		"seq": -1,
		"requires": [],
		"payload": payload,
	}, now)
	_set_status("Disparado: %s (%s)" % [event_id, chat_id])

## Sets every flag the event selected requires, the EventsDirector completes it on the next tick
## (for a scam that is falling for it)
func _on_complete_pressed() -> void:
	var entry := _get_selected()
	if entry.is_empty():
		return
	var event_id: String = entry["event_id"]
	story.events_director._on_event_initiated(event_id)

	for requirement in story.events_director.events_dict[event_id].get("requires", []):
		match str(requirement.get("flag", "")):
			"option":
				# As if picked in the chat of the event, "" (any chat) when it has none
				GameData.options_chose[requirement.get("choice", "")] = str(
					entry["payload"].get("conversation_id", "")
				)
			"payment":
				GameData.completed_payments.append(requirement.get("payment_id", ""))
			"payment_multitype":
				GameData.completed_payments.append_array(requirement.get("payment_array", []))
			"email_read":
				GameData.read_emails.append(requirement.get("email_id", ""))
			"app_installed":
				var app = GameData.apps_name.get(requirement.get("app_id", ""), null)
				if app != null and not GameData.downloaded_apps.has(app):
					GameData.downloaded_apps.append(app)
			"purchase":
				for item in requirement.get("items", []):
					var stores = item.get("store", [])
					var store_name: String = stores if typeof(stores) == TYPE_STRING else stores[0]
					var store = GameData.shop_string_to_enum.get(store_name, null)
					var purchases: Dictionary = GameData.purchased_items.get(store, {})
					purchases[item.get("item_id")] = int(item.get("quantity", 1))
					GameData.purchased_items[store] = purchases
	_set_status("Requisitos de %s marcados, completa no próximo tick" % event_id)

## Starts the given day as the morning paper does once closed
func _on_jump_pressed() -> void:
	GameData.current_day = int(day_spin.value)
	# ponytail: a full workday on every day, DayOverUI sets the real end of each day
	GameData.max_hours_minutes = 1080
	story.ui.day_introduction_ui.day_started.emit()
	_build_catalog()
	_refresh_list()
	_set_status("Dia %d iniciado" % GameData.current_day)
#endregion ACTIONS

#region CHECKLIST BRIDGE
## The checklist sends GET /fire?id=<event_id> and shows the status answered
func _process(_delta: float) -> void:
	while server.is_connection_available():
		peers.append(server.take_connection())
	for peer: StreamPeerTCP in peers.duplicate():
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			peers.erase(peer)
			continue
		if peer.get_available_bytes() == 0:
			continue
		# ponytail: the whole request comes in one read, it is a single short GET line
		var path: String = peer.get_utf8_string(peer.get_available_bytes()).get_slice(" ", 1)
		_answer(peer, _fire_by_id(path.get_slice("id=", 1).get_slice("&", 0).uri_decode()))
		peers.erase(peer)

func _fire_by_id(event_id: String) -> String:
	_build_catalog()
	for entry in catalog:
		if entry["event_id"] == event_id:
			_fire(entry)
			return status_label.text
	_set_status("%s não está no catálogo" % event_id)
	return status_label.text

func _answer(peer: StreamPeerTCP, body: String) -> void:
	var bytes := body.to_utf8_buffer()
	var header := "HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
" 		+ "Content-Type: text/plain; charset=utf-8
Content-Length: %d
" % bytes.size() 		+ "Connection: close

"
	peer.put_data(header.to_utf8_buffer() + bytes)
	peer.disconnect_from_host()
#endregion CHECKLIST BRIDGE

#region UI
func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var column := VBoxContainer.new()
	panel.add_child(column)

	filter_edit = LineEdit.new()
	filter_edit.placeholder_text = "Filtrar (id, tipo, descrição, d3...)"
	filter_edit.text_changed.connect(func(_text: String) -> void: _refresh_list())
	column.add_child(filter_edit)

	item_list = ItemList.new()
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.item_activated.connect(func(_index: int) -> void: _on_fire_pressed())
	column.add_child(item_list)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	_add_button(buttons, "Disparar", _on_fire_pressed)
	_add_button(buttons, "Completar", _on_complete_pressed)

	var isolated_check := CheckBox.new()
	isolated_check.text = "Só tasks disparadas (sem história nem aleatórias)"
	isolated_check.button_pressed = story.debug_isolated
	isolated_check.toggled.connect(func(on: bool) -> void: story.debug_isolated = on)
	column.add_child(isolated_check)

	# Every instrument bus sends to Music, muting it silences all of the music
	var music_bus := AudioServer.get_bus_index("Music")
	var mute_check := CheckBox.new()
	mute_check.text = "Sem música"
	mute_check.button_pressed = AudioServer.is_bus_mute(music_bus)
	mute_check.toggled.connect(func(on: bool) -> void: AudioServer.set_bus_mute(music_bus, on))
	column.add_child(mute_check)

	var day_row := HBoxContainer.new()
	column.add_child(day_row)
	day_spin = SpinBox.new()
	day_spin.min_value = 0
	day_spin.max_value = 7
	day_row.add_child(day_spin)
	_add_button(day_row, "Pular p/ dia", _on_jump_pressed)
	_add_button(day_row, "Fechar (F9)", func() -> void: visible = false)

func _add_button(parent: Control, text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_pressed)
	parent.add_child(button)

## Lists the events of the catalog matching every word of the filter
func _refresh_list() -> void:
	item_list.clear()
	var words := Array(filter_edit.text.to_lower().split(" ", false))
	for index in catalog.size():
		var entry := catalog[index]
		var day := "d%d" % entry["day"] if entry["day"] >= 0 else "d?"
		# Only the id is shown, the filter still matches the day, type and description
		var details := "%s [%s] %s" % [day, entry["type"], entry["description"]]
		if entry["payload"].is_empty():
			details += " (sem entrega)"
		var lower := ("%s %s" % [entry["event_id"], details]).to_lower()
		if words.any(func(word: String) -> bool: return not lower.contains(word)):
			continue
		var item := item_list.add_item(entry["event_id"])
		item_list.set_item_tooltip(item, details)
		item_list.set_item_metadata(item, index)

func _get_selected() -> Dictionary:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		_set_status("Selecione um evento")
		return {}
	return catalog[int(item_list.get_item_metadata(selected[0]))]

func _set_status(text: String) -> void:
	status_label.text = text
	print("[DebugTaskLauncher] ", text)
#endregion UI
