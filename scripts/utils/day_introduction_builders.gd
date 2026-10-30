## Builders of the pieces the day introduction draws its example screens with: labels,
## boxes and the Messages and Email apps' bars and bubbles, in the look of those apps
extends RefCounted

const AVATAR_PATH := "res://assets/avatars/%s.png"
const PROFILE_PICTURE = preload("res://scenes/apps/messages/profile_picture.tscn")
const VERIFIED_ICON = preload("res://assets/icons/verified.svg")
const BACK_ICON = preload("res://assets/icons/back_light.svg")
const BOLD_FONT = preload("res://assets/fonts/IBMPlexSans-Bold.ttf")
const SEMI_FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const MEDIUM_FONT = preload("res://assets/fonts/IBMPlexSans-Medium.ttf")
const REGULAR_FONT = preload("res://assets/fonts/IBMPlexSans-Regular.ttf")
const INK_COLOR := Color(0.09019608, 0.10980392, 0.18039216)
const SUCCESS_COLOR := Color(0.30980393, 0.79607844, 0.68235296)
const FAILURE_COLOR := Color(0.92156863, 0.039215688, 0.27058825)
const MUTED_COLOR := Color(0.43137255, 0.44313726, 0.5019608)
const CREAM_COLOR := Color(1, 1, 0.972549)
## Same look as the Messages app: its top bar, chat background and NPC bubbles
const CHAT_BAR_COLOR := Color(0.27451, 0.709804, 0.690196)
const CHAT_TEXT_COLOR := Color(0.11764706, 0.18823529, 0.2784314)
const BUBBLE_BORDER_COLOR := Color(0.85882354, 0.84705883, 0.8117647)
const DATE_PILL_TEXT_COLOR := Color(0.20392157, 0.2784314, 0.36078432)
## Widest a bubble's text gets before wrapping, short messages keep a short bubble
const MAX_BUBBLE_TEXT_WIDTH := 216.0
## Marker run over the suspicious part of each example
const BUBBLE_MARK := "[bgcolor=#eb0a4530][color=#eb0a45][b]%s[/b][/color][/bgcolor]"
const BAR_MARK := "[bgcolor=#eb0a45][color=#fffff8]%s[/color][/bgcolor]"


## The Messages app's top bar for a contact: back arrow, avatar with its badge, name
static func chat_bar(contact_name: String, avatar: String, verified: bool) -> PanelContainer:
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
		badge.add_theme_stylebox_override("panel", box(CREAM_COLOR, 100, 0))
		var badge_icon := TextureRect.new()
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_icon.texture = VERIFIED_ICON
		badge_icon.position = Vector2(1.5, 1.5)
		badge_icon.size = Vector2(11, 11)
		badge.add_child(badge_icon)
		avatar_holder.add_child(badge)

	var name_label := rich_label(contact_name, 15, CREAM_COLOR, BOLD_FONT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.set_meta("mark", BAR_MARK)
	row.add_child(name_label)

	bar.set_meta("name_label", name_label)
	return bar


## An NPC message bubble, same style as the app's: white, rounded but for the corner it
## comes from, the time under the text
static func chat_bubble(text: String, time: String) -> HBoxContainer:
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
	var text_label := rich_label(text, 13, CHAT_TEXT_COLOR)
	text_label.set_meta("mark", BUBBLE_MARK)
	# Short messages keep a short bubble, long ones wrap at the app's width
	var text_width := REGULAR_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 2.0
	text_label.custom_minimum_size.x = minf(text_width, MAX_BUBBLE_TEXT_WIDTH)
	column.add_child(text_label)
	var time_label := label(time, MEDIUM_FONT, 10, MUTED_COLOR)
	time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(time_label)

	row.set_meta("text_label", text_label)
	row.set_meta("column", column)
	return row


## An app's top bar showing only the app's name, as the Email app does
static func app_bar(title: String) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", top_box(CHAT_BAR_COLOR, 0))
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
	var title_label := label(title, BOLD_FONT, 15, CREAM_COLOR)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title_label)
	return bar


## The top half of an app window: rounded on top, square where its body joins
static func top_box(color: Color, margin: int) -> StyleBoxFlat:
	var style := box(color, 14, margin)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


## The body of an app window under its top bar: square on top, rounded and bordered below
static func bottom_box(color: Color, margin: int) -> StyleBoxFlat:
	var style := box(color, 14, margin, BUBBLE_BORDER_COLOR)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.border_width_top = 0
	return style


## The "Hoje" pill the app shows above the day's messages
static func date_pill() -> CenterContainer:
	var center := CenterContainer.new()
	var pill := PanelContainer.new()
	var style := box(Color(CHAT_TEXT_COLOR, 0.1), 11, 0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)
	var label := label("Hoje", SEMI_FONT, 11, DATE_PILL_TEXT_COLOR)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill.add_child(label)
	center.add_child(pill)
	return center


static func captioned_block(caption: String, color: Color) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 5)
	block.add_child(label(caption.to_upper(), BOLD_FONT, 10, color))
	return block


static func label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func rich_label(
	text: String, font_size: int, color: Color, font: Font = REGULAR_FONT
) -> RichTextLabel:
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


static func box(
	color: Color, radius: int, margin: int, border := Color.TRANSPARENT
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.set_content_margin_all(margin)
	if border.a > 0.0:
		style.set_border_width_all(1)
		style.border_color = border
	return style
