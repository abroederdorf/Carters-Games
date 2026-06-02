extends SceneTree

const SPRITES_ROOT := "res://assets/sprites/hide_seek"
const RESOURCES_ROOT := "res://resources/hide_seek"
const THEMES_JSON := "res://assets/data/hide_seek/themes.json"
const SHARED_SPRITES := "res://assets/sprites/hide_seek/shared"

# Configurable defaults
const ITEM_START_POS := Vector2(100, 100)
const ITEM_DEFAULT_SCALE := 0.5
const ANCHOR_COUNT := 50
const ANCHOR_DEFAULT_RADIUS := 40.0

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var theme := ""
	
	for i in range(args.size()):
		if args[i] == "--theme" and i + 1 < args.size():
			theme = args[i+1]
			
	if theme == "":
		print("Usage: godot -s preseed_scene.gd --theme <theme_name>")
		quit()
		return

	print("=== Pre-seeding Scene: %s ===" % theme)
	
	var theme_data = _load_themes()
	if not theme_data.has(theme):
		push_error("Theme '%s' not found in themes.json" % theme)
		quit()
		return
		
	var data = theme_data[theme]
	
	# 1. Create/Load Scene Resource
	var scene_path := "%s/%s.tres" % [RESOURCES_ROOT, theme]
	var scene_data: HideSeekSceneData
	
	if ResourceLoader.exists(scene_path):
		scene_data = load(scene_path)
		if scene_data and scene_data.is_manual_edit:
			print("[%s] PROTECTED: Scene has is_manual_edit = true. Aborting pre-seed to save your work." % theme)
			quit()
			return
	
	if scene_data == null:
		scene_data = HideSeekSceneData.new()
	
	scene_data.scene_name = theme
	
	# Load Background
	var short_theme := theme.replace("_game", "").replace("_scene", "")
	var bg_names := [
		"bg_%s.webp" % theme, "bg_%s.png" % theme,
		"bg_%s.webp" % short_theme, "bg_%s.png" % short_theme,
		"bg.webp", "bg.png",
		"bg_fast.webp", "bg_fast.png"
	]
	for bg_name in bg_names:
		var bg_path := "%s/%s/%s" % [SPRITES_ROOT, theme, bg_name]
		if FileAccess.file_exists(bg_path.replace("res://", "")):
			scene_data.background_image = load(bg_path)
			print("[%s] Background assigned: %s" % [theme, bg_name])
			break
	
	# 2. Pre-seed Items
	var synced_items: Array[HideSeekItemData] = []
	for i_data in data.get("items", []):
		var item_name: String = i_data["name"]
		var item = HideSeekItemData.new()
		item.item_name = item_name
		
		# Initial placement for manual work
		item.position = ITEM_START_POS
		item.radius = 60.0
		item.base_scale = ITEM_DEFAULT_SCALE
		item.tags.clear()
		
		# Thumbnail resolution
		var thumb_path := ""
		if i_data.has("shared"):
			var base_shared := "%s/%s" % [SHARED_SPRITES, i_data["shared"]]
			if FileAccess.file_exists((base_shared + ".webp").replace("res://", "")):
				thumb_path = base_shared + ".webp"
			elif FileAccess.file_exists((base_shared + ".png").replace("res://", "")):
				thumb_path = base_shared + ".png"
		elif i_data.has("path"):
			thumb_path = "res://" + i_data["path"]
		else:
			var base_local := "%s/%s/%s" % [SPRITES_ROOT, theme, item_name]
			if FileAccess.file_exists((base_local + ".webp").replace("res://", "")):
				thumb_path = base_local + ".webp"
			elif FileAccess.file_exists((base_local + ".png").replace("res://", "")):
				thumb_path = base_local + ".png"
		
		if thumb_path != "":
			item.thumbnail = load(thumb_path)
		else:
			print("[%s] WARNING: No sprite found for item: %s" % [theme, item_name])
		
		# Save individual item resource
		var item_dir := "%s/%s" % [RESOURCES_ROOT, theme]
		DirAccess.make_dir_recursive_absolute(item_dir)
		ResourceSaver.save(item, "%s/%s.tres" % [item_dir, item_name])
		synced_items.append(item)
	
	scene_data.items = synced_items
	
	# 3. Pre-seed Anchors (packed at top so bottom-up placement has clear working space)
	scene_data.anchors.clear()
	var cols := 10
	var bg_w := float(scene_data.background_image.get_width()) if scene_data.background_image else 1920.0
	var rows := int(ceil(float(ANCHOR_COUNT) / cols))
	var spacing_x := bg_w / (cols + 1)
	var spacing_y := 60.0
	var offset_shift := spacing_x * 0.5

	var count := 0
	for r in range(rows):
		for c in range(cols):
			if count >= ANCHOR_COUNT: break
			var anchor = HideSeekAnchor.new()
			anchor.id = count
			var x = spacing_x * (c + 1)
			if r % 2 == 1:
				x += offset_shift
				if x > bg_w - offset_shift: x -= spacing_x
			anchor.position = Vector2(x, 40.0 + spacing_y * r)
			anchor.radius = ANCHOR_DEFAULT_RADIUS
			anchor.tags.clear()
			scene_data.anchors.append(anchor)
			count += 1
	
	# 4. Save Scene
	ResourceSaver.save(scene_data, scene_path)
	print("Successfully pre-seeded '%s': %d items, %d anchors" % [theme, synced_items.size(), scene_data.anchors.size()])

	# 5. Move scene to front of SCENE_ORDER for testing
	_update_scene_order(theme)
	quit()

func _update_scene_order(theme: String) -> void:
	var state_path := "res://scripts/hide_seek/core/hide_seek_state.gd"
	var file := FileAccess.open(state_path, FileAccess.READ)
	if not file:
		print("[%s] WARNING: Could not open hide_seek_state.gd to update scene order" % theme)
		return
	var content := file.get_as_text()
	file.close()

	# Remove existing entry wherever it is (with or without trailing comma)
	for pattern: String in ['\t"%s",\n' % theme, '\t"%s"\n' % theme]:
		content = content.replace(pattern, "")

	# Insert as first entry in SCENE_ORDER
	var marker := "const SCENE_ORDER: Array[String] = [\n"
	var idx := content.find(marker)
	if idx == -1:
		print("[%s] WARNING: SCENE_ORDER not found in hide_seek_state.gd" % theme)
		return

	content = content.insert(idx + marker.length(), '\t"%s",\n' % theme)

	var out := FileAccess.open(state_path, FileAccess.WRITE)
	out.store_string(content)
	out.close()
	print("[%s] Moved to first in SCENE_ORDER for testing" % theme)

func _load_themes() -> Dictionary:
	var file = FileAccess.open(THEMES_JSON, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	var full_data = json.get_data()
	if full_data.has("themes"):
		return full_data["themes"]
	return full_data
