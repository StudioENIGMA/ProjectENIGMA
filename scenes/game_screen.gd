## Respecting "signal up, command down" principle, this node
## serves as a container for the main game screen components and
## facilitates communication between them

extends Node2D

@export var ui: Control
@export var event_handler: Node2D
@export var story_director: Node2D

func _ready() -> void:
  # Event Handler day end Timer to UI
  event_handler.day_ended.connect(ui.day_over_ui.show_day_over)

  # Event Handler new day start to UI
  event_handler.start_new_day.connect(ui.day_over_ui.hide_day_over)

  # Story Director new npc message to UI
  story_director.npc_message_created.connect(ui.base_app.messages_app_home.on_create_message)
  story_director.npc_message_created.connect(ui.base_app.messages_app_chat.on_create_message)

  # Story Director request answer option to UI
  story_director.request_answer_option.connect(
    ui.base_app.messages_app_chat.on_request_answer_option
  )

  # Event Handler takes care of clock ticks, warn those who need to know
  event_handler.clock_tick.connect(_on_clock_tick)

func _on_clock_tick(current_minutes: int) -> void:
  story_director.on_clock_tick(current_minutes)