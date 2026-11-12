## Modal shown over the phone before each day, like the newspaper in Papers Please.
## Goes one page at a time: first the new rule of the day, then one page per scam to watch
## for, each with an example chat drawn like the Messages app whose suspicious part gets
## marked. "Entendi" moves on and the last page starts the day, which is what kicks off
## the new day
extends Control

signal day_started
## Closed over a day that is already set up (the game was loaded), so no day starts
signal preview_closed

## Labels, boxes, bars and bubbles the example screens are drawn with
const IntroBuilders = preload("res://scripts/utils/day_introduction_builders.gd")
## The game's days on top of the rule page
const IntroCalendar = preload("res://scripts/utils/day_introduction_calendar.gd")
## Example chats of the day's scams, one page each after the introduction. Kept in a
## subfolder so the introductions loader, which reads every file in data/introduction, skips it
const SCAMS_PATH := "res://data/introduction/scams/day_%d_scams.json"
const AVATAR_PATH = IntroBuilders.AVATAR_PATH
const PROFILE_PICTURE = IntroBuilders.PROFILE_PICTURE
const TYPING_ANIMATION = preload("res://scenes/apps/messages/message_animation.tscn")
const RULE_ICON = preload("res://assets/icons/check.svg")
const SCAM_ICON = preload("res://assets/icons/inspect_light.svg")
const NOTES_ICON = preload("res://assets/icons/notes.png")
const CLIP_ICON = preload("res://assets/icons/paper-clip-14011.svg")
const INFORMATION_FIELD = preload("res://scenes/apps/bank/information_field.tscn")
const PIX_CODES_PATH := "res://data/bank/pix_codes_data.json"
const TICKET_CODES_PATH := "res://data/bank/ticket_codes_data.json"
const BOLD_FONT = IntroBuilders.BOLD_FONT
const SEMI_FONT = IntroBuilders.SEMI_FONT
const MEDIUM_FONT = IntroBuilders.MEDIUM_FONT
const REGULAR_FONT = IntroBuilders.REGULAR_FONT

const INK_COLOR = IntroBuilders.INK_COLOR
const MUTED_COLOR = IntroBuilders.MUTED_COLOR
const CREAM_COLOR = IntroBuilders.CREAM_COLOR
const SUCCESS_COLOR = IntroBuilders.SUCCESS_COLOR
const FAILURE_COLOR = IntroBuilders.FAILURE_COLOR
const DOT_COLOR := Color(0.09019608, 0.10980392, 0.18039216, 0.15)
## Same look as the Messages app: its top bar, chat background and NPC bubbles
const CHAT_BAR_COLOR = IntroBuilders.CHAT_BAR_COLOR
const BUBBLE_BORDER_COLOR = IntroBuilders.BUBBLE_BORDER_COLOR
## Same look as the Email app: its text and its attachment chips
const EMAIL_TEXT_COLOR := Color(0.101960786, 0.1254902, 0.2)
const ATTACHMENT_TEXT_COLOR := Color(0.13333334, 0.28235295, 0.38431373)
## The Bank app's "Confirmar" button
const CONFIRM_COLOR := Color(1, 0.015686275, 0.2784314)
## The Bank app's "code not found" message
const BANK_TEXT_COLOR := Color(0, 0.03529412, 0.14117648)
const BANK_ERROR_COLOR := Color(0.36078432, 0.078431375, 0.2)
## Marker run over the suspicious part of each example
const BUBBLE_MARK = IntroBuilders.BUBBLE_MARK
## Seconds the description takes per character to be typed
const TYPE_SECONDS := 0.025
## Seconds the "typing..." bubble shows before each example message arrives
const TYPING_SECONDS := 0.55
const PAGE_SECONDS := 0.3

@export var scrim: ColorRect
@export var sheet: Control
@export var icon_badge: PanelContainer
@export var icon: TextureRect
@export var day_label: Label
@export var title_label: Label
@export var dots: HBoxContainer
@export var pages_holder: Control
@export var next_button: Button
## Played as each example message arrives, like a message coming in on the phone
@export var message_sound: AudioStreamPlayer
## Played on "Entendi", the same tap sound as the phone's apps
@export var touch_sound: AudioStreamPlayer

var _pages: Array[Control] = []
## Day whose introduction is shown
var _day := 0
## Shown over a day already set up, closing it doesn't start the day
var _is_preview := false
var _page_index := 0
## Animation of whatever is being shown right now, tapping finishes it at once
var _reveal_tween: Tween
var _pulse_tween: Tween
var _is_changing_page := false
## Set while a tap rushes the animation to its end, so the sounds it skips over stay quiet
var _is_skipping := false


func _ready() -> void:
	visible = false
	scrim.gui_input.connect(_on_gui_input)
	next_button.pressed.connect(_on_next_button_pressed)


## Shows today's rules, or starts the day right away when there are none for it
##
## preview_day: Shows that day's introduction over a day already set up, closing it starts nothing
func show_introduction(preview_day: int = -1) -> void:
	_is_preview = preview_day >= 0
	_day = preview_day if _is_preview else GameData.current_day
	# Introductions are loaded by the IntroductionDirector from data/introduction
	var found := GameData.introductions.filter(func(item): return item.day == _day)
	if found.is_empty():
		if _is_preview:
			preview_closed.emit()
		else:
			_start_day()
		return

	var rules_by_id := {}
	for rule in GameData.load_rules():
		rules_by_id[rule.get("id", "")] = rule

	for child in pages_holder.get_children() + dots.get_children():
		child.queue_free()
	_pages.clear()
	_pages.append(_make_rule_page(found[0]))
	var scams = _load_json(SCAMS_PATH % _day)
	for scam in scams.get("scams", []) if scams is Dictionary else []:
		_pages.append(_make_scam_page(scam, rules_by_id.get(scam.get("rule_id", ""), {})))
	for page in _pages:
		page.visible = false
		pages_holder.add_child(page)
		dots.add_child(_make_dot())

	day_label.text = "DIA %d" % _day
	next_button.disabled = false
	scrim.modulate.a = 0.0
	sheet.modulate.a = 0.0
	modulate.a = 1.0
	show()

	# Wait for the layout so the modal has its resting size
	await get_tree().process_frame
	sheet.pivot_offset = sheet.size / 2
	next_button.pivot_offset = next_button.size / 2
	icon_badge.pivot_offset = icon_badge.size / 2

	# The phone blurs behind and the modal pops up over it
	_set_header(_pages[0])
	var open_tween := create_tween()
	open_tween.tween_property(scrim, "modulate:a", 1.0, 0.25)
	open_tween.tween_property(sheet, "modulate:a", 1.0, 0.2)
	(
		open_tween
		. parallel()
		. tween_property(sheet, "scale", Vector2.ONE, 0.45)
		. from(Vector2(0.85, 0.85))
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	_prepare_page(_pages[0])
	open_tween.tween_callback(_show_page.bind(0))


#region PAGES
func _show_page(index: int) -> void:
	_page_index = index
	var page := _pages[index]
	page.visible = true
	page.position.x = 0.0
	_set_header(page)
	var is_last := index == _pages.size() - 1
	next_button.text = "Começar Dia %d" % _day if is_last else "Entendi"
	_update_dots()

	# The badge in the header bounces in with the page's colour and icon
	var badge_tween := create_tween()
	(
		badge_tween
		. tween_property(icon_badge, "scale", Vector2.ONE, 0.4)
		. from(Vector2(0.6, 0.6))
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)

	if _reveal_tween:
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.tween_interval(0.15)
	if page.get_meta("kind") == "rule":
		_reveal_rule_page(page)
	else:
		_reveal_scam_page(page)
	if is_last:
		_reveal_tween.tween_callback(_pulse_next_button)


## Puts a page back to before its animation, so it slides in still empty
func _prepare_page(page: ScrollContainer) -> void:
	page.scroll_vertical = 0
	if page.get_meta("kind") == "rule":
		page.get_meta("calendar").prepare()
		page.get_meta("description").visible_ratio = 0.0
		for card in page.get_meta("rule_cards"):
			card.modulate.a = 0.0
		page.get_meta("footer").modulate.a = 0.0
		return
	for bubble in page.get_meta("bubbles"):
		bubble.visible = false
	if page.has_meta("typing"):
		page.get_meta("typing").visible = false
	if page.has_meta("bank_block"):
		page.get_meta("bank_block").modulate.a = 0.0
		for circle in page.get_meta("bank_circles"):
			_set_circle_progress(0.0, circle)
	page.get_meta("tip").modulate.a = 0.0


func _set_header(page: Control) -> void:
	var is_rule: bool = page.get_meta("kind") == "rule"
	title_label.text = page.get_meta("title")
	icon.texture = RULE_ICON if is_rule else SCAM_ICON
	icon_badge.self_modulate = SUCCESS_COLOR if is_rule else FAILURE_COLOR


## Slides the current page out to the left and the next one in from the right
func _go_to_next_page() -> void:
	_is_changing_page = true
	var old_page := _pages[_page_index]
	var new_page := _pages[_page_index + 1]
	var width := pages_holder.size.x

	var slide := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(old_page, "position:x", -width, PAGE_SECONDS)
	slide.tween_property(old_page, "modulate:a", 0.0, PAGE_SECONDS)
	_prepare_page(new_page)
	new_page.visible = true
	new_page.modulate.a = 0.0
	slide.tween_property(new_page, "position:x", 0.0, PAGE_SECONDS).from(width)
	slide.tween_property(new_page, "modulate:a", 1.0, PAGE_SECONDS)
	await slide.finished

	old_page.visible = false
	old_page.modulate.a = 1.0
	_is_changing_page = false
	_show_page(_page_index + 1)


## One dot per page, the current one stretched into a pill
func _update_dots() -> void:
	for index in dots.get_child_count():
		var dot: Panel = dots.get_child(index)
		var is_current := index == _page_index
		var dot_tween := dot.create_tween().set_parallel()
		dot_tween.tween_property(dot, "custom_minimum_size:x", 18.0 if is_current else 6.0, 0.25)
		dot_tween.tween_property(
			dot, "self_modulate", SUCCESS_COLOR if is_current else DOT_COLOR, 0.25
		)


func _make_dot() -> Panel:
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", IntroBuilders.box(Color.WHITE, 100, 0))
	dot.self_modulate = DOT_COLOR
	return dot


#endregion PAGES


#region RULE PAGE
## First page, from the day's introduction: its description typed out, the things to
## pay attention to as numbered cards and the footer pointing to the notes
func _make_rule_page(introduction: GameData.Introduction) -> Control:
	var page := _make_page("Regras do dia", "rule")
	var column: VBoxContainer = page.get_meta("column")

	var calendar := IntroCalendar.new()
	calendar.setup(_day)
	column.add_child(calendar)

	var description := IntroBuilders.rich_label(introduction.description, 16, INK_COLOR, BOLD_FONT)
	column.add_child(description)

	var rule_cards: Array[Control] = []
	var rules := introduction.rules
	for index in rules.size():
		var card := _rule_card(index + 1, rules[index])
		column.add_child(card)
		rule_cards.append(card)

	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override(
		"panel", IntroBuilders.box(Color(SUCCESS_COLOR, 0.12), 12, 10)
	)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 10)
	footer.add_child(footer_row)
	var notes_icon := TextureRect.new()
	notes_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	notes_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	notes_icon.texture = NOTES_ICON
	notes_icon.custom_minimum_size = Vector2(30, 30)
	notes_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer_row.add_child(notes_icon)
	var footer_label := IntroBuilders.label(
		introduction.footer, SEMI_FONT, 12, CHAT_BAR_COLOR.darkened(0.3)
	)
	footer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer_row.add_child(footer_label)
	footer.visible = introduction.footer != ""
	column.add_child(footer)

	page.set_meta("calendar", calendar)
	page.set_meta("description", description)
	page.set_meta("rule_cards", rule_cards)
	page.set_meta("footer", footer)
	return page


## One thing to pay attention to: its number in a disc and the text, without the leading dash
func _rule_card(number: int, text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel", IntroBuilders.box(Color.WHITE, 12, 10, BUBBLE_BORDER_COLOR)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var number_disc := PanelContainer.new()
	number_disc.custom_minimum_size = Vector2(26, 26)
	number_disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	number_disc.add_theme_stylebox_override("panel", IntroBuilders.box(SUCCESS_COLOR, 100, 0))
	var number_label := IntroBuilders.label(str(number), BOLD_FONT, 13, CREAM_COLOR)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_disc.add_child(number_label)
	row.add_child(number_disc)

	var rule_label := IntroBuilders.label(text.lstrip("—–- "), MEDIUM_FONT, 13, INK_COLOR)
	rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule_label)
	return card


## The description is typed out, then each card pops in and the footer fades in last
func _reveal_rule_page(page: Control) -> void:
	var description: RichTextLabel = page.get_meta("description")
	var footer: Control = page.get_meta("footer")

	page.get_meta("calendar").reveal(_reveal_tween)
	_reveal_tween.tween_property(
		description, "visible_ratio", 1.0, description.text.length() * TYPE_SECONDS
	)
	for card in page.get_meta("rule_cards"):
		_reveal_tween.tween_interval(0.15)
		_reveal_tween.tween_callback(_center_pivot.bind(card))
		_reveal_tween.tween_property(card, "modulate:a", 1.0, 0.2)
		(
			_reveal_tween
			. parallel()
			. tween_property(card, "scale", Vector2.ONE, 0.35)
			. from(Vector2(0.9, 0.9))
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
	_reveal_tween.tween_interval(0.25)
	_reveal_tween.tween_callback(_scroll_to_end.bind(page))
	_reveal_tween.tween_property(footer, "modulate:a", 1.0, 0.35)


#endregion RULE PAGE


## Scales and pops from the middle, measured when the animation reaches it so the layout is settled
func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size / 2


#region SCAM PAGE
## A page for one scam: the real contact next to the impostor when there is one, the
## impostor's example as its app shows it (a chat, or an email with "app": "email") and
## what gives it away
func _make_scam_page(scam: Dictionary, rule: Dictionary) -> Control:
	var page := _make_page(scam.get("title", rule.get("title", "Golpe")), "scam")
	var column: VBoxContainer = page.get_meta("column")
	var marked_labels: Array[RichTextLabel] = []

	var real: Dictionary = scam.get("real", {})
	if not real.is_empty():
		var real_block := IntroBuilders.captioned_block(
			"Contato verdadeiro", CHAT_BAR_COLOR.darkened(0.2)
		)
		var real_bar := IntroBuilders.chat_bar(
			real.get("sender", ""), real.get("avatar", ""), real.get("verified", false)
		)
		real_bar.add_theme_stylebox_override("panel", IntroBuilders.box(CHAT_BAR_COLOR, 14, 0))
		real_block.add_child(real_bar)
		column.add_child(real_block)

	var example_block := IntroBuilders.captioned_block(
		"Golpista" if not real.is_empty() else "Exemplo", FAILURE_COLOR
	)
	column.add_child(example_block)
	if scam.get("app", "messages") == "email":
		example_block.add_child(_email_example(scam, page, marked_labels))
	else:
		example_block.add_child(_chat_example(scam, page, marked_labels))

	# The payment as the Bank app shows it, with what to check circled
	if scam.has("bank"):
		var bank_block := IntroBuilders.captioned_block("No Banco", CHAT_BAR_COLOR.darkened(0.2))
		bank_block.add_child(_bank_example(scam["bank"], page))
		column.add_child(bank_block)
		page.set_meta("bank_block", bank_block)

	# What gives it away, shown once the suspicious part is marked
	var tip := PanelContainer.new()
	var tip_style := IntroBuilders.box(Color(FAILURE_COLOR, 0.07), 12, 12)
	tip_style.border_width_left = 3
	tip_style.border_color = FAILURE_COLOR
	tip.add_theme_stylebox_override("panel", tip_style)
	var tip_column := VBoxContainer.new()
	tip_column.add_theme_constant_override("separation", 2)
	tip.add_child(tip_column)
	tip_column.add_child(IntroBuilders.label("Como identificar", BOLD_FONT, 12, FAILURE_COLOR))
	tip_column.add_child(
		IntroBuilders.label(
			scam.get("tip", rule.get("description", "")), REGULAR_FONT, 12, INK_COLOR
		)
	)
	column.add_child(tip)

	page.set_meta("marked_labels", marked_labels)
	page.set_meta("suspicious", scam.get("suspicious", ""))
	page.set_meta("tip", tip)
	return page


## The impostor's chat: the Messages app's top bar with its name, then its messages, which
## come out of a "typing..." bubble one by one
func _chat_example(scam: Dictionary, page: Control, marked_labels: Array[RichTextLabel]) -> Control:
	var chat := VBoxContainer.new()
	chat.add_theme_constant_override("separation", 0)
	var bar := IntroBuilders.chat_bar(scam.get("sender", ""), scam.get("avatar", ""), false)
	bar.add_theme_stylebox_override("panel", IntroBuilders.top_box(CHAT_BAR_COLOR, 0))
	chat.add_child(bar)
	marked_labels.append(bar.get_meta("name_label"))

	var canvas := PanelContainer.new()
	canvas.add_theme_stylebox_override("panel", IntroBuilders.bottom_box(CREAM_COLOR, 8))
	chat.add_child(canvas)
	var messages_list := VBoxContainer.new()
	messages_list.add_theme_constant_override("separation", 5)
	canvas.add_child(messages_list)
	messages_list.add_child(IntroBuilders.date_pill())

	var bubbles: Array[Control] = []
	var messages: Array = scam.get("messages", [])
	for index in messages.size():
		var bubble := IntroBuilders.chat_bubble(messages[index], "09:%02d" % (41 + index))
		messages_list.add_child(bubble)
		bubbles.append(bubble)
		marked_labels.append(bubble.get_meta("text_label"))
	var typing := IntroBuilders.chat_bubble("", "")
	var typing_column: VBoxContainer = typing.get_meta("column")
	for child in typing_column.get_children():
		typing_column.remove_child(child)
		child.free()
	typing_column.add_child(TYPING_ANIMATION.instantiate())
	messages_list.add_child(typing)

	page.set_meta("bubbles", bubbles)
	page.set_meta("typing", typing)
	return chat


## The impostor's email as the Email app shows it: subject, sender with its avatar, the text
## and the attachments as chips. It arrives all at once, like a new email
func _email_example(
	scam: Dictionary, page: Control, marked_labels: Array[RichTextLabel]
) -> Control:
	var email := VBoxContainer.new()
	email.add_theme_constant_override("separation", 0)
	email.add_child(IntroBuilders.app_bar("Email"))

	var canvas := PanelContainer.new()
	canvas.add_theme_stylebox_override("panel", IntroBuilders.bottom_box(CREAM_COLOR, 12))
	email.add_child(canvas)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	canvas.add_child(body)

	var subject := IntroBuilders.rich_label(scam.get("subject", ""), 15, INK_COLOR, BOLD_FONT)
	subject.set_meta("mark", BUBBLE_MARK)
	body.add_child(subject)
	marked_labels.append(subject)

	var sender_row := HBoxContainer.new()
	sender_row.add_theme_constant_override("separation", 9)
	body.add_child(sender_row)
	var avatar_holder := Control.new()
	avatar_holder.custom_minimum_size = Vector2(30, 30)
	avatar_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sender_row.add_child(avatar_holder)
	var picture: Control = PROFILE_PICTURE.instantiate()
	picture.custom_minimum_size = Vector2(30, 30)
	avatar_holder.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sender_name: String = scam.get("sender", "")
	picture.setup(AVATAR_PATH % scam.get("avatar", sender_name), sender_name)
	var sender_column := VBoxContainer.new()
	sender_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sender_column.add_theme_constant_override("separation", -2)
	sender_row.add_child(sender_column)
	var sender := IntroBuilders.rich_label(sender_name, 12, INK_COLOR, BOLD_FONT)
	sender.set_meta("mark", BUBBLE_MARK)
	sender_column.add_child(sender)
	marked_labels.append(sender)
	sender_column.add_child(IntroBuilders.label("para mim", REGULAR_FONT, 11, MUTED_COLOR))
	var time := IntroBuilders.label("09:41", MEDIUM_FONT, 10, MUTED_COLOR)
	time.autowrap_mode = TextServer.AUTOWRAP_OFF
	time.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sender_row.add_child(time)

	var content := IntroBuilders.rich_label(
		"\n".join(scam.get("messages", [])), 13, EMAIL_TEXT_COLOR
	)
	content.set_meta("mark", BUBBLE_MARK)
	body.add_child(content)
	marked_labels.append(content)

	var attachments: Array = scam.get("attachments", [])
	if not attachments.is_empty():
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 6)
		chips.add_theme_constant_override("v_separation", 6)
		body.add_child(chips)
		for attachment in attachments:
			var chip := PanelContainer.new()
			var chip_style := IntroBuilders.box(Color(SUCCESS_COLOR, 0.22), 100, 0)
			chip_style.content_margin_left = 10
			chip_style.content_margin_right = 12
			chip_style.content_margin_top = 4
			chip_style.content_margin_bottom = 4
			chip.add_theme_stylebox_override("panel", chip_style)
			var chip_row := HBoxContainer.new()
			chip_row.add_theme_constant_override("separation", 5)
			chip.add_child(chip_row)
			var clip := TextureRect.new()
			clip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			clip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			clip.texture = CLIP_ICON
			clip.custom_minimum_size = Vector2(12, 12)
			clip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			chip_row.add_child(clip)
			var chip_label := IntroBuilders.rich_label(
				str(attachment), 11, ATTACHMENT_TEXT_COLOR, SEMI_FONT
			)
			chip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			chip_label.set_meta("mark", BUBBLE_MARK)
			chip_row.add_child(chip_label)
			marked_labels.append(chip_label)
			chips.add_child(chip)

	page.set_meta("bubbles", [body])
	return email


## The impostor's messages arrive one by one (out of the "typing..." bubble on a chat), then
## the suspicious part is marked and the tip explains it
func _reveal_scam_page(page: Control) -> void:
	var typing: Control = page.get_meta("typing", null)
	var tip: Control = page.get_meta("tip")

	for bubble in page.get_meta("bubbles"):
		if typing:
			_reveal_tween.tween_callback(typing.set_visible.bind(true))
			_reveal_tween.tween_interval(TYPING_SECONDS)
			_reveal_tween.tween_callback(typing.set_visible.bind(false))
		_reveal_tween.tween_callback(bubble.set_visible.bind(true))
		_reveal_tween.tween_callback(_play_message_sound)
		_reveal_tween.tween_property(bubble, "modulate:a", 1.0, 0.15).from(0.0)
		(
			_reveal_tween
			. parallel()
			. tween_property(bubble, "scale", Vector2.ONE, 0.3)
			. from(Vector2(0.9, 0.9))
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		_reveal_tween.tween_interval(0.2)

	_reveal_tween.tween_interval(0.2)
	_reveal_tween.tween_callback(_mark_suspicious.bind(page))
	_reveal_tween.tween_interval(0.35)

	if page.has_meta("bank_block"):
		_reveal_tween.tween_callback(_scroll_to_end.bind(page))
		_reveal_tween.tween_property(page.get_meta("bank_block"), "modulate:a", 1.0, 0.3)
		_reveal_tween.tween_interval(0.3)
		for circle in page.get_meta("bank_circles"):
			(
				_reveal_tween
				. tween_method(_set_circle_progress.bind(circle), 0.0, 1.0, 0.55)
				. set_trans(Tween.TRANS_SINE)
				. set_ease(Tween.EASE_IN_OUT)
			)
			_reveal_tween.tween_interval(0.15)

	_reveal_tween.tween_callback(_scroll_to_end.bind(page))
	_reveal_tween.tween_property(tip, "modulate:a", 1.0, 0.3)


## Slides the page down to its end when the content doesn't fit, so the tip comes into view
func _scroll_to_end(page: ScrollContainer) -> void:
	# Measured a frame later: what was just shown (or all of it, when skipped) has to be laid out first
	await get_tree().process_frame
	var end := int(page.get_v_scroll_bar().max_value - page.size.y)
	if end > page.scroll_vertical:
		(
			create_tween()
			. tween_property(page, "scroll_vertical", end, 0.45)
			. set_trans(Tween.TRANS_SINE)
			. set_ease(Tween.EASE_OUT)
		)


func _mark_suspicious(page: Control) -> void:
	var suspicious: String = page.get_meta("suspicious")
	if suspicious == "":
		return
	for label: RichTextLabel in page.get_meta("marked_labels"):
		var mark: String = label.get_meta("mark")
		if label.text.contains(suspicious) and not label.text.contains(mark % suspicious):
			label.text = label.text.replace(suspicious, mark % suspicious)


#endregion SCAM PAGE


#region BANK EXAMPLE
## The payment as the Bank app shows it once its code is typed: the code, then the same
## information fields the app uses and its "Confirmar" button. The fields come from the
## game's bank data when the code exists there, or from "fields" in the JSON otherwise
## (for checks the app doesn't show yet). Each field named in "check" gets circled
func _bank_example(bank: Dictionary, page: Control) -> Control:
	var is_pix: bool = bank.get("type", "boleto") == "pix"
	var code: String = bank.get("code", "")
	var fields: Array = bank.get("fields", _bank_fields(is_pix, code))
	var to_check: Array = bank.get("check", [])

	var screen := VBoxContainer.new()
	screen.add_theme_constant_override("separation", 0)
	screen.add_child(IntroBuilders.app_bar("Banco"))
	var canvas := PanelContainer.new()
	canvas.add_theme_stylebox_override("panel", IntroBuilders.bottom_box(CREAM_COLOR, 12))
	screen.add_child(canvas)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	canvas.add_child(column)

	var circles: Array[Control] = []
	for field in [["Código Pix" if is_pix else "Código Boleto", code]] + fields:
		var information: VBoxContainer = INFORMATION_FIELD.instantiate()
		column.add_child(information)
		information.setup(str(field[0]), str(field[1]))
		var information_panel: Control = information.get_node("InformationPanel")
		information_panel.custom_minimum_size.y = 38
		if to_check.has(field[0]):
			circles.append(_pen_circle(information_panel))

	if fields.is_empty():
		column.add_child(_not_found(code))
		page.set_meta("bank_circles", circles)
		return screen

	# The app's confirm button, there only for the look
	var confirm := PanelContainer.new()
	confirm.custom_minimum_size.y = 36
	confirm.add_theme_stylebox_override("panel", IntroBuilders.box(CONFIRM_COLOR, 17, 0))
	var confirm_label := IntroBuilders.label("Confirmar", BOLD_FONT, 15, Color.WHITE)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm.add_child(confirm_label)
	column.add_child(confirm)

	page.set_meta("bank_circles", circles)
	return screen


## The message the Bank app shows when the typed code doesn't exist
func _not_found(code: String) -> VBoxContainer:
	var message := VBoxContainer.new()
	message.add_theme_constant_override("separation", 6)
	var not_found := IntroBuilders.label(
		'O código digitado "%s" não foi encontrado.' % code, REGULAR_FONT, 14, BANK_TEXT_COLOR
	)
	not_found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(not_found)
	var check := IntroBuilders.label(
		"Confira se a informação está correta!", BOLD_FONT, 12, BANK_ERROR_COLOR
	)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(check)
	return message


## The fields the Bank app shows for a code from the game's bank data, empty when the code
## isn't there
func _bank_fields(is_pix: bool, code: String) -> Array:
	var codes = _load_json(PIX_CODES_PATH if is_pix else TICKET_CODES_PATH)
	var info: Dictionary = codes.get(code, {}) if codes is Dictionary else {}
	if info.is_empty():
		return []
	if is_pix:
		return [
			["Nome", info["name"]],
			["CPF", info["cpf"]],
			["Email", info["email"]],
			["Valor", GameData.format_brl(info["value"])]
		]
	return [
		["Instituição Pagadora", info["institution"]], ["Valor", GameData.format_brl(info["value"])]
	]


## A red pen circle around a control, drawn as "circle_progress" goes from 0 to 1
func _pen_circle(around: Control) -> Control:
	var circle := Control.new()
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	circle.set_meta("circle_progress", 0.0)
	circle.draw.connect(_draw_pen_circle.bind(circle))
	around.add_child(circle)
	return circle


func _draw_pen_circle(circle: Control) -> void:
	var progress: float = circle.get_meta("circle_progress")
	if progress <= 0.0:
		return
	var center := circle.size / 2
	var radius := circle.size / 2 + Vector2(10, 7)
	# A bit more than a full turn and slightly wobbly, like a quick circle made by hand
	var start := deg_to_rad(-160.0)
	var sweep := TAU * 1.08 * progress
	var points := PackedVector2Array()
	var steps := maxi(int(48 * progress), 2)
	for step in steps + 1:
		var angle := start + sweep * step / steps
		var wobble := 1.0 + 0.035 * sin(angle * 3.0 + 1.3)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y) * wobble)
	circle.draw_polyline(points, Color(FAILURE_COLOR, 0.9), 2.5, true)


func _set_circle_progress(progress: float, circle: Control) -> void:
	circle.set_meta("circle_progress", progress)
	circle.queue_redraw()


#endregion BANK EXAMPLE


#region BUILDERS
## A page fills the holder and scrolls if its content is taller than the modal
func _make_page(title: String, kind: String) -> ScrollContainer:
	var page := ScrollContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	page.add_child(column)
	page.gui_input.connect(_on_gui_input)
	page.set_meta("title", title)
	page.set_meta("kind", kind)
	page.set_meta("column", column)
	return page


#endregion BUILDERS


## Gently breathes the button on the last page so the player knows the day starts there
func _pulse_next_button() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(next_button, "scale", Vector2(1.04, 1.04), 0.6).set_trans(
		Tween.TRANS_SINE
	)
	_pulse_tween.tween_property(next_button, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _play_message_sound() -> void:
	if _is_skipping:
		return
	# Slightly different each time so a run of messages doesn't sound mechanical
	message_sound.pitch_scale = randf_range(0.95, 1.08)
	message_sound.play()


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Tapping while a page is still animating shows it all at once
func _skip_reveal() -> bool:
	if _reveal_tween and _reveal_tween.is_running():
		_is_skipping = true
		_reveal_tween.custom_step(60.0)
		_is_skipping = false
		return true
	return false


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip_reveal()


func _on_next_button_pressed() -> void:
	if _is_changing_page or _skip_reveal():
		return
	touch_sound.play()
	if _page_index < _pages.size() - 1:
		_go_to_next_page()
		return

	next_button.disabled = true
	if _pulse_tween:
		_pulse_tween.kill()
	next_button.scale = Vector2.ONE

	# The modal shrinks away and the phone comes back into focus
	var exit_tween := create_tween().set_parallel()
	(
		exit_tween
		. tween_property(sheet, "scale", Vector2(0.9, 0.9), 0.25)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_IN)
	)
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await exit_tween.finished
	hide()
	if _is_preview:
		preview_closed.emit()
	else:
		_start_day()


func _start_day() -> void:
	day_started.emit()
	GameData.save_game()
