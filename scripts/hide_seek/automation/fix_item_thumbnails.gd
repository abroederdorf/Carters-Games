extends SceneTree

# Repairs and extends a manually-edited .tres without overwriting anchors, tags,
# base_scale, or positions. Safe to re-run after moving sprites to shared/.
#
# Usage:
#   godot --headless --script scripts/hide_seek/automation/fix_item_thumbnails.gd -- --theme <name>

const SPRITES_ROOT := "res://assets/sprites/hide_seek"
const RESOURCES_ROOT := "res://resources/hide_seek"
const SHARED_SPRITES := "res://assets/sprites/hide_seek/shared"
const THEMES_JSON := "res://assets/data/hide_seek/themes.json"


func _init() -> void:
	var target_theme := ""
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--theme" and i + 1 < args.size():
			target_theme = args[i + 1]

	if target_theme.is_empty():
		push_error("Usage: -- --theme <theme_name>")
		quit()
		return

	_fix_theme(target_theme)
	quit()


func _fix_theme(theme: String) -> void:
	var res_path := "res://resources/hide_seek/%s.tres" % theme
	if not ResourceLoader.exists(res_path):
		push_error("Scene not found: %s" % res_path)
		return

	var scene_data := ResourceLoader.load(res_path, "", ResourceLoader.CACHE_MODE_REPLACE) as HideSeekSceneData
	if scene_data == null:
		push_error("Failed to load as HideSeekSceneData: %s" % res_path)
		return

	var fixed := 0
	var added := 0
	var skipped := 0

	# ── Step 1 & 2: Fix thumbnails for ALL existing items ──────────────────────
	for item in scene_data.items:
		if _fix_thumbnail(item, theme):
			fixed += 1

	# ── Step 3 & 4: Add items from themes.json that are missing from the .tres ─
	var themes_data := _load_json(THEMES_JSON)
	if themes_data.has("themes") and themes_data["themes"].has(theme):
		var theme_items: Array = themes_data["themes"][theme].get("items", [])

		var existing_names: Dictionary = {}
		for item in scene_data.items:
			existing_names[item.item_name] = true

		for i_data in theme_items:
			var item_name: String = i_data["name"]

			if _has_similar_name(existing_names, item_name):
				continue

			var tex := _find_texture(item_name, theme)
			if tex == null:
				print("[%s] No sprite for '%s' — skipping" % [theme, item_name])
				skipped += 1
				continue

			var new_item := HideSeekItemData.new()
			new_item.item_name = item_name
			new_item.thumbnail = tex
			new_item.radius = 60.0
			new_item.base_scale = 1.0
			scene_data.items.append(new_item)
			existing_names[item_name] = true
			print("[%s] Added '%s'" % [theme, item_name])
			added += 1
	else:
		print("[%s] Not found in themes.json — skipping add step" % theme)

	# ── Save ───────────────────────────────────────────────────────────────────
	var abs_path := ProjectSettings.globalize_path(res_path)
	var err := ResourceSaver.save(scene_data, abs_path)
	if err == OK:
		print("[%s] Saved — fixed=%d  added=%d  skipped=%d" % [theme, fixed, added, skipped])
	else:
		push_error("[%s] Save failed: %d" % [theme, err])


# ── Thumbnail repair ───────────────────────────────────────────────────────────

func _fix_thumbnail(item: HideSeekItemData, theme: String) -> bool:
	if item.thumbnail is CompressedTexture2D:
		var tex_path := item.thumbnail.resource_path
		if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
			return false  # Already a valid external reference
		# Source file moved or missing — find new location
		print("[%s] Stale path for '%s': %s" % [theme, item.item_name, tex_path])
	elif item.thumbnail != null:
		# Embedded ImageTexture or other non-file type
		print("[%s] Fixing embedded thumbnail for '%s'" % [theme, item.item_name])
	# null thumbnails are also repaired silently

	var tex := _find_texture(item.item_name, theme)
	if tex != null:
		item.thumbnail = tex
		return true

	print("[%s] No sprite found for '%s' — thumbnail unchanged" % [theme, item.item_name])
	return false


# ── Helpers ────────────────────────────────────────────────────────────────────

func _find_texture(item_name: String, theme: String) -> Texture2D:
	var local := "%s/%s/%s.png" % [SPRITES_ROOT, theme, item_name]
	if ResourceLoader.exists(local):
		return load(local) as Texture2D
	var shared := "%s/%s.png" % [SHARED_SPRITES, item_name]
	if ResourceLoader.exists(shared):
		return load(shared) as Texture2D
	return null


func _has_similar_name(existing: Dictionary, name: String) -> bool:
	if existing.has(name):
		return true
	# Token-based alias check: "beetle" matches "beetle_green", "lizard" matches "lizard_orange"
	# Min length of 5 avoids short false matches e.g. "hose" in fire_hose vs hose_reel
	var name_tokens := name.split("_")
	for existing_name in existing.keys():
		var existing_tokens: PackedStringArray = existing_name.split("_")
		for token in name_tokens:
			if token.length() >= 5 and token in existing_tokens:
				return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		return result
	return {}
