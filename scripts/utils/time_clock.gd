extends RichTextLabel

var current_weekday_int:int = 4
var current_weekday_string:String = "Quinta"
var current_month_string:String = "Setembro" # Hardcoded for now, probably won't change in-game
var current_day:int = 11 + GameData.data.current_day # Start at 11th

func update_weekday(day_increment:int) -> void:
	# Update the current_day
	current_day = current_day + day_increment

	# Update the current_weekday_string
	current_weekday_int = (current_weekday_int + day_increment) % 7
	match current_weekday_int:
		1:
			current_weekday_string = "Segunda"
		2:
			current_weekday_string = "Terça"
		3:
			current_weekday_string = "Quarta"
		4:
			current_weekday_string = "Quinta"
		5:
			current_weekday_string = "Sexta"
		6:
			current_weekday_string = "Sábado"
		0:
			current_weekday_string = "Domingo"

func update_clock_display(current_hour:int, current_minute:int) -> void:
	# Format time with leading zeros
	var hours:String = str(current_hour % 24) if current_hour >= 10 else "0" + str(current_hour)

	# Format minutes with leading zeros
	var minutes:String = str(current_minute) if current_minute >= 10 else "0" + str(current_minute)

	# Combine hours and minutes
	var hour_string  = hours + ":" + minutes

	# Set font sizes
	var font_large = "[font n=res://assets/fonts/IBMPlexSans-ExtraLight.ttf size=\"150\"]"
	var font_small = "[font n=res://assets/fonts/IBMPlexSans-ExtraLight.ttf size=\"40\"]"

	# Update the RichTextLabel content
	self.text = font_large + hour_string + "[/font]" + font_small + "\n"
	self.text += current_weekday_string.left(3) + ", " + str(current_day) + " " + current_month_string
	self.text += "[/font]"
