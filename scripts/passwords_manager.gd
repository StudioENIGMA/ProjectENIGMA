extends Node2D

@onready var mensagens = $Control/Panel/VBoxContainer/app_password
@onready var background = $Control/Panel
@onready var vbox = $Control/Panel/VBoxContainer
@onready var close_button = $Control/Panel/close

@onready var password_changer = load("res://scenes/phone_settings/change_password.tscn")
@onready var none_password_label = Label.new()

var vbox_height

func _ready() -> void:
	check_passwords()
	
	if vbox.get_child(0) == null:
		none_password_added()
	
	EventBus.first_correct_password.connect(_on_first_password_emitted)
	close_button.pressed.connect(_on_close_button_pressed)

func check_passwords() -> void:
	for child in vbox.get_children():
		child.queue_free()
	
	for key in GameData.data.passwords.keys():
		var password = GameData.data.passwords[key]
		if not password == "":
			instantiate_password(password, key)

func _process(delta: float) -> void:
	pass
	
func _on_first_password_emitted(new_password : String, app_name : String) -> void:
	instantiate_password(new_password, app_name)
	GameData.data.passwords[app_name] = new_password
	check_passwords()
	#TODO change icon based in wich app was created
	
func none_password_added() -> void:
	background.add_child(none_password_label)

	none_password_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	none_password_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	none_password_label.custom_minimum_size = Vector2(1000, 200)
		
	none_password_label.text = "Você não possui nenhuma senha cadastrada"
	none_password_label.add_theme_font_size_override("font_size", 50)
	
	var custom_font = FontFile.new()
	custom_font.font_data = load("res://assets/fonts/IBMPlexSans-Regular.ttf")
	none_password_label.add_theme_font_override("font", custom_font)
	
	label_position(none_password_label)

func instantiate_password(new_password : String, app_name : String) -> void:
	if vbox.get_child(0) == null:
		none_password_label.hide()
	
	var password_box = load("res://scenes/phone_settings/password.tscn")
	var password_box_instance = password_box.instantiate()
	
	vbox.add_child(password_box_instance)
	
	password_box_instance.setup(new_password, app_name)	
	
func label_position(label : Label) -> void:
	label.position = Vector2((1080 - label.size.x) / 2, 1000)

func _on_close_button_pressed() -> void:
	self.hide()
	
