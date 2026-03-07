extends Control

@export var time_label: Label

func setup(date_dict: Dictionary) -> void:
	#if date_dict["day"] == GameDat
	time_label.text = "%s/%s" % [date_dict["day"], date_dict["month"]]
