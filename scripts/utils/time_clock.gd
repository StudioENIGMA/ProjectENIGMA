extends VBoxContainer

@export var large_size:int = 80
@export var small_size:int = 30

#region CHILDREN NODES REFERENCES
@export var time_label: Label
@export var weekday_label: Label
#endregion

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
