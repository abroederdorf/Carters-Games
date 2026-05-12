extends SceneTree

# Metadata for the Jungle scene
const THEME_NAME = "jungle"
const BG_PATH = "res://assets/sprites/hide_seek/jungle/bg.png"
const ITEMS_DATA = [
	{"name": "banana_bunch", "pos": Vector2(150, 100), "radius": 60.0},
	{"name": "binoculars", "pos": Vector2(850, 920), "radius": 50.0},
	{"name": "butterfly", "pos": Vector2(450, 850), "radius": 40.0},
	{"name": "explorer_hat", "pos": Vector2(600, 950), "radius": 55.0},
	{"name": "monkey", "pos": Vector2(1610, 430), "radius": 75.0},
	{"name": "orchid", "pos": Vector2(350, 500), "radius": 50.0},
	{"name": "parrot", "pos": Vector2(700, 150), "radius": 65.0},
	{"name": "sloth", "pos": Vector2(1200, 300), "radius": 80.0},
	{"name": "snake", "pos": Vector2(380, 400), "radius": 60.0},
	{"name": "tiger", "pos": Vector2(1800, 850), "radius": 90.0}
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
