## Base application script that handles common functionality for all apps
## Buttons from the top bar should be handled here

extends Node2D

## Reference to the close app button in the top bar
@export var close_app_button:TextureButton
## Reference to the return app button in the top bar
@export var back_button:TextureButton

## Reference to the desktop UI node (to manage app opening/closing)
@export var desktop_ui:Control

## Reference to the messaging app node
@export var messages_app:Control

var open_apps_count:int = 0

func _ready() -> void:
  desktop_ui.app_opened.connect(_on_app_opened)
  desktop_ui.app_closed.connect(_on_app_closed)

func _on_app_opened(app_name:String) -> void:
  # Show top bar when an app is opened
  self.visible = true
  open_apps_count += 1

  # Get specific app that should be opened
  var specific_app:Control
  match app_name:
    "Messages":
      specific_app = messages_app
    _:
      pass

  # Pull specific app to front and make it visible
  specific_app.visible = true
  self.move_child(specific_app, self.get_child_count() - 1)

func _on_app_closed(app_name:String) -> void:
  # Hide top bar when no apps are open
  open_apps_count -= 1
  if open_apps_count <= 0:
    self.visible = false

  # Get specific app that should be closed
  match app_name:
    "Messages":
      messages_app.visible = false
    _:
      pass
