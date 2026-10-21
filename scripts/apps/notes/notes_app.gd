extends Control
## The company board: what the player checks a message, email or payment against
##
## Read from data/notes/board.json each time the app opens. Every section shows up on the day
## the rule that needs it is released (see data/rules/rules.json), tagged as new on that day.

const BOARD_PATH := "res://data/notes/board.json"
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-Bold.ttf")
const FONT_SEMIBOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const FONT_REGULAR := preload("res://assets/fonts/IBMPlexSans-Regular.ttf")
const INK := Color(0.09019608, 0.10980392, 0.18039216)
const MUTED := Color(0.43137255, 0.44313726, 0.5019608)
const TEAL := Color(0.13333334, 0.28235295, 0.38431373)
const MINT := Color(0.30980393, 0.79607844, 0.68235296)
const HAIRLINE := Color(0.85882354, 0.84705883, 0.8117647)

@export var subtitle_label: Label
@export var sections_list: VBoxContainer
@export var scroll: ScrollContainer


## Rebuilds the board for today
func setup() -> void:
	for child in sections_list.get_children():
		sections_list.remove_child(child)
		child.queue_free()

	var board := _load_board()
	var today: Dictionary = board.get("days", {}).get(str(GameData.current_day), {})
	subtitle_label.text = "Confira aqui antes de denunciar · Dia %d" % GameData.current_day

	_add_trusted_contacts(board)
	_add_list_section("Arquivos aceitos", 1, board.get("accepted_files", []))
	_add_list_section("Padrões de pagamento", 1, board.get("payment_patterns", []))
	_add_list_section("Lojas", 1, [
		"Antes de comprar, veja a nota da loja no site de avaliações do Navegador.",
		"Nota abaixo de 50: não compre e denuncie.",
	])
	_add_list_section("Motivos aceitos", 2, board.get("accepted_reasons", []))
	_add_orders(today.get("orders", []))
	_add_list_section("Regras de segurança", 4, board.get("security_rules", []))
	_add_list_section("Bancos aceitos hoje", 4, today.get("accepted_banks", []))
	_add_approvers(board.get("approvers", []))

	scroll.scroll_vertical = 0


## Who can ask the player for something today: the bosses and suppliers of every day, and the
## people the random tasks of today come from (see story_director._publish_trusted_senders()).
## Anyone else is a scam. Emails are only listed once the Email app is released.
func _add_trusted_contacts(board: Dictionary) -> void:
	var directory: Array = board.get("contacts", [])
	var shows_email := (
		GameData.apps_in_store.has(GameData.App.EMAIL)
		or GameData.downloaded_apps.has(GameData.App.EMAIL)
	)

	var body := _add_section("Contatos confiáveis de hoje", 0)
	_add_line(body, "Só eles pedem algo a você hoje. Qualquer outro contato é golpe: confira nome, "
		+ "conta e email letra por letra.", MUTED)

	_add_caption(body, "CHEFIAS E FORNECEDORES")
	var fixed_people: Array[Dictionary] = []
	for trusted in board.get("trusted_every_day", []):
		var contact := _find_contact(directory, "name", str(trusted.get("name", "")))
		var person := _person(str(trusted.get("name", "")), directory)
		if trusted.get("channel", "messages") == "messages":
			person["account"] = str(contact.get("account", GameData.account_from_name(person["name"])))
			person["verified"] = contact.get("verified", false)
		else:
			person["email"] = str(contact.get("email", ""))
		fixed_people.append(person)
		_add_trusted_row(body, person, shows_email)

	_add_caption(body, "PEDIDOS DE HOJE")
	var people: Array[Dictionary] = []
	for sender in GameData.trusted_senders_today:
		# The bosses and suppliers of every day are already listed above
		if fixed_people.any(func(fixed: Dictionary) -> bool: return _is_same_sender(fixed, sender)):
			continue
		if sender.has("email"):
			if not shows_email:
				continue
			var owner := _find_contact(directory, "email", str(sender["email"]))
			var person := _find_person(people, str(owner.get("name", sender["email"])))
			if person.is_empty():
				person = _person(str(owner.get("name", sender["email"])), directory)
				people.append(person)
			person["email"] = str(sender["email"])
		else:
			var person := _find_person(people, str(sender["name"]))
			if person.is_empty():
				person = _person(str(sender["name"]), directory)
				people.append(person)
			person["account"] = str(sender["account"])
			person["verified"] = sender.get("verified", false)

	if people.is_empty():
		_add_line(body, "Ninguém além das chefias hoje.", MUTED)
	for person in people:
		_add_trusted_row(body, person, shows_email)


## Whether a sender of today is a person of the trusted contacts, by account or by address
func _is_same_sender(person: Dictionary, sender: Dictionary) -> bool:
	var email := str(sender.get("email", ""))
	var account := str(sender.get("account", ""))
	return (
		(not email.is_empty() and email == person["email"])
		or (not account.is_empty() and account == person["account"])
	)


## A person of the trusted contacts, with the sector the company directory gives it
func _person(person_name: String, directory: Array) -> Dictionary:
	var contact := _find_contact(directory, "name", person_name)
	return {
		"name": person_name,
		"account": "",
		"verified": false,
		"email": "",
		"department": str(contact.get("department", "")),
	}


func _find_person(people: Array[Dictionary], person_name: String) -> Dictionary:
	for person in people:
		if person["name"] == person_name:
			return person
	return {}


## The contact of the company directory whose field matches, empty when there is none
func _find_contact(directory: Array, field: String, value: String) -> Dictionary:
	for contact in directory:
		if str(contact.get(field, "")).to_lower() == value.to_lower():
			return contact
	return {}


## One trusted contact: its name, how it reaches the player (account, email) and its sector.
## A contact only reached by email is left out until the Email app is released
func _add_trusted_row(body: VBoxContainer, person: Dictionary, shows_email: bool) -> void:
	var has_account: bool = not str(person["account"]).is_empty()
	var has_email: bool = shows_email and not str(person["email"]).is_empty()
	if not has_account and not has_email:
		return

	var row := _add_row(body)
	_add_label(row, person["name"], FONT_SEMIBOLD, 14, INK)
	if has_account:
		var account: String = person["account"]
		if person["verified"]:
			account += " ✓"
		_add_label(row, account, FONT_REGULAR, 12, TEAL)
	# A sender known only by its address is already named by it
	if has_email and person["email"] != person["name"]:
		_add_label(row, person["email"], FONT_REGULAR, 12, TEAL)
	if not str(person["department"]).is_empty():
		_add_label(row, person["department"], FONT_REGULAR, 12, MUTED)


## Small title of a group of lines inside a section, set apart from the group above it
func _add_caption(body: VBoxContainer, text: String) -> void:
	if body.get_child_count() > 1:
		var gap := Control.new()
		gap.custom_minimum_size.y = 6
		body.add_child(gap)
	_add_label(body, text, FONT_BOLD, 10, MUTED)


## The orders of the sectors for today
func _add_orders(orders: Array) -> void:
	if GameData.current_day < 3:
		return
	var body := _add_section("Pedidos do dia", 3)
	if orders.is_empty():
		_add_line(body, "Nenhum pedido hoje.", MUTED)
	for order in orders:
		var row := _add_row(body)
		_add_label(row, str(order.get("order_id", "")), FONT_SEMIBOLD, 14, INK)
		_add_label(row, str(order.get("items", "")), FONT_REGULAR, 13, INK)
		_add_label(row, "Pedido por %s · %s" % [
			order.get("requested_by", ""), order.get("department", "")
		], FONT_REGULAR, 12, MUTED)


## Who signs the orders of each sector
func _add_approvers(approvers: Array) -> void:
	if GameData.current_day < 6:
		return
	var body := _add_section("Quem aprova pedidos", 6)
	_add_line(body, "Um pedido só vale com a assinatura de quem aprova no setor.", MUTED)
	for approver in approvers:
		_add_line(body, "%s: %s" % [approver.get("department", ""), approver.get("name", "")], INK)


## A section made of one line per item, shown from the given day on
func _add_list_section(title: String, day: int, items: Array) -> void:
	if GameData.current_day < day:
		return
	var body := _add_section(title, day)
	if items.is_empty():
		_add_line(body, "Nada por hoje.", MUTED)
	for item in items:
		_add_line(body, "• " + str(item), INK)


## Adds a section title (tagged as new on the day it shows up) and returns its body
func _add_section(title: String, day: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	sections_list.add_child(section)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	section.add_child(title_row)
	_add_label(title_row, title, FONT_BOLD, 16, INK)
	if day == GameData.current_day:
		title_row.add_child(_new_tag())

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	section.add_child(body)

	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1
	divider.color = HAIRLINE
	section.add_child(divider)
	return body


## A group of lines kept together, for one contact or one order
func _add_row(body: VBoxContainer) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	body.add_child(row)
	return row


func _add_line(body: Container, text: String, color: Color) -> void:
	_add_label(body, text, FONT_REGULAR, 13, color)


func _add_label(parent: Container, text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	# Lines of a column wrap to its width, a title in a row keeps its own width
	if parent is VBoxContainer:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 1
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


## The "NOVO" pill next to a section shown for the first time today
func _new_tag() -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MINT, 0.22)
	style.set_corner_radius_all(100)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 1
	style.content_margin_bottom = 1

	var tag := PanelContainer.new()
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "NOVO"
	label.add_theme_font_override("font", FONT_BOLD)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", TEAL)
	tag.add_child(label)
	return tag


func _load_board() -> Dictionary:
	var file := FileAccess.open(BOARD_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open board file: %s" % BOARD_PATH)
		return {}

	var board = JSON.parse_string(file.get_as_text())
	if not board is Dictionary:
		push_error("Board file is not a JSON object: %s" % BOARD_PATH)
		return {}
	return board
