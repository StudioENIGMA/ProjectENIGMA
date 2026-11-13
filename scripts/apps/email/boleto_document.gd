extends Control
## A boleto attached to an email, the way it is printed: the face the sender controls
##
## Shows the bank, the code, who receives the payment and how much it is. Each of those can be
## pointed at as a scam discrepancy, to be checked against the bank app (the face registered there,
## where the money really goes), the beneficiaries and banks listed in the Notes app and the email
## that sent it.

## Emitted when the player, inspecting, points at a part of the boleto as a scam discrepancy
##
## section: "source" ("boleto"), "section" ("boleto_bank", "boleto_code", "boleto_payee",
## "boleto_cnpj", "boleto_agency", "boleto_due", "boleto_value", "boleto_payer" or
## "boleto_reason"), "boleto_id" and "excerpt"
signal discrepancy_picked(section: Dictionary)

## Fields under the code, top to bottom: printed field, caption and section
const FIELDS := [
	["payee", "Beneficiário", "boleto_payee"],
	["cnpj", "CNPJ do beneficiário", "boleto_cnpj"],
	["agency", "Agência / código do beneficiário", "boleto_agency"],
	["due_date", "Vencimento", "boleto_due"],
	["value", "Valor do documento", "boleto_value"],
	["payer", "Pagador", "boleto_payer"],
	["reason", "Motivo", "boleto_reason"],
]
const FONT_SEMIBOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const FONT_REGULAR := preload("res://assets/fonts/IBMPlexSans-Regular.ttf")
const INK := Color(0.09019608, 0.10980392, 0.18039216)
const MUTED := Color(0.43137255, 0.44313726, 0.5019608)

@export var bank_label: Label
@export var bank_code_label: Label
@export var code_label: Label
@export var fields_column: VBoxContainer
@export var barcode: BoletoBarcode
@export var bank_target: DiscrepancyTarget
@export var code_target: DiscrepancyTarget

## Keeps the parts of the boleto that can be pointed at as a discrepancy in step
var _inspector := DiscrepancyInspector.new()


func _ready() -> void:
	_inspector.picked.connect(discrepancy_picked.emit) # Propagate signal to base app


## Fills the boleto with the face printed on the attachment
##
## attachment: The email attachment that opened it: "boleto_id", "code" and "printed" (the fields
## of the printed face, see BoletosDirector)
func setup(attachment: Dictionary) -> void:
	var boleto_id := str(attachment.get("boleto_id", ""))
	var code := str(attachment.get("code", ""))
	var printed: Dictionary = attachment.get("printed", {})

	for child in fields_column.get_children():
		fields_column.remove_child(child)
		child.queue_free()
	_inspector.forget_all()

	bank_label.text = str(printed.get("bank", "—"))
	bank_code_label.text = str(printed.get("bank_code", "—"))
	code_label.text = code
	barcode.setup(code)
	_add_target(bank_target, boleto_id, "boleto_bank", "%s · %s" % [
		bank_label.text, bank_code_label.text
	])
	_add_target(code_target, boleto_id, "boleto_code", code)

	for field in FIELDS:
		var text := str(printed.get(field[0], "—"))
		if field[0] == "value":
			text = GameData.format_brl(float(printed.get("value", 0.0)))
		_add_field(field[1], text, boleto_id, field[2])


## Rules group the sections of this screen are checked against, see data/rules/rules.json
func get_rules_app() -> String:
	return "Bank"


## Arms every part of the boleto so the player can point at the one giving the scam away
func set_inspection_mode(is_on: bool) -> void:
	_inspector.set_armed(is_on)


## Sections that can be pointed at, lit while the rest of the phone is dimmed
func get_discrepancy_targets() -> Array[DiscrepancyTarget]:
	return _inspector.get_targets()


## Unmarks the part picked, the others stay armed
func clear_discrepancy_selection() -> void:
	_inspector.clear_selection()


## Adds a field under the code: its caption, its value and the target that lets it be pointed at
func _add_field(caption: String, text: String, boleto_id: String, section: String) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	fields_column.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	_add_label(column, caption, FONT_REGULAR, 12, MUTED)
	_add_label(column, text, FONT_SEMIBOLD, 16, INK)

	var target := DiscrepancyTarget.new()
	target.padding = Vector2(8, 5)
	panel.add_child(target)
	_add_target(target, boleto_id, section, text)


func _add_label(parent: Container, text: String, font: Font, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 1
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _add_target(
	target: DiscrepancyTarget, boleto_id: String, section: String, excerpt: String
) -> void:
	target.section = {
		"source": "boleto",
		"boleto_id": boleto_id,
		"section": section,
		"excerpt": excerpt,
	}
	_inspector.add(target)
