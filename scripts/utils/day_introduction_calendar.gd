## The game's days as a desk calendar, on top of the day introduction's rule page: month on a
## coloured header with the spiral rings, one column per day with its weekday and date, the days
## gone by crossed out and today circled. The dates follow the game's own calendar
## (GameData.get_current_date_dict)
extends MarginContainer

const IntroBuilders = preload("res://scripts/utils/day_introduction_builders.gd")
## Last day of the game, its end rolls the credits (see day_over_ui.gd). Day 0 is the
## tutorial, so the calendar shows days 1 to this one
const LAST_DAY := 7
const BOLD_FONT = IntroBuilders.BOLD_FONT
const SEMI_FONT = IntroBuilders.SEMI_FONT
const INK_COLOR = IntroBuilders.INK_COLOR
const MUTED_COLOR = IntroBuilders.MUTED_COLOR
const CREAM_COLOR = IntroBuilders.CREAM_COLOR
const SUCCESS_COLOR = IntroBuilders.SUCCESS_COLOR
const FAILURE_COLOR = IntroBuilders.FAILURE_COLOR
const CHAT_BAR_COLOR = IntroBuilders.CHAT_BAR_COLOR
const CHAT_TEXT_COLOR = IntroBuilders.CHAT_TEXT_COLOR
const BUBBLE_BORDER_COLOR = IntroBuilders.BUBBLE_BORDER_COLOR

## The day being introduced, circled on the calendar
var _day := 0
var _card: PanelContainer
var _columns: Array[Control] = []
var _today: Control


## Builds the calendar with the given game day as today
func setup(today: int) -> void:
	_day = today
	# Room around the card so today's ring, the spiral and the shadow are never clipped
	add_theme_constant_override("margin_left", 4)
	add_theme_constant_override("margin_right", 4)
	add_theme_constant_override("margin_top", 9)
	add_theme_constant_override("margin_bottom", 6)

	_card = PanelContainer.new()
	var card_style := IntroBuilders.box(Color.WHITE, 14, 0, BUBBLE_BORDER_COLOR)
	card_style.shadow_color = Color(CHAT_TEXT_COLOR, 0.1)
	card_style.shadow_size = 6
	card_style.shadow_offset = Vector2(0, 3)
	_card.add_theme_stylebox_override("panel", card_style)
	add_child(_card)
	var card_column := VBoxContainer.new()
	card_column.add_theme_constant_override("separation", 0)
	_card.add_child(card_column)

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
		ring.add_theme_stylebox_override(
			"panel", IntroBuilders.box(CHAT_TEXT_COLOR.lightened(0.2), 3, 0)
		)
		rings.add_child(ring)

	card_column.add_child(_header())

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

	for day in range(1, LAST_DAY + 1):
		var day_column := _calendar_day(day)
		days_row.add_child(day_column)
		_columns.append(day_column)
		if day == _day:
			_today = day_column


## Puts the calendar back to before its animation: card hidden, nothing crossed nor circled
func prepare() -> void:
	_card.modulate.a = 0.0
	for day_column in _columns:
		if day_column.has_meta("cross"):
			_set_cross_progress(0.0, day_column.get_meta("cross"))
		if day_column.has_meta("circle"):
			day_column.get_meta("circle").scale = Vector2.ZERO


## The card settles in, the days gone by get crossed out one by one, then today is circled
## and its ring starts rippling
##
## tween: The page's reveal, the calendar's steps are queued on it
func reveal(tween: Tween) -> void:
	tween.tween_callback(func(): _card.pivot_offset = _card.size / 2)
	tween.tween_property(_card, "modulate:a", 1.0, 0.2)
	(
		tween
		. parallel()
		. tween_property(_card, "scale", Vector2.ONE, 0.3)
		. from(Vector2(0.94, 0.94))
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)

	for day_column in _columns:
		if day_column.has_meta("cross"):
			tween.tween_method(
				_set_cross_progress.bind(day_column.get_meta("cross")), 0.0, 2.0, 0.25
			)

	if _today:
		tween.tween_interval(0.1)
		(
			tween
			. tween_property(_today.get_meta("circle"), "scale", Vector2.ONE, 0.4)
			. from(Vector2.ZERO)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		tween.tween_callback(_ripple_today.bind(_today.get_meta("ring")))
	tween.tween_interval(0.2)


## Header: month and year, the days left on the right
func _header() -> PanelContainer:
	var today_date := _date_of_day(_day)
	var header := PanelContainer.new()
	var header_style := IntroBuilders.box(CHAT_BAR_COLOR, 14, 0)
	header_style.corner_radius_bottom_left = 0
	header_style.corner_radius_bottom_right = 0
	header_style.content_margin_left = 12
	header_style.content_margin_right = 12
	header_style.content_margin_top = 10
	header_style.content_margin_bottom = 7
	header.add_theme_stylebox_override("panel", header_style)
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var month_label := IntroBuilders.label(
		"%s %d" % [GameData.month_name(today_date).to_upper(), today_date["year"]],
		BOLD_FONT,
		12,
		CREAM_COLOR
	)
	month_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(month_label)
	var days_left := LAST_DAY - _day
	var left_text := (
		"último dia!"
		if days_left == 0
		else (
			"falta%s %d dia%s"
			% ["m" if days_left > 1 else "", days_left, "s" if days_left > 1 else ""]
		)
	)
	var left_label := IntroBuilders.label(left_text, SEMI_FONT, 11, Color(CREAM_COLOR, 0.85))
	left_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	header_row.add_child(left_label)
	return header


## One day: weekday, date and the game day under it. Gone by days get a cross drawn over the
## date, today a circle behind it with a ring that keeps rippling out
func _calendar_day(day: int) -> VBoxContainer:
	var is_past := day < _day
	var is_today := day == _day
	var date := _date_of_day(day)

	var day_column := VBoxContainer.new()
	day_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_column.add_theme_constant_override("separation", 2)

	var weekday := IntroBuilders.label(
		GameData.weekday_name(date).left(3).to_upper(),
		BOLD_FONT,
		9,
		FAILURE_COLOR if is_today else MUTED_COLOR
	)
	weekday.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weekday.autowrap_mode = TextServer.AUTOWRAP_OFF
	day_column.add_child(weekday)

	# The date sits on a fixed square, today's circle and ring and the cross are drawn on it
	var date_box := Control.new()
	date_box.custom_minimum_size = Vector2(30, 30)
	date_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	day_column.add_child(date_box)
	if is_today:
		var ring_style := IntroBuilders.box(Color.TRANSPARENT, 100, 0, SUCCESS_COLOR)
		ring_style.set_border_width_all(2)
		var ring := Panel.new()
		ring.add_theme_stylebox_override("panel", ring_style)
		ring.size = Vector2(30, 30)
		ring.pivot_offset = Vector2(15, 15)
		ring.modulate.a = 0.0
		date_box.add_child(ring)
		var circle := Panel.new()
		circle.add_theme_stylebox_override("panel", IntroBuilders.box(SUCCESS_COLOR, 100, 0))
		circle.size = Vector2(30, 30)
		circle.pivot_offset = Vector2(15, 15)
		date_box.add_child(circle)
		day_column.set_meta("ring", ring)
		day_column.set_meta("circle", circle)

	var number := IntroBuilders.label(
		str(date["day"]),
		BOLD_FONT,
		14,
		CREAM_COLOR if is_today else (MUTED_COLOR if is_past else INK_COLOR)
	)
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

	var game_day := IntroBuilders.label(
		"D%d" % day,
		SEMI_FONT,
		9,
		SUCCESS_COLOR.darkened(0.2) if is_today else Color(MUTED_COLOR, 0.7)
	)
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
			cross.draw_line(
				from,
				from.lerp(strokes[index][1], stroke_progress),
				Color(SUCCESS_COLOR, 0.85),
				2.5,
				true
			)


func _set_cross_progress(progress: float, cross: Control) -> void:
	cross.set_meta("cross_progress", progress)
	cross.queue_redraw()


## The date of a game day, counted from today's date in the game
func _date_of_day(day: int) -> Dictionary:
	# Outside a started game (no start date yet) the real date stands in for it
	var today := (
		GameData.get_current_date_dict()
		if not GameData.start_date_dict.is_empty()
		else Time.get_date_dict_from_system()
	)
	var unix := Time.get_unix_time_from_datetime_dict(today) + (day - GameData.current_day) * 86400
	return Time.get_datetime_dict_from_unix_time(unix)


## Today's ring keeps rippling out from its circle while the page is open
func _ripple_today(ring: Control) -> void:
	var ripple := ring.create_tween().set_loops()
	(
		ripple
		. tween_property(ring, "scale", Vector2(1.55, 1.55), 1.1)
		. from(Vector2.ONE)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	ripple.parallel().tween_property(ring, "modulate:a", 0.0, 1.1).from(0.9)
	ripple.tween_interval(0.3)
