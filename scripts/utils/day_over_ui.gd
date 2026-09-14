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
const SUCCESS_COLOR_ACTIVE = Color(0.27450982, 0.70980394, 0.6901961)
const FAILURE_COLOR = Color(0.92156863, 0.039215688, 0.27058825)
const FAILURE_COLOR_ACTIVE = Color(0.5686275, 0.101960786, 0.21960784)

@export var next_day_button:Button
@export var events_container: VBoxContainer
@export var reputation_points_label: Label
@export var result_label: Label
@export var result_badge: PanelContainer

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
		_style_badge(SUCCESS_COLOR)
		_style_button(SUCCESS_COLOR, SUCCESS_COLOR_ACTIVE)
		if GameData.current_day + 1 == 7:
			next_day_button.text = "Continuar"
			next_day_button.pressed.connect(_on_final_day_button_pressed)
		else:
			next_day_button.text = "Iniciar Dia " + str(GameData.current_day + 1)
			next_day_button.pressed.connect(_on_next_day_button_pressed)
	else:
		result_label.text = "REPROVADO"
		_style_badge(FAILURE_COLOR)
		_style_button(FAILURE_COLOR, FAILURE_COLOR_ACTIVE)
		next_day_button.text = "Recomeçar Dia " + str(GameData.current_day)
		next_day_button.pressed.connect(_on_previous_day_button_pressed)
	self.show()

func _style_badge(color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_right = 100
	style.corner_radius_bottom_left = 100
	result_badge.add_theme_stylebox_override("panel", style)

func _style_button(color: Color, active_color: Color) -> void:
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 100
	normal_style.corner_radius_top_right = 100
	normal_style.corner_radius_bottom_right = 100
	normal_style.corner_radius_bottom_left = 100

	var active_style = normal_style.duplicate()
	active_style.bg_color = active_color

	next_day_button.add_theme_stylebox_override("normal", normal_style)
	next_day_button.add_theme_stylebox_override("hover", active_style)
	next_day_button.add_theme_stylebox_override("pressed", active_style)

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
