extends Control

@export var time_label: Label

func setup(date_dict: Dictionary) -> void:
	if date_dict["day"] == GameData.get_current_date_dict()["day"]:
		time_label.text = "Hoje"
	else:
		time_label.text = "%02d/%02d" % [date_dict["day"], date_dict["month"]]
