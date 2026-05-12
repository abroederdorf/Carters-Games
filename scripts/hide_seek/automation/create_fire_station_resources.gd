extends SceneTree

# Metadata for the Fire Station scene
const THEME_NAME = "fire_station"
const BG_PATH = "res://assets/sprites/hide_seek/fire_station/bg_fast.png"
const ITEMS_DATA = [
	{"name": "axe", "pos": Vector2(1000, 150), "radius": 55.0},
	{"name": "bell", "pos": Vector2(1350, 70), "radius": 45.0},
	{"name": "boots", "pos": Vector2(1900, 950), "radius": 60.0},
	{"name": "dalmatian", "pos": Vector2(750, 900), "radius": 70.0},
	{"name": "fire_extinguisher", "pos": Vector2(500, 500), "radius": 50.0},
	{"name": "fire_truck", "pos": Vector2(1500, 500), "radius": 120.0},
	{"name": "helmet", "pos": Vector2(1700, 800), "radius": 50.0},
	{"name": "hose_reel", "pos": Vector2(300, 850), "radius": 65.0},
	{"name": "hydrant", "pos": Vector2(50, 950), "radius": 55.0},
	{"name": "ladder", "pos": Vector2(1850, 300), "radius": 90.0}
]

func _init():
	var scene_data = HideSeekSceneData.new()
	scene_data.scene_name = THEME_NAME
	scene_data.background_image = load(BG_PATH)
	
	var dir = DirAccess.open("res://resources/hide_seek/")
	if not dir.dir_exists(THEME_NAME):
		dir.make_dir(THEME_NAME)
	
	for data in ITEMS_DATA:
		var item = HideSeekItemData.new()
		item.item_name = data["name"]
		item.position = data["pos"]
		item.radius = data["radius"]
		
		var thumb_path = "res://assets/sprites/hide_seek/%s/%s.png" % [THEME_NAME, data["name"]]
		item.thumbnail = load(thumb_path)
		
		var item_res_path = "res://resources/hide_seek/%s/%s.tres" % [THEME_NAME, data["name"]]
		ResourceSaver.save(item, item_res_path)
		
		scene_data.items.append(item)
	
	var scene_res_path = "res://resources/hide_seek/%s.tres" % THEME_NAME
	var err = ResourceSaver.save(scene_data, scene_res_path)
	
	if err == OK:
		print("Successfully created resources for: ", THEME_NAME)
	else:
		print("Failed to save scene resource: ", err)
	
	quit()
