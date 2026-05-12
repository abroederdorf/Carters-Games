extends SceneTree

func _init():
	var file = FileAccess.open("res://assets/data/hide_seek/anchors_data.json", FileAccess.READ)
	if not file:
		print("Could not find anchors_data.json")
		quit()
		return
		
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not json is Dictionary:
		print("Invalid JSON format")
		quit()
		return
		
	for theme_name in json.keys():
		var scene_res_path = "res://resources/hide_seek/%s.tres" % theme_name
		if not ResourceLoader.exists(scene_res_path):
			print("Resource not found: ", scene_res_path)
			continue
			
		var scene_data: HideSeekSceneData = load(scene_res_path)
		if not scene_data:
			print("Failed to load: ", scene_res_path)
			continue
			
		print("Updating anchors for: ", theme_name)
		scene_data.anchors.clear()
		
		var anchors_list = json[theme_name]
		for a_data in anchors_list:
			var anchor = HideSeekAnchor.new()
			anchor.position = Vector2(a_data["x"], a_data["y"])
			anchor.radius = a_data["radius"]
			anchor.difficulty = a_data.get("difficulty", 1)
			var tags_data = a_data.get("tags", [])
			for t in tags_data:
				anchor.tags.append(str(t))
			scene_data.anchors.append(anchor)
			
		var err = ResourceSaver.save(scene_data, scene_res_path)
		if err == OK:
			print("  Successfully saved anchors.")
		else:
			print("  Error saving resource: ", err)
			
	quit()
