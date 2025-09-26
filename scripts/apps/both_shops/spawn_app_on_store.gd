extends Node

class_name SpawnAppOnStore

const AppItemScene = preload("res://scenes/apps/store-shop/shop_app.tscn")

@onready var app_list_container = $"."

@export var store_instance : Node2D

var apps_data: Array[Dictionary] = [
	{
		"name": AppsControll.apps_name[AppsControll.App.Messages],
		"chinese_name": "訊息和對話",
		"description": "Receba e Envie Mensagens!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/messages.png",
	},

	{
		"name": AppsControll.apps_name[AppsControll.App.Email],
		"chinese_name": "電子郵件",
		"description": "Receba e envie emails aqui!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/email.png",
	},

	{
		"name": AppsControll.apps_name[AppsControll.App.Browser],
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

func _ready() -> void:
	# spawn_apps()
	pass

func spawn_apps():
	var apps_in_store = AppsControll.get_apps_in_store()

	for child in app_list_container.get_children():
		child.queue_free()

	for app in apps_in_store:
		var new_app_item = AppItemScene.instantiate()
		new_app_item.store_instance = self.store_instance
		new_app_item.app_enabler_instance = self.get_parent().get_parent().get_parent()

		var app_data = get_app_data(app)

		new_app_item.get_node("Label_Margin_Container/Label").text = app_data["name"]

		new_app_item.get_node("Description_Container/Description").text = app_data["description"]

		var new_texture = load(app_data["icon_path"])
		new_app_item.get_node("Icon_Margin_Container/TextureRect").texture = new_texture

		app_list_container.add_child(new_app_item)

func remove_apps_from_list():
	for app in app_list_container.get_children():
		app.queue_free()

func get_app_data(app: AppsControll.App) -> Dictionary:
	for app_data in apps_data:
		if app_data["name"] == AppsControll.apps_name[app]:
			return app_data

	return {}
