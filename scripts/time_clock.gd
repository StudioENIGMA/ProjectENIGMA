extends RichTextLabel

func _physics_process(_delta: float) -> void:
	var datetime = Time.get_datetime_dict_from_system()
	var weekday : String
	match datetime["weekday"]:
		1:
			weekday = "Monday"
		2:
			weekday = "Tuesday"
		3:
			weekday = "Wednesday"
		4:
			weekday = "Thursday"
		5:
			weekday = "Friday"
		6:
			weekday = "Saturday"
		0:
			weekday = "Sunday"
	var month : String
	match datetime["month"]:
		1:
			month = "January"
		2:
			month = "February"
		3:
			month = "March"
		4:
			month = "April"
		5:
			month = "May"
		6:
			month = "June"
		7:
			month = "July"
		8:
			month = "August"
		9:
			month = "September"
		10:
			month = "October"
		11:
			month = "November"
		12:
			month = "December"
	var hours = datetime["hour"]
	var minutes = str(datetime["minute"]) if datetime["minute"] >= 10 else "0" + str(datetime["minute"])
	var ampm = "PM" if hours > 12 else "AM"
	self.text = "[font n=res://assets/fonts/IBMPlexSans-ExtraLight.ttf size=\"150\"]" + str(hours % 12) + ":" + minutes + "[/font][font n=res://assets/fonts/IBMPlexSans-ExtraLight.ttf size=\"40\"]" + ampm +"\n"
	self.text += weekday.left(3) + ", " + str(datetime["day"]) + " " + month + "[/font]"
