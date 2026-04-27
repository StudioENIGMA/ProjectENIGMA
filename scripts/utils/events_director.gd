extends Node

#region CONSTANTS
const TYPE_TO_RP = {
	"random-task": 15,
	"main-task": 20,
	"scam": -10,
}
#endregion CONSTANTS

#region STATES
var events_dict: Dictionary
var events_to_check: Array[String]
#endregion STATES

#region SETUP
func setup_from_json_file(events_json: Variant) -> void:
	assert(typeof(events_json) == TYPE_ARRAY)
	events_dict = events_json
	events_to_check = []
#endregion SETUP

#region FUNCTIONS
func _on_event_initiated(event_id: String) -> void:
	if not events_to_check.has(event_id) and not event_id == "":
		events_to_check.append(event_id)

func _on_clock_tick() -> void:
	for event_id in events_to_check:
		var event = events_dict.get(event_id, null)
		var is_event_completed: bool = evaluate_requirements(event)
		if is_event_completed:
			GameData.events_log.append(event)

			var event_type = event.get("type", "")
			var reputation_points = TYPE_TO_RP.get(event_type, 0)
			GameData.daily_reputation_points += reputation_points

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
		if flag == "purchase":
			var items = requirement.get("items", [])
			for item in items:
				var item_id = item.get("item_id", "")
				var quantity = int(item.get("quantity", 0))
				var store_id = item.get("store", "")
				var store = GameData.apps_name.get(store_id, null)

				if not GameData.purchased_items.has(store):
					return false
				var store_purchases = GameData.purchased_items[store]
				if not store_purchases.has(item_id):
					return false
				if store_purchases[item_id] < quantity:
					return false

				return true
		if flag == "payment":
			var payment_id = requirement.get("payment_id", "")
			return GameData.completed_payments.has(payment_id)
	return false
#endregion FUNCTIONS
