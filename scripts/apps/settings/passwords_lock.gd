extends Control

## Emitted when the player asks to go change the expired password
signal password_change_requested()

#region CHILDREN NODES REFERENCES
@export var title_label: Label
@export var message_label: Label
@export var change_password_button: Button
#endregion

var gated_app: GameData.App

func _ready() -> void:
	change_password_button.pressed.connect(password_change_requested.emit)

## Sets up the PasswordsLock UI with the provided data, initializing the gated app
## and telling the player where its password is changed
func setup(data: Dictionary) -> void:
	gated_app = int(data["GatedApp"]) as GameData.App

	var app_data: Dictionary = GameData.apps_data.get(gated_app, {})
	var app_name: String = app_data.get(
		"name", GameData.apps_name_reverse.get(gated_app, "Aplicativo")
	)

	title_label.text = "%s bloqueado" % app_name
	message_label.text = (
		"Por segurança, a senha do %s precisa ser trocada todos os dias. Troque a senha no"
		+ " Gerenciador de Senhas das Configurações para desbloquear o aplicativo."
	) % app_name
