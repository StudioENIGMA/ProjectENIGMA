extends Node

#region DEFINITIONS
signal open_website(app: GameData.App, website_data: Variant)

enum SiteType{
	REVIEW,
	SHOP,
}

@export var reviews_director: Node
@export var shops_director: Node

var app_to_site_type = {
	GameData.App.REVIEWSSITE : SiteType.REVIEW,
	GameData.App.BROWSERAMAZONIASHOP : SiteType.SHOP,
	GameData.App.BROWSERLIBREMERCADOSHOP : SiteType.SHOP,
	GameData.App.BROWSEREMILIASHOP : SiteType.SHOP,
	GameData.App.BROWSEREMPORIOBOLOSSHOP : SiteType.SHOP,
	GameData.App.BROWSERAECSHOP: SiteType.SHOP,
	GameData.App.BROWSERZORASHOP: SiteType.SHOP,
}
#endregion DEFINITIONS

func _on_open_website_requested(app: GameData.App) -> void:
	var website_data
	match app_to_site_type.get(app):
		SiteType.REVIEW:
			website_data = reviews_director.companies_array
		SiteType.SHOP:
			website_data = shops_director.get_shop_items_array(app)
	open_website.emit(app, website_data)
