## Respecting "signal up, command down" principle, this node
## serves as a container for the main game screen components and
## facilitates communication between them

extends Node2D

#region CHILDREN NODES REFERENCES
@export var ui: Control
@export var event_handler: Node2D
@export var story_director: Node2D
#endregion CHILDREN NODES REFERENCES

#region INITIALIZATION
## Setup signal connections to redirect events to each app
func _ready() -> void:
  # Relevant children nodes references
  var answers_director = story_director.messages_director.answers_director
  var npc_messages_director = story_director.messages_director.npc_messages_director
  var messages_app_home = ui.base_app.messages_app_home
  var messages_app_chat = ui.base_app.messages_app_chat

  # EVENT HANDLER
  # Event Handler day end Timer to UI
  event_handler.day_ended.connect(ui.day_over_ui.show_day_over)
  # Event Handler new day start to UI
  event_handler.start_new_day.connect(ui.day_over_ui.hide_day_over)
  # Event Handler takes care of clock ticks, warn those who need to know
  event_handler.clock_tick.connect(_on_clock_tick)

  # STORY DIRECTOR
  # Story Director new npc message to UI
  npc_messages_director.npc_message_created.connect(messages_app_home.on_create_message)
  npc_messages_director.npc_message_created.connect(messages_app_chat.on_create_message)
  # Story Director request answer option to UI
  answers_director.request_answer_option.connect(
	messages_app_chat.on_request_answer_option
  )

  # UI
  # UI message answered to Story Director
  ui.message_answered.connect(answers_director.on_message_answered)

#endregion INITIALIZATION

## Handles the clock tick event from the event handler
##
## current_minutes: The current in-game minutes
func _on_clock_tick(current_minutes: int) -> void:
  story_director.on_clock_tick(current_minutes)
