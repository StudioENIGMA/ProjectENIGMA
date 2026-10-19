## Modal shown over the phone before each day, like the newspaper in Papers Please.
## Goes one page at a time: first the new rule of the day, then one page per scam to watch
## for, each with an example chat drawn like the Messages app whose suspicious part gets
## marked. "Entendi" moves on and the last page starts the day, which is what kicks off
## the new day
extends Control

signal day_started()
## Closed over a day that is already set up (the game was loaded), so no day starts
signal preview_closed()

## Example chats of the day's scams, one page each after the introduction. Kept in a
## subfolder so the introductions loader, which reads every file in data/introduction, skips it
const SCAMS_PATH := "res://data/introduction/scams/day_%d_scams.json"
const RULES_PATH := "res://data/rules/rules.json"
const AVATAR_PATH := "res://assets/avatars/%s.png"
const PROFILE_PICTURE = preload("res://scenes/apps/messages/profile_picture.tscn")
const TYPING_ANIMATION = preload("res://scenes/apps/messages/message_animation.tscn")
const VERIFIED_ICON = preload("res://assets/icons/verified.svg")
const BACK_ICON = preload("res://assets/icons/back_light.svg")
const RULE_ICON = preload("res://assets/icons/check.svg")
const SCAM_ICON = preload("res://assets/icons/inspect_light.svg")
const NOTES_ICON = preload("res://assets/icons/notes.png")
const CLIP_ICON = preload("res://assets/icons/paper-clip-14011.svg")
const INFORMATION_FIELD = preload("res://scenes/apps/bank/information_field.tscn")
const PIX_CODES_PATH := "res://data/bank/pix_codes_data.json"
const TICKET_CODES_PATH := "res://data/bank/ticket_codes_data.json"
## Last day of the game, its end rolls the credits (see day_over_ui.gd). Day 0 is the
## tutorial, so the calendar shows days 1 to this one
const LAST_DAY := 7
const WEEKDAY_NAMES := ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
const MONTH_NAMES := ["JANEIRO", "FEVEREIRO", "MARÇO", "ABRIL", "MAIO", "JUNHO", "JULHO", "AGOSTO", "SETEMBRO", "OUTUBRO", "NOVEMBRO", "DEZEMBRO"]
const BOLD_FONT = preload("res://assets/fonts/IBMPlexSans-Bold.ttf")
const SEMI_FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const MEDIUM_FONT = preload("res://assets/fonts/IBMPlexSans-Medium.ttf")
const REGULAR_FONT = preload("res://assets/fonts/IBMPlexSans-Regular.ttf")

const INK_COLOR := Color(0.09019608, 0.10980392, 0.18039216)
const MUTED_COLOR := Color(0.43137255, 0.44313726, 0.5019608)
const CREAM_COLOR := Color(1, 1, 0.972549)
const SUCCESS_COLOR := Color(0.30980393, 0.79607844, 0.68235296)
const FAILURE_COLOR := Color(0.92156863, 0.039215688, 0.27058825)
const DOT_COLOR := Color(0.09019608, 0.10980392, 0.18039216, 0.15)
## Same look as the Messages app: its top bar, chat background and NPC bubbles
const CHAT_BAR_COLOR := Color(0.27451, 0.709804, 0.690196)
const CHAT_TEXT_COLOR := Color(0.11764706, 0.18823529, 0.2784314)
const BUBBLE_BORDER_COLOR := Color(0.85882354, 0.84705883, 0.8117647)
const DATE_PILL_TEXT_COLOR := Color(0.20392157, 0.2784314, 0.36078432)
## Same look as the Email app: its text and its attachment chips
const EMAIL_TEXT_COLOR := Color(0.101960786, 0.1254902, 0.2)
const ATTACHMENT_TEXT_COLOR := Color(0.13333334, 0.28235295, 0.38431373)
## The Bank app's "Confirmar" button
const CONFIRM_COLOR := Color(1, 0.015686275, 0.2784314)
## The Bank app's "code not found" message
const BANK_TEXT_COLOR := Color(0, 0.03529412, 0.14117648)
const BANK_ERROR_COLOR := Color(0.36078432, 0.078431375, 0.2)
## Widest a bubble's text gets before wrapping, short messages keep a short bubble
const MAX_BUBBLE_TEXT_WIDTH := 216.0
## Marker run over the suspicious part of each example
const BUBBLE_MARK := "[bgcolor=#eb0a4530][color=#eb0a45][b]%s[/b][/color][/bgcolor]"
const BAR_MARK := "[bgcolor=#eb0a45][color=#fffff8]%s[/color][/bgcolor]"
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
	var rules = _load_json(RULES_PATH)
	for rule in (rules if rules is Array else []):
		rules_by_id[rule.get("id", "")] = rule

	for child in pages_holder.get_children() + dots.get_children():
		child.queue_free()
	_pages.clear()
	_pages.append(_make_rule_page(found[0]))
	var scams = _load_json(SCAMS_PATH % _day)
	for scam in (scams.get("scams", []) if scams is Dictionary else []):
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
	open_tween.parallel().tween_property(sheet, "scale", Vector2.ONE, 0.45) \
		.from(Vector2(0.85, 0.85)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
	badge_tween.tween_property(icon_badge, "scale", Vector2.ONE, 0.4) \
		.from(Vector2(0.6, 0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
		var calendar: Control = page.get_meta("calendar")
		calendar.get_meta("card").modulate.a = 0.0
		for day_column in calendar.get_meta("columns"):
			if day_column.has_meta("cross"):
				_set_cross_progress(0.0, day_column.get_meta("cross"))
			if day_column.has_meta("circle"):
				day_column.get_meta("circle").scale = Vector2.ZERO
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
		dot_tween.tween_property(dot, "self_modulate", SUCCESS_COLOR if is_current else DOT_COLOR, 0.25)


func _make_dot() -> Panel:
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", _box(Color.WHITE, 100, 0))
	dot.self_modulate = DOT_COLOR
	return dot
#endregion PAGES


#region RULE PAGE
## First page, from the day's introduction: its description typed out, the things to
## pay attention to as numbered cards and the footer pointing to the notes
func _make_rule_page(introduction: GameData.Introduction) -> Control:
	var page := _make_page("Regras do dia", "rule")
	var column: VBoxContainer = page.get_meta("column")

	var calendar := _calendar()
	column.add_child(calendar)

	var description := _rich_label(introduction.description, 16, INK_COLOR, BOLD_FONT)
	column.add_child(description)

	var rule_cards: Array[Control] = []
	var rules := introduction.rules
	for index in rules.size():
		var card := _rule_card(index + 1, rules[index])
		column.add_child(card)
		rule_cards.append(card)

	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _box(Color(SUCCESS_COLOR, 0.12), 12, 10))
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
	var footer_label := _label(introduction.footer, SEMI_FONT, 12, CHAT_BAR_COLOR.darkened(0.3))
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
	card.add_theme_stylebox_override("panel", _box(Color.WHITE, 12, 10, BUBBLE_BORDER_COLOR))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var number_disc := PanelContainer.new()
	number_disc.custom_minimum_size = Vector2(26, 26)
	number_disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	number_disc.add_theme_stylebox_override("panel", _box(SUCCESS_COLOR, 100, 0))
	var number_label := _label(str(number), BOLD_FONT, 13, CREAM_COLOR)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_disc.add_child(number_label)
	row.add_child(number_disc)

	var rule_label := _label(text.lstrip("—–- "), MEDIUM_FONT, 13, INK_COLOR)
	rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule_label)
	return card


## The description is typed out, then each card pops in and the footer fades in last
func _reveal_rule_page(page: Control) -> void:
	var description: RichTextLabel = page.get_meta("description")
	var footer: Control = page.get_meta("footer")

	_reveal_calendar(page.get_meta("calendar"))
	_reveal_tween.tween_property(description, "visible_ratio", 1.0, description.text.length() * TYPE_SECONDS)
	for card in page.get_meta("rule_cards"):
		_reveal_tween.tween_interval(0.15)
		_reveal_tween.tween_callback(_center_pivot.bind(card))
		_reveal_tween.tween_property(card, "modulate:a", 1.0, 0.2)
		_reveal_tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.35) \
			.from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_interval(0.25)
	_reveal_tween.tween_callback(_scroll_to_end.bind(page))
	_reveal_tween.tween_property(footer, "modulate:a", 1.0, 0.35)
#endregion RULE PAGE


#region CALENDAR
## The game's days as a desk calendar: month on a coloured header with the spiral rings,
## one column per day with its weekday and date, the days gone by crossed out and today
## circled. The dates follow the game's own calendar (GameData.get_current_date_dict)
func _calendar() -> MarginContainer:
	# Room around the card so today's ring, the spiral and the shadow are never clipped
	var holder := MarginContainer.new()
	holder.add_theme_constant_override("margin_left", 4)
	holder.add_theme_constant_override("margin_right", 4)
	holder.add_theme_constant_override("margin_top", 9)
	holder.add_theme_constant_override("margin_bottom", 6)

	var card := PanelContainer.new()
	var card_style := _box(Color.WHITE, 14, 0, BUBBLE_BORDER_COLOR)
	card_style.shadow_color = Color(CHAT_TEXT_COLOR, 0.1)
	card_style.shadow_size = 6
	card_style.shadow_offset = Vector2(0, 3)
	card.add_theme_stylebox_override("panel", card_style)
	holder.add_child(card)
	var card_column := VBoxContainer.new()
	card_column.add_theme_constant_override("separation", 0)
	card.add_child(card_column)

	# The spiral rings the pages hang from, poking over the header
	var rings := Control.new()
	rings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_column.add_child(rings)
	for ring_x in [0.22, 0.78]:
		var ring := Panel.new()
		ring.z_index = 1
		ring.anchor_left = ring_x
		ring.anchor_right = ring_x
		ring.offset_left = -3
		ring.offset_right = 3
		ring.offset_top = -9
		ring.offset_bottom = 7
		ring.add_theme_stylebox_override("panel", _box(CHAT_TEXT_COLOR.lightened(0.2), 3, 0))
		rings.add_child(ring)

	# Header: month and year, the days left on the right
	var today_date := _date_of_day(_day)
	var header := PanelContainer.new()
	var header_style := _box(CHAT_BAR_COLOR, 14, 0)
	header_style.corner_radius_bottom_left = 0
	header_style.corner_radius_bottom_right = 0
	header_style.content_margin_left = 12
	header_style.content_margin_right = 12
	header_style.content_margin_top = 10
	header_style.content_margin_bottom = 7
	header.add_theme_stylebox_override("panel", header_style)
	card_column.add_child(header)
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var month_label := _label("%s %d" % [MONTH_NAMES[today_date["month"] - 1], today_date["year"]], BOLD_FONT, 12, CREAM_COLOR)
	month_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(month_label)
	var days_left := LAST_DAY - _day
	var left_text := "último dia!" if days_left == 0 else "falta%s %d dia%s" % ["m" if days_left > 1 else "", days_left, "s" if days_left > 1 else ""]
	var left_label := _label(left_text, SEMI_FONT, 11, Color(CREAM_COLOR, 0.85))
	left_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	header_row.add_child(left_label)

	# One column per day of the game
	var days_margin := MarginContainer.new()
	days_margin.add_theme_constant_override("margin_left", 4)
	days_margin.add_theme_constant_override("margin_right", 4)
	days_margin.add_theme_constant_override("margin_top", 8)
	days_margin.add_theme_constant_override("margin_bottom", 9)
	card_column.add_child(days_margin)
	var days_row := HBoxContainer.new()
	days_row.add_theme_constant_override("separation", 0)
	days_margin.add_child(days_row)

	var columns: Array[Control] = []
	for day in range(1, LAST_DAY + 1):
		var day_column := _calendar_day(day)
		days_row.add_child(day_column)
		columns.append(day_column)
		if day == _day:
			holder.set_meta("today", day_column)

	holder.set_meta("card", card)
	holder.set_meta("columns", columns)
	return holder


## One day: weekday, date and the game day under it. Gone by days get a cross drawn over the
## date, today a circle behind it with a ring that keeps rippling out
func _calendar_day(day: int) -> VBoxContainer:
	var is_past := day < _day
	var is_today := day == _day
	var date := _date_of_day(day)

	var day_column := VBoxContainer.new()
	day_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_column.add_theme_constant_override("separation", 2)

	var weekday := _label(WEEKDAY_NAMES[date["weekday"]], BOLD_FONT, 9, FAILURE_COLOR if is_today else MUTED_COLOR)
	weekday.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weekday.autowrap_mode = TextServer.AUTOWRAP_OFF
	day_column.add_child(weekday)

	# The date sits on a fixed square, today's circle and ring and the cross are drawn on it
	var date_box := Control.new()
	date_box.custom_minimum_size = Vector2(30, 30)
	date_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	day_column.add_child(date_box)
	if is_today:
		var ring_style := _box(Color.TRANSPARENT, 100, 0, SUCCESS_COLOR)
		ring_style.set_border_width_all(2)
		var ring := Panel.new()
		ring.add_theme_stylebox_override("panel", ring_style)
		ring.size = Vector2(30, 30)
		ring.pivot_offset = Vector2(15, 15)
		ring.modulate.a = 0.0
		date_box.add_child(ring)
		var circle := Panel.new()
		circle.add_theme_stylebox_override("panel", _box(SUCCESS_COLOR, 100, 0))
		circle.size = Vector2(30, 30)
		circle.pivot_offset = Vector2(15, 15)
		date_box.add_child(circle)
		day_column.set_meta("ring", ring)
		day_column.set_meta("circle", circle)

	var number := _label(str(date["day"]), BOLD_FONT, 14, CREAM_COLOR if is_today else (MUTED_COLOR if is_past else INK_COLOR))
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	number.size = Vector2(30, 30)
	date_box.add_child(number)

	if is_past:
		# A green marker check, drawn stroke by stroke as "cross_progress" goes from 0 to 2
		var cross := Control.new()
		cross.size = Vector2(30, 30)
		cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cross.set_meta("cross_progress", 0.0)
		cross.draw.connect(_draw_cross.bind(cross))
		date_box.add_child(cross)
		day_column.set_meta("cross", cross)

	var game_day := _label("D%d" % day, SEMI_FONT, 9, SUCCESS_COLOR.darkened(0.2) if is_today else Color(MUTED_COLOR, 0.7))
	game_day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_day.autowrap_mode = TextServer.AUTOWRAP_OFF
	day_column.add_child(game_day)
	return day_column


func _draw_cross(cross: Control) -> void:
	var progress: float = cross.get_meta("cross_progress")
	var strokes := [[Vector2(7, 15), Vector2(13, 21)], [Vector2(13, 21), Vector2(23, 9)]]
	for index in strokes.size():
		var stroke_progress := clampf(progress - index, 0.0, 1.0)
		if stroke_progress > 0.0:
			var from: Vector2 = strokes[index][0]
			cross.draw_line(from, from.lerp(strokes[index][1], stroke_progress), Color(SUCCESS_COLOR, 0.85), 2.5, true)


func _set_cross_progress(progress: float, cross: Control) -> void:
	cross.set_meta("cross_progress", progress)
	cross.queue_redraw()


## The date of a game day, counted from today's date in the game
func _date_of_day(day: int) -> Dictionary:
	# Outside a started game (no start date yet) the real date stands in for it
	var today := GameData.get_current_date_dict() if not GameData.start_date_dict.is_empty() else Time.get_date_dict_from_system()
	var unix := Time.get_unix_time_from_datetime_dict(today) + (day - GameData.current_day) * 86400
	return Time.get_datetime_dict_from_unix_time(unix)


## The card settles in, the days gone by get crossed out one by one, then today is circled
## and its ring starts rippling
func _reveal_calendar(calendar: Control) -> void:
	var card: Control = calendar.get_meta("card")
	_reveal_tween.tween_callback(_center_pivot.bind(card))
	_reveal_tween.tween_property(card, "modulate:a", 1.0, 0.2)
	_reveal_tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.3) \
		.from(Vector2(0.94, 0.94)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	for day_column in calendar.get_meta("columns"):
		if day_column.has_meta("cross"):
			_reveal_tween.tween_method(_set_cross_progress.bind(day_column.get_meta("cross")), 0.0, 2.0, 0.25)

	var today: Control = calendar.get_meta("today", null)
	if today:
		_reveal_tween.tween_interval(0.1)
		_reveal_tween.tween_property(today.get_meta("circle"), "scale", Vector2.ONE, 0.4) \
			.from(Vector2.ZERO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_reveal_tween.tween_callback(_ripple_today.bind(today.get_meta("ring")))
	_reveal_tween.tween_interval(0.2)


## Scales and pops from the middle, measured when the animation reaches it so the layout is settled
func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size / 2


## Today's ring keeps rippling out from its circle while the page is open
func _ripple_today(ring: Control) -> void:
	var ripple := ring.create_tween().set_loops()
	ripple.tween_property(ring, "scale", Vector2(1.55, 1.55), 1.1).from(Vector2.ONE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ripple.parallel().tween_property(ring, "modulate:a", 0.0, 1.1).from(0.9)
	ripple.tween_interval(0.3)
#endregion CALENDAR


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
		var real_block := _captioned_block("Contato verdadeiro", CHAT_BAR_COLOR.darkened(0.2))
		var real_bar := _chat_bar(real.get("sender", ""), real.get("avatar", ""), real.get("verified", false))
		real_bar.add_theme_stylebox_override("panel", _box(CHAT_BAR_COLOR, 14, 0))
		real_block.add_child(real_bar)
		column.add_child(real_block)

	var example_block := _captioned_block("Golpista" if not real.is_empty() else "Exemplo", FAILURE_COLOR)
	column.add_child(example_block)
	if scam.get("app", "messages") == "email":
		example_block.add_child(_email_example(scam, page, marked_labels))
	else:
		example_block.add_child(_chat_example(scam, page, marked_labels))

	# The payment as the Bank app shows it, with what to check circled
	if scam.has("bank"):
		var bank_block := _captioned_block("No Banco", CHAT_BAR_COLOR.darkened(0.2))
		bank_block.add_child(_bank_example(scam["bank"], page))
		column.add_child(bank_block)
		page.set_meta("bank_block", bank_block)

	# What gives it away, shown once the suspicious part is marked
	var tip := PanelContainer.new()
	var tip_style := _box(Color(FAILURE_COLOR, 0.07), 12, 12)
	tip_style.border_width_left = 3
	tip_style.border_color = FAILURE_COLOR
	tip.add_theme_stylebox_override("panel", tip_style)
	var tip_column := VBoxContainer.new()
	tip_column.add_theme_constant_override("separation", 2)
	tip.add_child(tip_column)
	tip_column.add_child(_label("Como identificar", BOLD_FONT, 12, FAILURE_COLOR))
	tip_column.add_child(_label(scam.get("tip", rule.get("description", "")), REGULAR_FONT, 12, INK_COLOR))
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
	var bar := _chat_bar(scam.get("sender", ""), scam.get("avatar", ""), false)
	bar.add_theme_stylebox_override("panel", _top_box(CHAT_BAR_COLOR, 0))
	chat.add_child(bar)
	marked_labels.append(bar.get_meta("name_label"))

	var canvas := PanelContainer.new()
	canvas.add_theme_stylebox_override("panel", _bottom_box(CREAM_COLOR, 8))
	chat.add_child(canvas)
	var messages_list := VBoxContainer.new()
	messages_list.add_theme_constant_override("separation", 5)
	canvas.add_child(messages_list)
	messages_list.add_child(_date_pill())

	var bubbles: Array[Control] = []
	var messages: Array = scam.get("messages", [])
	for index in messages.size():
		var bubble := _chat_bubble(messages[index], "09:%02d" % (41 + index))
		messages_list.add_child(bubble)
		bubbles.append(bubble)
		marked_labels.append(bubble.get_meta("text_label"))
	var typing := _chat_bubble("", "")
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
func _email_example(scam: Dictionary, page: Control, marked_labels: Array[RichTextLabel]) -> Control:
	var email := VBoxContainer.new()
	email.add_theme_constant_override("separation", 0)
	email.add_child(_app_bar("Email"))

	var canvas := PanelContainer.new()
	canvas.add_theme_stylebox_override("panel", _bottom_box(CREAM_COLOR, 12))
	email.add_child(canvas)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	canvas.add_child(body)

	var subject := _rich_label(scam.get("subject", ""), 15, INK_COLOR, BOLD_FONT)
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
	var sender := _rich_label(sender_name, 12, INK_COLOR, BOLD_FONT)
	sender.set_meta("mark", BUBBLE_MARK)
	sender_column.add_child(sender)
	marked_labels.append(sender)
	sender_column.add_child(_label("para mim", REGULAR_FONT, 11, MUTED_COLOR))
	var time := _label("09:41", MEDIUM_FONT, 10, MUTED_COLOR)
	time.autowrap_mode = TextServer.AUTOWRAP_OFF
	time.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sender_row.add_child(time)

	var content := _rich_label("\n".join(scam.get("messages", [])), 13, EMAIL_TEXT_COLOR)
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
			var chip_style := _box(Color(SUCCESS_COLOR, 0.22), 100, 0)
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
			var chip_label := _rich_label(str(attachment), 11, ATTACHMENT_TEXT_COLOR, SEMI_FONT)
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
		_reveal_tween.parallel().tween_property(bubble, "scale", Vector2.ONE, 0.3) \
			.from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_reveal_tween.tween_interval(0.2)

	_reveal_tween.tween_interval(0.2)
	_reveal_tween.tween_callback(_mark_suspicious.bind(page))
	_reveal_tween.tween_interval(0.35)

	if page.has_meta("bank_block"):
		_reveal_tween.tween_callback(_scroll_to_end.bind(page))
		_reveal_tween.tween_property(page.get_meta("bank_block"), "modulate:a", 1.0, 0.3)
		_reveal_tween.tween_interval(0.3)
		for circle in page.get_meta("bank_circles"):
			_reveal_tween.tween_method(_set_circle_progress.bind(circle), 0.0, 1.0, 0.55) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_reveal_tween.tween_interval(0.15)

	_reveal_tween.tween_callback(_scroll_to_end.bind(page))
	_reveal_tween.tween_property(tip, "modulate:a", 1.0, 0.3)


## Slides the page down to its end when the content doesn't fit, so the tip comes into view
func _scroll_to_end(page: ScrollContainer) -> void:
	# Measured a frame later: what was just shown (or all of it, when skipped) has to be laid out first
	await get_tree().process_frame
	var end := int(page.get_v_scroll_bar().max_value - page.size.y)
	if end > page.scroll_vertical:
		create_tween().tween_property(page, "scroll_vertical", end, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


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
	screen.add_child(_app_bar("Banco"))
	var canvas := PanelContainer.new()
	canvas.add_theme_stylebox_override("panel", _bottom_box(CREAM_COLOR, 12))
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
	confirm.add_theme_stylebox_override("panel", _box(CONFIRM_COLOR, 17, 0))
	var confirm_label := _label("Confirmar", BOLD_FONT, 15, Color.WHITE)
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
	var not_found := _label("O código digitado \"%s\" não foi encontrado." % code, REGULAR_FONT, 14, BANK_TEXT_COLOR)
	not_found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(not_found)
	var check := _label("Confira se a informação está correta!", BOLD_FONT, 12, BANK_ERROR_COLOR)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(check)
	return message


## The fields the Bank app shows for a code from the game's bank data, empty when the code isn't there
func _bank_fields(is_pix: bool, code: String) -> Array:
	var codes = _load_json(PIX_CODES_PATH if is_pix else TICKET_CODES_PATH)
	var info: Dictionary = codes.get(code, {}) if codes is Dictionary else {}
	if info.is_empty():
		return []
	if is_pix:
		return [["Nome", info["name"]], ["CPF", info["cpf"]], ["Email", info["email"]], ["Valor", GameData.format_brl(info["value"])]]
	return [["Instituição Pagadora", info["institution"]], ["Valor", GameData.format_brl(info["value"])]]


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



#region CHAT BUILDERS
## The Messages app's top bar for a contact: back arrow, avatar with its badge, name
func _chat_bar(contact_name: String, avatar: String, verified: bool) -> PanelContainer:
	var bar := PanelContainer.new()
	var bar_margin := MarginContainer.new()
	bar_margin.add_theme_constant_override("margin_left", 8)
	bar_margin.add_theme_constant_override("margin_right", 10)
	bar.add_child(bar_margin)
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 40
	row.add_theme_constant_override("separation", 9)
	bar_margin.add_child(row)

	var back := TextureRect.new()
	back.texture = BACK_ICON
	back.custom_minimum_size = Vector2(12, 16)
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)

	var avatar_holder := Control.new()
	avatar_holder.custom_minimum_size = Vector2(32, 32)
	avatar_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(avatar_holder)
	var picture: Control = PROFILE_PICTURE.instantiate()
	picture.custom_minimum_size = Vector2(32, 32)
	avatar_holder.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.setup(AVATAR_PATH % (avatar if avatar != "" else contact_name), contact_name)
	if verified:
		# Same badge as the app: a cream disc on the avatar's corner with the check inside
		var badge := Panel.new()
		badge.position = Vector2(19, 19)
		badge.size = Vector2(14, 14)
		badge.add_theme_stylebox_override("panel", _box(CREAM_COLOR, 100, 0))
		var badge_icon := TextureRect.new()
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_icon.texture = VERIFIED_ICON
		badge_icon.position = Vector2(1.5, 1.5)
		badge_icon.size = Vector2(11, 11)
		badge.add_child(badge_icon)
		avatar_holder.add_child(badge)

	var name_label := _rich_label(contact_name, 15, CREAM_COLOR, BOLD_FONT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.set_meta("mark", BAR_MARK)
	row.add_child(name_label)

	bar.set_meta("name_label", name_label)
	return bar


## An NPC message bubble, same style as the app's: white, rounded but for the corner it
## comes from, the time under the text
func _chat_bubble(text: String, time: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_border_width_all(1)
	style.border_color = BUBBLE_BORDER_COLOR
	style.set_corner_radius_all(18)
	style.corner_radius_bottom_left = 6
	style.corner_detail = 10
	style.shadow_color = Color(CHAT_TEXT_COLOR, 0.07)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	bubble.add_theme_stylebox_override("panel", style)
	row.add_child(bubble)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	bubble.add_child(column)
	var text_label := _rich_label(text, 13, CHAT_TEXT_COLOR)
	text_label.set_meta("mark", BUBBLE_MARK)
	# Short messages keep a short bubble, long ones wrap at the app's width
	var text_width := REGULAR_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 2.0
	text_label.custom_minimum_size.x = minf(text_width, MAX_BUBBLE_TEXT_WIDTH)
	column.add_child(text_label)
	var time_label := _label(time, MEDIUM_FONT, 10, MUTED_COLOR)
	time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(time_label)

	row.set_meta("text_label", text_label)
	row.set_meta("column", column)
	return row


## An app's top bar showing only the app's name, as the Email app does
func _app_bar(title: String) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _top_box(CHAT_BAR_COLOR, 0))
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 40
	row.add_theme_constant_override("separation", 12)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_child(row)
	bar.add_child(margin)
	var back := TextureRect.new()
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back.texture = BACK_ICON
	back.custom_minimum_size = Vector2(12, 16)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	var title_label := _label(title, BOLD_FONT, 15, CREAM_COLOR)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title_label)
	return bar


## The top half of an app window: rounded on top, square where its body joins
func _top_box(color: Color, margin: int) -> StyleBoxFlat:
	var style := _box(color, 14, margin)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


## The body of an app window under its top bar: square on top, rounded and bordered below
func _bottom_box(color: Color, margin: int) -> StyleBoxFlat:
	var style := _box(color, 14, margin, BUBBLE_BORDER_COLOR)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.border_width_top = 0
	return style


## The "Hoje" pill the app shows above the day's messages
func _date_pill() -> CenterContainer:
	var center := CenterContainer.new()
	var pill := PanelContainer.new()
	var style := _box(Color(CHAT_TEXT_COLOR, 0.1), 11, 0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)
	var label := _label("Hoje", SEMI_FONT, 11, DATE_PILL_TEXT_COLOR)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill.add_child(label)
	center.add_child(pill)
	return center
#endregion CHAT BUILDERS


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


func _captioned_block(caption: String, color: Color) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 5)
	block.add_child(_label(caption.to_upper(), BOLD_FONT, 10, color))
	return block


func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _rich_label(text: String, font_size: int, color: Color, font: Font = REGULAR_FONT) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_override("bold_font", BOLD_FONT)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_color_override("default_color", color)
	return label


func _box(color: Color, radius: int, margin: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.set_content_margin_all(margin)
	if border.a > 0.0:
		style.set_border_width_all(1)
		style.border_color = border
	return style
#endregion BUILDERS


## Gently breathes the button on the last page so the player knows the day starts there
func _pulse_next_button() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(next_button, "scale", Vector2(1.04, 1.04), 0.6).set_trans(Tween.TRANS_SINE)
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
	exit_tween.tween_property(sheet, "scale", Vector2(0.9, 0.9), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
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
