extends Node

var api: ModLoaderAPI


func _on_mod_load(mod_api: ModLoaderAPI) -> void:
	api = mod_api
	api.info("script carregado")
	api.hook("apps_data_loaded", _on_apps_data_loaded)


func _on_apps_data_loaded(apps_data: Dictionary) -> void:
	api.info("apps_data carregado, %d apps registrados" % apps_data.size())
