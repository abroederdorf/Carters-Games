extends SceneTree

# Metadata for the Mountain scene
const THEME_NAME = "mountains"
const BG_PATH = "res://assets/sprites/hide_seek/mountains/bg.png"
const ITEMS_DATA = [
	{"name": "bear", "pos": Vector2(240, 720), "radius": 80.0},
	{"name": "tent", "pos": Vector2(1450, 810), "radius": 90.0},
	{"name": "campfire", "pos": Vector2(1320, 840), "radius": 60.0},
	{"name": "fish", "pos": Vector2(880, 920), "radius": 50.0},
	{"name": "climber", "pos": Vector2(1680, 320), "radius": 70.0},
	{"name": "skier", "pos": Vector2(450, 210), "radius": 75.0},
	{"name": "hiker", "pos": Vector2(1100, 650), "radius": 70.0},
	{"name": "tree", "pos": Vector2(600, 580), "radius": 100.0},
	{"name": "flowers", "pos": Vector2(1250, 950), "radius": 55.0},
	{"name": "birds", "pos": Vector2(960, 150), "radius": 50.0},
	{"name": "backpack", "pos": Vector2(1020, 680), "radius": 45.0},
	{"name": "deer", "pos": Vector2(1750, 780), "radius": 80.0},
	{"name": "cave", "pos": Vector2(180, 450), "radius": 110.0},
	{"name": "rock", "pos": Vector2(1550, 960), "radius": 65.0}
]

func _init():
	var scene_data = HideSeekSceneData.new()
	scene_data.scene_name = THEME_NAME
	scene_data.background_image = load(BG_PATH)
	
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
