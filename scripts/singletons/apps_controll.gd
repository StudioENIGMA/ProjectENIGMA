extends Node

class_name AppControl

enum App {
	Email,
	Store,
	Browser,
	Settings,
	Messages,
	FakeStore,
}

var apps_name: Dictionary = {}
var apps_in_store: Array[App] = [App.Messages, App.Browser, App.Email]
var downloaded_apps: Array[App] = [App.Messages, App.Settings, App.Store]
var available_updates: Array[App] = []

func _ready() -> void:
	apps_name[App.Store] = "Loja"
	apps_name[App.Email] = "Email"
	apps_name[App.Browser] = "Navegador"
	apps_name[App.Messages] = "Mensagens"
	apps_name[App.Settings] = "Ajustes"
	apps_name[App.FakeStore] = "Loja"

func get_available_updates() -> Array[App]:
	return available_updates

func get_downloaded_apps() -> Array[App]:
	return downloaded_apps

func get_apps_in_store() -> Array[App]:
	return apps_in_store

func download_app(app: App) -> void:
	downloaded_apps.push_back(app)

func delete_app(app: App) -> void:
	downloaded_apps.erase(app)

func add_update_for(app: App) -> void:
	available_updates.push_back(app)

func update_app(app: App) -> void:
	available_updates.erase(app)

func open_app(app: App, app_enabler_instance: AppEnabler):
	match app:
		App.Email:
			app_enabler_instance.open_mail.emit()
		App.Store:
			app_enabler_instance.open_store.emit()
		App.Browser:
			app_enabler_instance.open_browser.emit()
		App.Settings:
			app_enabler_instance.open_settings.emit()
		App.Messages:
			app_enabler_instance.open_messages.emit()
		App.FakeStore:
			app_enabler_instance.open_store.emit()
