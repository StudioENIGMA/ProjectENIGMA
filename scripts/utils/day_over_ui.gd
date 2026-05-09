extends Control

signal day_over_clicked()

const MIN_RP_DAY = [10,75,85,95,120,125,140]
const EVENT_DESCRIPTION_SCENE = preload("res://scenes/event_description.tscn")
const TYPE_TO_RP = {
	"random-task": 15,
	"main-task": 20,
	"scam": -10,
}

@export var next_day_button:Button
@export var events_container: VBoxContainer
@export var reputation_points_label: Label
@export var result_rich_text: RichTextLabel

func show_day_over() -> void:
	for child in events_container.get_children():
		child.queue_free()

	for event in GameData.events_log:
		var event_instance = EVENT_DESCRIPTION_SCENE.instantiate()

		var event_rp = TYPE_TO_RP.get(event.get("type", ""), 0)
		event_instance.setup(event.get("description", ""), event_rp)
		events_container.add_child(event_instance)

	reputation_points_label.text = "%d/%d" % [GameData.daily_reputation_points, MIN_RP_DAY[GameData.current_day]]

	result_rich_text.text = "APROVADO"
	result_rich_text.add_theme_color_override("default_color", Color("#44cfb2"))
	next_day_button.text = "Iniciar Dia " + str(GameData.current_day + 1)
	next_day_button.pressed.connect(_on_next_day_button_pressed)
	self.show()

func hide_day_over() -> void:
	self.visible = false

func _on_next_day_button_pressed() -> void:
	GameData.current_day += 1
	GameData.total_reputation_points += GameData.daily_reputation_points

	# Select random apps to receive updates (50% chance for each downloaded app)
	GameData.apps_with_available_updates.clear()
	for app in GameData.downloaded_apps:
		if randi() % 100 < 50: # 50% chance
			GameData.apps_with_available_updates.append(app)

	GameData.save_game()
	day_over_clicked.emit()

func _on_previous_day_button_pressed() -> void:
	GameData.reset_to_defaults()
	GameData.load_game()
	get_tree().change_scene_to_file("res://scenes/game_screen.tscn")
