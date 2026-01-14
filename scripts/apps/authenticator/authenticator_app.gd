extends VBoxContainer

const AUTHENTICATOR_INSTANCE_SCENE = preload(
  "res://scenes/apps/authenticator/authenticator_instance.tscn"
)

func _ready() -> void:
  # Instantiate an authenticator for bank app
  var bank_authenticator_instance = AUTHENTICATOR_INSTANCE_SCENE.instantiate()
  bank_authenticator_instance.setup(GameData.App.BANK)
  add_child(bank_authenticator_instance)

## Updates the validity timer for all children authenticator instances
func update_codes_validity() -> void:
  if get_child_count() == 0:
    return

  for child in get_children():
    child.update_codes_validity()