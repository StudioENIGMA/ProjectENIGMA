extends Control

@export var time_label: Label

func setup(date_dict: Dictionary) -> void:
	if date_dict["day"] == GameData.get_current_date_dict()["day"]:
		time_label.text = "Hoje"
	else:
		var day_string = "%d" % date_dict["day"]
		@warning_ignore("integer_division")
		if int(date_dict["day"]) / int(10) < 1:
			day_string = "0" + day_string

		var month_string = "%d" % date_dict["month"]
		@warning_ignore("integer_division")
		if int(date_dict["month"]) / int(10) < 1:
			month_string = "0" + month_string

		time_label.text = "%s/%s" % [day_string, month_string]
