extends Node2D
class_name  both_shops

var normal_apps_names = [
	"Mensagens",
	"Email",
	"Navegador"
]

var fake_apps_names = [
	"訊息和對話", # mensagens
	"電子郵件",	# email
	"導航和搜尋", # navegador
	"小老虎遊戲" # app de aposta 
]

var operations = [
	"開始安裝", # instalar
	"應用程式更新", # atualizar
	"阿布里爾" # abrir
]

var matches = []

@onready var uninstall : Button = $Panel/Uninstall
@onready var exit_button : Button = $Exit_shop
@export var is_fake : bool = 0
@export var deleted : bool
@onready var apps = $Panel/VBoxContainer.get_children()

func _ready() -> void:
	if !is_fake:
		load_normal_shop()
		uninstall.hide()
		apps[3].hide()
	else:
		load_fake_shop()

func load_fake_shop() -> void:
	for i in range(apps.size()):
		apps[i].get_node("Label_Margin_Container/Label").text = fake_apps_names[i]
		
		var operationals_buttons = apps[i].get_node("Button_Container").get_children()
		for j in range(operationals_buttons.size()):
			operationals_buttons[j].text = operations[j]

func load_normal_shop() -> void:
	for i in range(apps.size()-1):
		apps[i].get_node("Label_Margin_Container/Label").text = normal_apps_names[i]

func _on_search_bar_text_changed(new_text:String) -> void:
	new_text = new_text.to_lower()
	
	if new_text == "":
		for i in apps:
			i.show()
		return
	matches.clear()	
	
	for i in apps:
		var scene_text = i.get_node("Label_Margin_Container/Label").text
		if new_text in scene_text.to_lower():
			matches.append(i)
	
	for i in apps:
		if i in matches:
			i.show()
		else:
			i.hide()

func _on_exit_shop_pressed() -> void:
	invisible()
	
func invisible() -> void:
	visible = not visible

func _on_uninstall_pressed() -> void:
	uninstall.text = "正在卸載..."
	deleted = 1
	await get_tree().create_timer(3.0).timeout
	invisible()
	
