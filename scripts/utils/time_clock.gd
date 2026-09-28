extends VBoxContainer

## Minutes before the end of the workday when the bar turns into an alert
const WORKDAY_WARNING_MINUTES: int = 60
const MINT = Color(0.30980393, 0.79607844, 0.68235296)
const LIGHT_MINT = Color(0.44705883, 0.87450981, 0.7294118)
const CRIMSON = Color(0.92156863, 0.039215688, 0.27058825)

@export var large_size:int = 80
@export var small_size:int = 30

#region CHILDREN NODES REFERENCES
@export var time_label: Label
@export var weekday_label: Label
## Optional: how much of the workday has passed and how much is left
@export var workday_bar: Range
@export var workday_label: Label
#endregion

## The bar's own copy of its fill, recolored as the workday ends
var _workday_fill: StyleBoxFlat

func get_date_string() -> String:
	var current_date_dict = GameData.get_current_date_dict()

	var current_weekday_string = ""
	# Update the current_weekday_string
	match current_date_dict["weekday"]:
		Time.Weekday.WEEKDAY_MONDAY:
			current_weekday_string = "Segunda"
		Time.Weekday.WEEKDAY_TUESDAY:
			current_weekday_string = "Terça"
		Time.Weekday.WEEKDAY_WEDNESDAY:
			current_weekday_string = "Quarta"
		Time.Weekday.WEEKDAY_THURSDAY:
			current_weekday_string = "Quinta"
		Time.Weekday.WEEKDAY_FRIDAY:
			current_weekday_string = "Sexta"
		Time.Weekday.WEEKDAY_SATURDAY:
			current_weekday_string = "Sábado"
		Time.Weekday.WEEKDAY_SUNDAY:
			current_weekday_string = "Domingo"

	var current_month_string = ""
	# Update the current_weekday_string
	match current_date_dict["month"]:
		Time.Month.MONTH_JANUARY:
			current_month_string = "Janeiro"
		Time.Month.MONTH_FEBRUARY:
			current_month_string = "Fevereiro"
		Time.Month.MONTH_MARCH:
			current_month_string = "Março"
		Time.Month.MONTH_APRIL:
			current_month_string = "Abril"
		Time.Month.MONTH_MAY:
			current_month_string = "Maio"
		Time.Month.MONTH_JUNE:
			current_month_string = "Junho"
		Time.Month.MONTH_JULY:
			current_month_string = "Julho"
		Time.Month.MONTH_AUGUST:
			current_month_string = "Agosto"
		Time.Month.MONTH_SEPTEMBER:
			current_month_string = "Setembro"
		Time.Month.MONTH_OCTOBER:
			current_month_string = "Outubro"
		Time.Month.MONTH_NOVEMBER:
			current_month_string = "Novembro"
		Time.Month.MONTH_DECEMBER:
			current_month_string = "Dezembro"

	return "%s, %s %s" % [current_weekday_string, str(current_date_dict["day"]), current_month_string]

func update_clock_display(current_hour:int, current_minute:int) -> void:
	# Format time with leading zeros
	var hours:String = str(current_hour % 24) if current_hour >= 10 else "0" + str(current_hour)

	# Format minutes with leading zeros
	var minutes:String = str(current_minute) if current_minute >= 10 else "0" + str(current_minute)

	# Combine hours and minutes
	var hour_string  = hours + ":" + minutes

	# Update the RichTextLabel content
	time_label.text = hour_string
	weekday_label.text = get_date_string()
	_update_workday(current_hour * 60 + current_minute)

func _update_workday(current_minutes: int) -> void:
	if workday_bar == null or workday_label == null:
		return

	# The tutorial day ends earlier
	var day_end: int = GameData.max_hours_minutes
	if GameData.current_day == 0:
		day_end = GameData.max_hours_minutes_tutorial
	var day_start: int = GameData.starting_hours_minutes

	workday_bar.value = clampf(
		float(current_minutes - day_start) / float(day_end - day_start), 0.0, 1.0
	)

	var minutes_left: int = maxi(day_end - current_minutes, 0)
	_set_workday_warning(minutes_left <= WORKDAY_WARNING_MINUTES)
	if minutes_left % 60 == 0:
		workday_label.text = "restam %dh" % (minutes_left / 60)
	elif minutes_left < 60:
		workday_label.text = "restam %dmin" % minutes_left
	else:
		workday_label.text = "restam %dh%02d" % [minutes_left / 60, minutes_left % 60]

## Paints the bar and the countdown crimson when the workday is about to end
func _set_workday_warning(is_warning: bool) -> void:
	if _workday_fill == null:
		_workday_fill = workday_bar.get_theme_stylebox("fill").duplicate()
		workday_bar.add_theme_stylebox_override("fill", _workday_fill)
	_workday_fill.bg_color = CRIMSON if is_warning else MINT
	workday_label.add_theme_color_override("font_color", CRIMSON if is_warning else LIGHT_MINT)
