extends Node2D

@onready var background = $background
@onready var title = $title
@onready var close_button = $background/close

@onready var current_version = "14.5.4"
@onready var new_version = "14.5.5"

@onready var text_label = Label.new()
@onready var update_button = Button.new()
#@onready var text

func _ready() -> void:
	background.add_child(text_label)
	
	label_text_has_update_format()
	label_position(text_label)
	
	background.add_child(update_button)
	
	update_button_format(update_button)
	update_button.position = Vector2((1080 - update_button.size.x) / 2, text_label.position.y + 250)
	
	update_button.pressed.connect(_on_update_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_version == new_version:
		none_update_available()
		
func label_text_has_update_format() -> void:
	text_label.text = "O Sistema Operacional atual está na versão " + current_version + ". A versão mais recente é " + new_version + ". Deseja atualizar o sistema?"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(1000, 200)
	
	text_label.add_theme_font_size_override("font_size", 50)
	
	var custom_font = FontFile.new()
	custom_font.font_data = load("res://assets/fonts/IBMPlexSans-Regular.ttf")
	text_label.add_theme_font_override("font", custom_font)
	
func label_position(label : Label) -> void:
	label.position = Vector2((1080 - label.size.x) / 2, 400)
	
func update_button_format(button : Button) -> void:
	button.text = "Atualizar Sistema"
	
	button.size = Vector2(1000, 200)
	button.add_theme_font_size_override("font_size", 60)
	
	var custom_font = FontFile.new()
	custom_font.font_data = load("res://assets/fonts/IBMPlexSans-Regular.ttf")
	button.add_theme_font_override("font", custom_font)
	
func none_update_available() -> void:
	text_label.text = "O Sistema Operacional atual está na versão " + current_version + ". " + "Sem atualização disponível."
	update_button.hide()
	
func _on_update_button_pressed() -> void:
	update_button.text = "Atualizando..."
	await get_tree().create_timer(4).timeout
	current_version = new_version

	await get_tree().create_timer(10).timeout
	
	new_version = "16.0.0"
	_on_new_update_available()
	
func _on_new_update_available() -> void:
	label_text_has_update_format()
	update_button.text = "Atualizar Sistema"
	update_button_format(update_button)
	update_button.show()

func _on_close_button_pressed() -> void:
	self.hide()
