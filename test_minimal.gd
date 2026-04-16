extends SceneTree

var frames = 0


func _process(delta):
	frames += 1
	if frames == 1:
		print("--- SCRIPT RUNNING ---")
		var sdk = Engine.get_singleton("TownSDK")
		print("Engine.get_singleton('TownSDK') = ", sdk)
		
		# We must use call because TownSdkClient might not compile cleanly if it's missing
		var class_db_exists = ClassDB.class_exists("TownSdkClient")
		print("ClassDB.class_exists('TownSdkClient') = ", class_db_exists)
		print("--- SCRIPT FINISHED ---")
	
	if frames > 2:
		quit(0)
	
	return false
