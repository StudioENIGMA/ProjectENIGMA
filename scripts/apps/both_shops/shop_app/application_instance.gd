extends Control

var buttons = []
var current_app: AppsControl.App

var store_instance:Node2D
var app_enabler_instance:AppEnabler

func _ready() -> void:
	var container = $Button_Container
	for button in container.get_children():
		buttons.append(button)

	var downloaded_apps = AppsControl.get_downloaded_apps()
	var available_updates = AppsControl.get_available_updates()
	var apps_name = AppsControl.apps_name
	var app_name = $Label_Margin_Container/Label.text

	for app in apps_name.keys():
		if apps_name[app] == app_name:
			current_app = app

	if current_app in available_updates:
		buttons[0].visible = false
		buttons[1].visible = true
		buttons[2].visible = false
		return

	if current_app in downloaded_apps:
		buttons[0].visible = true
		buttons[1].visible = false
		buttons[2].visible = false
		return

	buttons[0].visible = false
	buttons[1].visible = false
	buttons[2].visible = true

func _on_open_pressed() -> void:
	store_instance.visible = false
	AppsControl.open_app(current_app, app_enabler_instance)

func _on_update_pressed() -> void:
	buttons[1].text = "Atualizando..."
	await get_tree().create_timer(0.5).timeout
	AppsControl.update_app(current_app)
	buttons[1].text = "Atualizar"
	buttons[0].visible = true
	buttons[1].visible = false
	buttons[2].visible = false

func _on_install_pressed() -> void:
	buttons[2].text = "Instalando..."
	await get_tree().create_timer(0.5).timeout
	AppsControl.download_app(current_app)
	buttons[2].text = "Instalar"
	buttons[0].visible = true
	buttons[1].visible = false
	buttons[2].visible = false
