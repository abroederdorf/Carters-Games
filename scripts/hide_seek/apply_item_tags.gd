extends SceneTree

func _init():
	var file = FileAccess.open("res://scripts/hide_seek/item_tags.json", FileAccess.READ)
	if not file:
		print("Could not find item_tags.json")
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
			continue
			
		var scene_data: HideSeekSceneData = load(scene_res_path)
		if not scene_data:
			continue
			
		print("Updating item tags for: ", theme_name)
		var theme_tags = json[theme_name]
		
		for item in scene_data.items:
			if theme_tags.has(item.item_name):
				item.tags.clear()
				var tags_list = theme_tags[item.item_name]
				for t in tags_list:
					item.tags.append(str(t))
				
				# Also update the individual item resource file
				var item_res_path = "res://resources/hide_seek/%s/%s.tres" % [theme_name, item.item_name]
				if ResourceLoader.exists(item_res_path):
					ResourceSaver.save(item, item_res_path)
		
		# Save the scene data as well (though items are sub-resources)
		ResourceSaver.save(scene_data, scene_res_path)
			
	quit()
