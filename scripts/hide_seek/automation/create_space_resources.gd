extends SceneTree

# Metadata for the Space scene
const THEME_NAME = "space"
const BG_PATH = "res://assets/sprites/hide_seek/space/bg.png"
const ITEMS_DATA = [
	{"name": "alien", "pos": Vector2(1800, 750), "radius": 60.0},
	{"name": "astronaut", "pos": Vector2(1100, 500), "radius": 75.0},
	{"name": "crater", "pos": Vector2(150, 950), "radius": 80.0},
	{"name": "flying_saucer", "pos": Vector2(300, 100), "radius": 90.0},
	{"name": "moon_rover", "pos": Vector2(500, 750), "radius": 85.0},
	{"name": "ray_gun", "pos": Vector2(800, 700), "radius": 45.0},
	{"name": "rocket", "pos": Vector2(1700, 300), "radius": 100.0},
	{"name": "saturn", "pos": Vector2(1600, 100), "radius": 80.0},
	{"name": "space_helmet", "pos": Vector2(1300, 700), "radius": 50.0},
	{"name": "star", "pos": Vector2(1000, 50), "radius": 35.0}
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
