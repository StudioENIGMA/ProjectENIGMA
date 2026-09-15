extends Control

signal day_over_clicked()
signal end_game()

const MIN_RP_DAY = [10, 55, 60, 70, 75, 80, 85]
const EVENT_DESCRIPTION_SCENE = preload("res://scenes/event_description.tscn")
const CREDIT_ROLL_PATH = "res://scenes/rolling_credits.tscn"
const TYPE_TO_RP = {
	"conversation": 10,
	"random-task": 15,
	"main-task": 20,
	"scam": -10,
}

const SUCCESS_COLOR = Color(0.30980393, 0.79607844, 0.68235296)
const FAILURE_COLOR = Color(0.92156863, 0.039215688, 0.27058825)
## Tallest the events list grows before it starts scrolling
const MAX_EVENTS_HEIGHT = 300.0

@export var next_day_button:Button
@export var events_container: VBoxContainer
@export var reputation_points_label: Label
@export var result_label: Label
@export var events_scroll: ScrollContainer

func show_day_over() -> void:
	if GameData.current_day == 7:
		handle_credit_scene()
		return

	for child in events_container.get_children():
		child.queue_free()

	for event in GameData.events_log:
		var event_instance = EVENT_DESCRIPTION_SCENE.instantiate()

		var event_rp = TYPE_TO_RP.get(event.get("type", ""), 0)
		event_instance.setup(event.get("description", ""), event_rp)
		events_container.add_child(event_instance)

	reputation_points_label.text = "%d/%d" % [GameData.daily_reputation_points, MIN_RP_DAY[GameData.current_day]]

	for connection in next_day_button.pressed.get_connections():
		next_day_button.pressed.disconnect(connection["callable"])

	if GameData.daily_reputation_points >= MIN_RP_DAY[GameData.current_day]:
		result_label.text = "APROVADO"
		result_label.add_theme_color_override("font_color", SUCCESS_COLOR)
		reputation_points_label.add_theme_color_override("font_color", SUCCESS_COLOR)
		if GameData.current_day + 1 == 7:
			next_day_button.text = "Continuar"
			next_day_button.pressed.connect(_on_final_day_button_pressed)
		else:
			next_day_button.text = "Iniciar Dia " + str(GameData.current_day + 1)
			next_day_button.pressed.connect(_on_next_day_button_pressed)
	else:
		result_label.text = "REPROVADO"
		result_label.add_theme_color_override("font_color", FAILURE_COLOR)
		reputation_points_label.add_theme_color_override("font_color", FAILURE_COLOR)
		next_day_button.text = "Recomeçar Dia " + str(GameData.current_day)
		next_day_button.pressed.connect(_on_previous_day_button_pressed)
	self.show()
	_fit_events_scroll()

## Sizes the events list to its rows (capped), so the summary stays one compact centered block
func _fit_events_scroll() -> void:
	# Freed rows linger until the end of the frame, so measure after it
	await get_tree().process_frame
	var rows_height = events_container.get_combined_minimum_size().y
	events_scroll.custom_minimum_size.y = min(rows_height, MAX_EVENTS_HEIGHT)

func handle_credit_scene() -> void:
	end_game.emit()
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file(CREDIT_ROLL_PATH)

func hide_day_over() -> void:
	self.visible = false

func _on_final_day_button_pressed() -> void:
	GameData.current_day += 1
	GameData.total_reputation_points += GameData.daily_reputation_points
	GameData.starting_hours_minutes = 1080
	GameData.max_hours_minutes = 1230
	day_over_clicked.emit()

func _on_next_day_button_pressed() -> void:
	GameData.current_day += 1
	GameData.total_reputation_points += GameData.daily_reputation_points

	if GameData.current_day == 1:
		GameData.max_hours_minutes = 840
	elif GameData.current_day == 2:
		GameData.max_hours_minutes = 960
	else:
		GameData.max_hours_minutes = 1080

	# Select random apps to receive updates (50% chance for each downloaded app)
	GameData.apps_with_available_updates.clear()
	for app in GameData.downloaded_apps:
		if randi() % 100 < 50: # 50% chance
			GameData.apps_with_available_updates.append(app)

	day_over_clicked.emit()
	GameData.save_game()

func _on_previous_day_button_pressed() -> void:
	GameData.reset_to_defaults()
	GameData.load_game()
	get_tree().change_scene_to_file("res://scenes/game_screen.tscn")
