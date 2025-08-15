extends RichTextLabel

func _process(_delta: float) -> void:
	var timer = $"../../Timer"
	
	var current_day_minutes : float = -timer.get_time_left() + 1080
	
	var current_hour : int = int(current_day_minutes) / 60 
	var current_minute : int = int(current_day_minutes) % 60 
	
	var day : String = str(11 + GameData.data.current_day)
	
	var weekday_int : int = 4 + GameData.data.current_day % 6
	var weekday : String
	match weekday_int:
		1:
			weekday = "Segunda"
		2:
			weekday = "Terça"
		3:
			weekday = "Quarta"
		4:
			weekday = "Quinta"
		5:
			weekday = "Sexta"
		6:
			weekday = "Sábado"
		0:
			weekday = "Domingo"
			
	var month : String = "Setembro"
	
	var hours : String = str(current_hour) if current_hour >= 10 else "0" + str(current_hour)
	var minutes : String = str(current_minute) if current_minute >= 10 else "0" + str(current_minute)

	self.text = "[font n=res://assets/fonts/IBMPlexSans-Light.ttf size=\"150\"]" + hours + ":" + minutes + "[/font][font n=res://assets/fonts/IBMPlexSans-Regular.ttf size=\"40\"]\n"
	self.text += weekday.left(3) + ", " + day + " " + month + "[/font]"
