extends Control

const AUTHENTICATOR_INSTANCE_SCENE = preload(
	"res://scenes/apps/authenticator/authenticator_instance.tscn"
)

#region CHILDREN NODES REFERENCES
@export var authenticators_container: VBoxContainer
#endregion CHILDREN NODES REFERENCES

func _ready() -> void:
	# Instantiate an authenticator for bank app
	var bank_authenticator_instance = AUTHENTICATOR_INSTANCE_SCENE.instantiate()
	authenticators_container.add_child(bank_authenticator_instance)
	bank_authenticator_instance.setup(GameData.App.BANK)

## Updates the validity timer for all children authenticator instances
func update_codes_validity() -> void:
	for child in authenticators_container.get_children():
		child.update_codes_validity()
