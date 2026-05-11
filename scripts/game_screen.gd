## Respecting "signal up, command down" principle, this node
## serves as a container for the main game screen components and
## facilitates communication between them

extends Control

#region CHILDREN NODES REFERENCES
@export var ui: Control
@export var event_handler: Node2D
@export var story_director: Node2D
@export var progressive_blur: ColorRect
#endregion CHILDREN NODES REFERENCES

#region INITIALIZATION
## Setup signal connections to redirect events to each app
func _ready() -> void:
  # Relevant children nodes references
  var answers_director = story_director.messages_director.answers_director
  var emails_director = story_director.emails_director
  var browser_director = story_director.browser_director
  var bank_director = story_director.bank_director
  var messages_app_home = ui.base_app.messages_app_home
  var messages_app_chat = ui.base_app.messages_app_chat

  # EVENT HANDLER
  # Event Handler day end Timer to UI
  event_handler.day_ended.connect(ui.day_over_ui.show_day_over)
  event_handler.day_ended.connect(ui.base_app.close_all_apps)
  # Event Handler new day start to UI
  event_handler.start_new_day.connect(ui.day_over_ui.hide_day_over)
  event_handler.start_new_day.connect(answers_director.clear_pending_answers)
  # Event Handler takes care of clock ticks, warn those who need to know
  event_handler.clock_tick.connect(_on_clock_tick)
  # Event handler hack event to UI
  event_handler.hack_handler.open_hack_minigame.connect(ui.base_app.start_hack_minigame)
  event_handler.hack_handler.send_hack_notification.connect(
	ui.notifications_control.send_hack_notification
  )
  event_handler.set_shop_by_date()

  # STORY DIRECTOR
  # Story Director new npc message to UI
  story_director.messages_director.npc_message_sent.connect(messages_app_home.on_send_message)
  story_director.messages_director.npc_message_sent.connect(messages_app_chat.on_send_message)
  story_director.messages_director.npc_message_created.connect(messages_app_chat.on_create_message)
  # Story Director request answer option to UI
  answers_director.request_answer_option.connect(
	messages_app_chat.on_request_answer_option
  )
  # Answers Director blocked someone, notify the UI to update the messages accordingly
  answers_director.delete_conversation.connect(messages_app_home.on_delete_conversation)
  answers_director.delete_conversation.connect(ui.base_app.on_delete_conversation)
  # Story Director new email to UI
  emails_director.email_received.connect(ui.base_app.email_app_home.on_receive_email)
  #Story Director Browser
  story_director.news_ready.connect(ui.base_app.browser_app._on_news_received)
  story_director.update_news.connect(ui.base_app.browser_app.update_news)
  #Story Director Reviews Website
  ui.base_app.browser_app.open_site_requested.connect(
	browser_director._on_open_website_requested
  )
  browser_director.open_website.connect(
	ui.base_app._on_app_opened
  )
  #Story Director Bank
  ui.base_app.bank_payment_info.transaction_completed.connect(
	bank_director._on_transaction_completed
  )
  bank_director.send_codes_dict.connect(
	ui.base_app.bank_payment_info._on_codes_dict_updated, ConnectFlags.CONNECT_DEFERRED
  )
  ui.base_app.browser_app_shop_payment_screen.create_code.connect(
   bank_director._on_code_created
  )
  bank_director.send_new_code.connect(
	ui.base_app.browser_app_shop_payment_screen._on_code_received
  )

  # UI
  # UI message answered to Story Director
  ui.message_answered.connect(answers_director.on_message_answered)
  # UI browser news requested
  ui.base_app.browser_app.request_news.connect(story_director._on_browser_request_news)
  # UI hacked minigame ended to event handler
  ui.base_app.fast_typing.hack_concluded.connect(event_handler.hack_handler.on_hack_concluded)
  ui.base_app.line_connect.hack_concluded.connect(event_handler.hack_handler.on_hack_concluded)
  ui.base_app.maze.hack_concluded.connect(event_handler.hack_handler.on_hack_concluded)
  # UI asking for minigame
  ui.base_app.virus_scanner.minigame_request.connect(event_handler.hack_handler.open_minigame)
  # UI start new day
  ui.day_over_ui.day_over_clicked.connect(event_handler.reset_data_for_new_day)
  ui.day_over_ui.day_over_clicked.connect(story_director.reload_and_setup_today)
  ui.day_over_ui.day_over_clicked.connect(ui.base_app.messages_app_home._on_start_new_day)
  # UI game paused
  ui.base_app.pause_game_requested.connect(ui.pause_game_ui.show_pause_menu)
#endregion INITIALIZATION

## Handles the clock tick event from the event handler
##
## current_minutes: The current in-game minutes
func _on_clock_tick(current_minutes: int) -> void:
  story_director.on_clock_tick(current_minutes)

  # Authenticator validity update
  ui.base_app.authenticator_app.update_codes_validity()

  # Minigame update timer
  ui.base_app.fast_typing.minigame_timer.update_timer()
  ui.base_app.line_connect.minigame_timer.update_timer()
  ui.base_app.maze.minigame_timer.update_timer()

  # Update blur for all the game
  _update_blur()

func _update_blur() -> void:
  # Max blur scale is 10
  var blur_scale:float = min(GameData.number_of_viruses / 50.0, 6.0)

  var blur_material:ShaderMaterial = progressive_blur.material
  blur_material.set_shader_parameter("blur_scale", blur_scale)
