extends Node2D

@onready var mensagens = $Control/Panel/VBoxContainer/app_password
@onready var background = $Control/Panel
@onready var vbox = $Control/Panel/VBoxContainer
@onready var close_button = $Control/Panel/close

@onready var password_changer = load("res://scenes/phone_settings/change_password.tscn")
@onready var none_password_label = Label.new()

var vbox_height

func _ready() -> void:
	if vbox.get_child(0) == null:
		none_password_added()
	
	var password_changer_instance = password_changer.instantiate()
	password_changer_instance.first_correct_password.connect(_on_first_password_emitted)
	#test("password", "app_name")
	
	close_button.pressed.connect(_on_close_button_pressed)

func _process(delta: float) -> void:
	pass
	
func _on_first_password_emitted(new_password : String, app_name : String) -> void:
	var password_box = load("res://scenes/phone_settings/password.tscn")
	var password_box_instance = password_box.instantiate()
	
	vbox.add_child(password_box_instance)
	
	password_box_instance.text_password(new_password)
	password_box_instance.text_title(app_name)
	
	#TODO change icon based in wich app was created
	
func none_password_added() -> void:
	#var margin_container = MarginContainer.new()
	#background.add_child(margin_container)
	#margin_container.global_position = Vector2(0, 200)
	background.add_child(none_password_label)
	#margin_container.add_theme_constant_override("margin_left", 100)
	
	#margin_container.add_child(none_password_label)
	
	#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	none_password_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	none_password_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	none_password_label.custom_minimum_size = Vector2(1000, 200)
		
	none_password_label.text = "Você não possui nenhuma senha cadastrada"
	none_password_label.add_theme_font_size_override("font_size", 50)
	
	var custom_font = FontFile.new()
	custom_font.font_data = load("res://assets/fonts/IBMPlexSans-Regular.ttf")
	none_password_label.add_theme_font_override("font", custom_font)
	
	label_position(none_password_label)
#func _on_change_button_pressed() -> void:
	#_set_password_changer_position(vbox_height)

#func _set_password_changer_position(position) -> void:
	#mensagens.password_changer.global_position.y -= position

func test(new_password : String, app_name : String) -> void:
	if vbox.get_child(0) == null:
		none_password_label.hide()
	
	var password_box = load("res://scenes/phone_settings/password.tscn")
	var password_box_instance = password_box.instantiate()
	
	vbox.add_child(password_box_instance)
	
	password_box_instance.text_password(new_password)
	password_box_instance.text_title(app_name)
	
func label_position(label : Label) -> void:
	label.position = Vector2((1080 - label.size.x) / 2, 1000)

func _on_close_button_pressed() -> void:
	self.hide()
	
