extends SceneTree

# Metadata for the Construction Site scene
const THEME_NAME = "construction_site"
const BG_PATH = "res://assets/sprites/hide_seek/construction_site/bg.png"
const ITEMS_DATA = [
	{"name": "blueprint", "pos": Vector2(650, 950), "radius": 60.0},
	{"name": "bulldozer", "pos": Vector2(350, 650), "radius": 85.0},
	{"name": "cement_mixer", "pos": Vector2(1400, 700), "radius": 75.0},
	{"name": "dump_truck", "pos": Vector2(1800, 850), "radius": 95.0},
	{"name": "excavator", "pos": Vector2(550, 750), "radius": 100.0},
	{"name": "hammer", "pos": Vector2(120, 930), "radius": 40.0},
	{"name": "hard_hat", "pos": Vector2(1000, 550), "radius": 45.0},
	{"name": "safety_vest", "pos": Vector2(480, 930), "radius": 50.0},
	{"name": "toolbox", "pos": Vector2(70, 930), "radius": 55.0},
	{"name": "traffic_cone", "pos": Vector2(380, 930), "radius": 40.0}
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
