extends SceneTree

# Metadata for the Monster Truck Jam scene
const THEME_NAME = "monster_truck_jam"
const BG_PATH = "res://assets/sprites/hide_seek/monster_truck_jam/bg.png"
const ITEMS_DATA = [
	{"name": "checkered_flag", "pos": Vector2(200, 250), "radius": 50.0},
	{"name": "crushed_car", "pos": Vector2(350, 620), "radius": 75.0},
	{"name": "flame_decal", "pos": Vector2(200, 680), "radius": 45.0},
	{"name": "gas_can", "pos": Vector2(500, 950), "radius": 55.0},
	{"name": "megaphone", "pos": Vector2(1500, 300), "radius": 40.0},
	{"name": "monster_truck", "pos": Vector2(110, 400), "radius": 100.0},
	{"name": "mud_splatter", "pos": Vector2(800, 800), "radius": 60.0},
	{"name": "tire", "pos": Vector2(900, 930), "radius": 65.0},
	{"name": "trophy", "pos": Vector2(750, 880), "radius": 55.0},
	{"name": "wrench", "pos": Vector2(50, 950), "radius": 40.0}
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
