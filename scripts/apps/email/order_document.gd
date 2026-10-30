extends Control
## An order document of a company sector, opened from an email attachment
##
## Shows the order the way the sector filled it: its number, who asked for it, why, and who
## signed it. Each of those can be pointed at as a scam discrepancy, to be checked against the
## orders of the day and the approvers listed in the Notes app.

## Emitted when the player, inspecting, points at a part of the document as a scam discrepancy
##
## section: "source" ("document"), "section" ("order_id", "order_requester", "order_reason" or
## "order_signature"), "document_id" and "excerpt"
signal discrepancy_picked(section: Dictionary)

const DOCUMENTS_PATH := "res://data/orders/documents.json"

@export var department_label: Label
@export var order_id_label: Label
@export var requester_label: Label
@export var reason_label: Label
@export var items_label: Label
@export var signature_label: Label
@export var signature_caption_label: Label
@export var order_id_target: DiscrepancyTarget
@export var requester_target: DiscrepancyTarget
@export var reason_target: DiscrepancyTarget
@export var signature_target: DiscrepancyTarget

## Keeps the parts of the document that can be pointed at as a discrepancy in step
var _inspector := DiscrepancyInspector.new()


func _ready() -> void:
	_inspector.picked.connect(discrepancy_picked.emit) # Propagate signal to base app


## Fills the document from data/orders/documents.json
##
## attachment: The email attachment that opened it, with its "document_id"
func setup(attachment: Dictionary) -> void:
	var document_id := str(attachment.get("document_id", ""))
	var document: Dictionary = _load_documents().get(document_id, {})

	var department := str(document.get("department", "—"))
	department_label.text = "Enigma · Setor de %s" % department
	order_id_label.text = str(document.get("order_id", "—"))
	requester_label.text = str(document.get("requested_by", "—"))
	reason_label.text = str(document.get("reason", "—"))
	items_label.text = str(document.get("items", ""))
	signature_label.text = str(document.get("signed_by", ""))
	signature_caption_label.text = "Assinado por %s" % str(document.get("signed_by", "—"))

	_inspector.forget_all()
	_add_target(order_id_target, document_id, "order_id", order_id_label.text)
	_add_target(requester_target, document_id, "order_requester", requester_label.text)
	_add_target(
		reason_target, document_id, "order_reason", "%s: %s" % [reason_label.text, items_label.text]
	)
	_add_target(signature_target, document_id, "order_signature", signature_label.text)


## Rules group the sections of this screen are checked against, see data/rules/rules.json
func get_rules_app() -> String:
	return "browser"


## Arms every part of the document so the player can point at the one giving the scam away
func set_inspection_mode(is_on: bool) -> void:
	_inspector.set_armed(is_on)


## Sections that can be pointed at, lit while the rest of the phone is dimmed
func get_discrepancy_targets() -> Array[DiscrepancyTarget]:
	return _inspector.get_targets()


## Unmarks the part picked, the others stay armed
func clear_discrepancy_selection() -> void:
	_inspector.clear_selection()


func _add_target(
	target: DiscrepancyTarget, document_id: String, section: String, excerpt: String
) -> void:
	target.section = {
		"source": "document",
		"document_id": document_id,
		"section": section,
		"excerpt": excerpt,
	}
	_inspector.add(target)


## Reads every order document, forged ones included
func _load_documents() -> Dictionary:
	var file := FileAccess.open(DOCUMENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open documents file: %s" % DOCUMENTS_PATH)
		return {}

	var documents = JSON.parse_string(file.get_as_text())
	if not documents is Dictionary:
		push_error("Documents file is not a JSON object: %s" % DOCUMENTS_PATH)
		return {}
	return documents
