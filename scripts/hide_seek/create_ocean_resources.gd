extends SceneTree

# Metadata for the Ocean scene
const THEME_NAME = "ocean"
const BG_PATH = "res://assets/sprites/hide_seek/ocean/bg.png"
const ITEMS_DATA = [
	{"name": "anchor", "pos": Vector2(250, 200), "radius": 70.0},
	{"name": "clownfish", "pos": Vector2(120, 680), "radius": 50.0},
	{"name": "crab", "pos": Vector2(960, 950), "radius": 60.0},
	{"name": "jellyfish", "pos": Vector2(1600, 400), "radius": 80.0},
	{"name": "sea_turtle", "pos": Vector2(600, 350), "radius": 90.0},
	{"name": "seahorse", "pos": Vector2(380, 850), "radius": 45.0},
	{"name": "shark", "pos": Vector2(1000, 200), "radius": 100.0},
	{"name": "starfish", "pos": Vector2(1750, 950), "radius": 55.0},
	{"name": "submarine", "pos": Vector2(1400, 250), "radius": 85.0},
	{"name": "treasure_chest", "pos": Vector2(1550, 800), "radius": 75.0}
]

func _init():
	var scene_data = HideSeekSceneData.new()
	scene_data.scene_name = THEME_NAME
	scene_data.background_image = load(BG_PATH)
	
	# Ensure directory exists
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
		
		# Save individual item resource
		var item_res_path = "res://resources/hide_seek/%s/%s.tres" % [THEME_NAME, data["name"]]
		ResourceSaver.save(item, item_res_path)
		
		scene_data.items.append(item)
	
	# Save main scene resource
	var scene_res_path = "res://resources/hide_seek/%s.tres" % THEME_NAME
	var err = ResourceSaver.save(scene_data, scene_res_path)
	
	if err == OK:
		print("Successfully created resources for: ", THEME_NAME)
	else:
		print("Failed to save scene resource: ", err)
	
	quit()
