extends VBoxContainer

@export var not_found_label: Label
@export var error_label: Label

func setup(code: String) -> void:
	var label_text = "O código digitado \"%s\" não foi encontrado." % code;
	not_found_label.text = label_text;
	error_label.text = "Confira se a informação está correta!"

## Tells the payment was refused because it belongs to a scam the player reported
func setup_blocked(code: String) -> void:
	not_found_label.text = "O pagamento \"%s\" foi bloqueado." % code
	error_label.text = "Você denunciou esse golpe."
