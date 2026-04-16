extends SceneTree

func _init():
	print("Singletons:")
	for s in Engine.get_singleton_list():
		print(" - ", s)
	var sdk = Engine.get_singleton("TownSDK")
	print("TownSDK: ", sdk)
	var town_client = ClassDB.can_instantiate("TownSdkClient")
	print("Can instantiate TownSdkClient: ", town_client)
	quit()
