extends Control

#region SIGNALS
signal message_answered(answer_id:int)
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var base_app:Control
@export var day_over_ui:Control
@export var notifications_control:Control
@export var notification_center:Control
@export var apps_ui:Control
@export var pause_game_ui:Control
#endregion CHILDREN NODES REFERENCES

#region INITIALIZATION
## Setup signal connections to redirect events to each app
func _ready() -> void:
  base_app.messages_app_chat.request_message_notification.connect(
		notifications_control.add_notification_to_queue
  )
  base_app.bank_payment_info.request_transaction_notification.connect(
		notifications_control.add_notification_to_queue
  )
  base_app.email_app_home.request_email_notification.connect(
		notifications_control.add_notification_to_queue
  )

  base_app.messages_app_chat.message_answered.connect(message_answered.emit)
  base_app.apk_installation_requested.connect(apps_ui.on_app_installed)
  base_app.store_app.app_installed.connect(apps_ui.on_app_installed)
  base_app.fake_store_app.app_installed.connect(apps_ui.on_app_installed)

  notifications_control.notification_added.connect(apps_ui.on_notification_added)
  base_app.main_app_opened.connect(apps_ui.on_app_opened)

  # Notification center keeps every notification until it is cleared or its app is opened
  notifications_control.notification_posted.connect(notification_center.add_notification)
  notifications_control.notification_tapped.connect(base_app.open_app_from_notification)
  notification_center.app_open_requested.connect(base_app.open_app_from_notification)
  base_app.main_app_opened.connect(notification_center.on_app_opened)
  # Hack minigames hide the banners, the center must not be pulled over them either
  notifications_control.visibility_changed.connect(
    func(): notification_center.set_enabled(notifications_control.is_visible_in_tree())
  )
#endregion INITIALIZATION
