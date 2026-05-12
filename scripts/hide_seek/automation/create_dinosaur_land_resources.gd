extends SceneTree

# Metadata for the Dinosaur Land scene
const THEME_NAME = "dinosaur_land"
const BG_PATH = "res://assets/sprites/hide_seek/dinosaur_land/bg.png"
const ITEMS_DATA = [
	{"name": "dino_egg", "pos": Vector2(300, 850), "radius": 50.0},
	{"name": "fern", "pos": Vector2(200, 950), "radius": 65.0},
	{"name": "footprint", "pos": Vector2(1000, 900), "radius": 60.0},
	{"name": "fossil", "pos": Vector2(1700, 700), "radius": 55.0},
	{"name": "palm_tree", "pos": Vector2(500, 500), "radius": 110.0},
	{"name": "pterodactyl", "pos": Vector2(1400, 200), "radius": 75.0},
	{"name": "stegosaurus", "pos": Vector2(1200, 600), "radius": 85.0},
	{"name": "t_rex", "pos": Vector2(800, 550), "radius": 95.0},
	{"name": "triceratops", "pos": Vector2(150, 750), "radius": 80.0},
	{"name": "volcano", "pos": Vector2(300, 400), "radius": 120.0}
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
