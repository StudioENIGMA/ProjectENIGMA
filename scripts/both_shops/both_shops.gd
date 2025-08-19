extends Node2D
class_name both_shops

var apps_data = [
	{
		"name": "Mensagens",
		"chinese_name": "訊息和對話",
		"description": "Receba e Envie Mensagens!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/messages.png",
	},
	
	{
		"name": "Email", 
		"chinese_name": "電子郵件",
		"description": "Receba e envie emails aqui!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/email.png",
	},
	
	{
		"name": "Navegador",
		"chinese_name": "導航和搜尋",
		"description": "Acesse seus sites favoritos!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/browser.png",
	},
	
	{
		"name": "Gambling",
		"chinese_name": "小老虎遊戲",
		"description": "!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/app-store.png",
	}
]

var operations = [
	"開始安裝", # instalar
	"應用程式更新", # atualizar
	"阿布里爾" # abrir
]

var matches = []

@onready var uninstall : Button = $Panel/Uninstall
@onready var exit_button : Button = $Exit_shop
@export var is_fake : bool = false
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
		apps[i].get_node("Label_Margin_Container/Label").text = apps_data[i]["chinese_name"]

		apps[i].get_node("Description_Container/Description").text = apps_data[i]["description_in_chinese"]
		
		var new_texture = load(apps_data[i]["icon_path"])
		apps[i].get_node("Icon_Margin_Container/TextureRect").texture = new_texture

		var operationals_buttons = apps[i].get_node("Button_Container").get_children()
		for j in range(operationals_buttons.size()):
			operationals_buttons[j].text = operations[j]

func load_normal_shop() -> void:
	for i in range(apps.size() - 1):
		apps[i].get_node("Label_Margin_Container/Label").text = apps_data[i]["name"]
		
		apps[i].get_node("Description_Container/Description").text = apps_data[i]["description"]
		
		var new_texture = load(apps_data[i]["icon_path"])
		apps[i].get_node("Icon_Margin_Container/TextureRect").texture = new_texture

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
	deleted = true
	await get_tree().create_timer(3.0).timeout
	invisible()
