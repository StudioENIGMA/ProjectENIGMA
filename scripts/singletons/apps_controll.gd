extends Node

class_name AppControl

enum App {
	EMAIL,
	STORE,
	BROWSER,
	SETTINGS,
	MESSAGES,
	FAKESTORE,
}

var apps_name: Dictionary = {}
var apps_in_store: Array[App] = [App.MESSAGES, App.EMAIL]
var downloaded_apps: Array[App] = [App.MESSAGES, App.SETTINGS]
var available_updates: Array[App] = []

func _ready() -> void:
	apps_name[App.STORE] = "Loja"
	apps_name[App.EMAIL] = "Email"
	apps_name[App.BROWSER] = "Navegador"
	apps_name[App.MESSAGES] = "Mensagens"
	apps_name[App.SETTINGS] = "Ajustes"
	apps_name[App.FAKESTORE] = "Loja"

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
		App.EMAIL:
			app_enabler_instance.open_mail.emit()
		App.STORE:
			app_enabler_instance.open_store.emit()
		App.BROWSER:
			app_enabler_instance.open_browser.emit()
		App.SETTINGS:
			app_enabler_instance.open_settings.emit()
		App.MESSAGES:
			app_enabler_instance.open_messages.emit()
		App.FAKESTORE:
			app_enabler_instance.open_store.emit()
