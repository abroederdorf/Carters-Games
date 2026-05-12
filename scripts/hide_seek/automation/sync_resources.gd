extends SceneTree

const SPRITES_ROOT := "res://assets/sprites/hide_seek"
const RESOURCES_ROOT := "res://resources/hide_seek"
const ANCHORS_JSON := "res://assets/data/hide_seek/anchors_data.json"
const TAGS_JSON := "res://assets/data/hide_seek/item_tags.json"
const DEFAULT_RADIUS := 60.0

var _anchor_data: Dictionary = {}
var _tag_data: Dictionary = {}
var _created := 0
var _updated := 0
var _skipped := 0


func _init() -> void:
	print("=== sync_resources: starting ===")

	_anchor_data = _load_json(ANCHORS_JSON)
	_tag_data = _load_json(TAGS_JSON)

	var themes := _discover_themes()
	print("Found %d themes." % themes.size())

	for theme in themes:
		_sync_theme(theme)

	print("=== Done. created=%d  updated=%d  skipped=%d ===" % [_created, _updated, _skipped])
	quit()


# ── Theme Discovery ────────────────────────────────────────────────────────────

func _discover_themes() -> Array[String]:
	var themes: Array[String] = []
	var dir := DirAccess.open(SPRITES_ROOT)
	if not dir:
		push_error("Cannot open sprites root: " + SPRITES_ROOT)
		return themes
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with(".") and entry != "shared":
			var bg := "%s/%s/bg.png" % [SPRITES_ROOT, entry]
			if ResourceLoader.exists(bg):
				themes.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	themes.sort()
	return themes


# ── Per-Theme Sync ─────────────────────────────────────────────────────────────

func _sync_theme(theme: String) -> void:
	var scene_path := "%s/%s.tres" % [RESOURCES_ROOT, theme]
	var scene_data: HideSeekSceneData

	if ResourceLoader.exists(scene_path):
		scene_data = load(scene_path) as HideSeekSceneData
		if scene_data == null:
			push_error("[%s] Failed to load existing .tres — skipping." % theme)
			_skipped += 1
			return
	else:
		scene_data = HideSeekSceneData.new()
		scene_data.scene_name = theme
		scene_data.background_image = load("%s/%s/bg.png" % [SPRITES_ROOT, theme])
		_ensure_dir("%s/%s" % [RESOURCES_ROOT, theme])

	_sync_items(scene_data, theme)
	_apply_anchors(scene_data, theme)
	_apply_tags(scene_data, theme)

	var err := ResourceSaver.save(scene_data, scene_path)
	if err == OK:
		print("[%s] OK (%d items, %d anchors)" % [theme, scene_data.items.size(), scene_data.anchors.size()])
		if ResourceLoader.exists(scene_path):
			_updated += 1
		else:
			_created += 1
	else:
		push_error("[%s] Failed to save scene resource: %d" % [theme, err])
		_skipped += 1


# ── Item Sync ──────────────────────────────────────────────────────────────────

func _sync_items(scene_data: HideSeekSceneData, theme: String) -> void:
	var sprite_dir := "%s/%s" % [SPRITES_ROOT, theme]
	var item_names := _discover_items(sprite_dir)

	# Index existing items by name for fast lookup
	var existing: Dictionary = {}
	for item in scene_data.items:
		existing[item.item_name] = item

	var synced_items: Array[HideSeekItemData] = []

	for item_name in item_names:
		var item: HideSeekItemData
		if existing.has(item_name):
			item = existing[item_name]
		else:
			item = HideSeekItemData.new()
			item.item_name = item_name
			item.position = Vector2.ZERO
			item.radius = DEFAULT_RADIUS

		# Always refresh thumbnail from sprite
		var thumb_path := "%s/%s.png" % [sprite_dir, item_name]
		item.thumbnail = load(thumb_path)

		# Save individual item resource
		var item_path := "%s/%s/%s.tres" % [RESOURCES_ROOT, theme, item_name]
		ResourceSaver.save(item, item_path)

		synced_items.append(item)

	scene_data.items = synced_items


func _discover_items(sprite_dir: String) -> Array[String]:
	var names: Array[String] = []
	var dir := DirAccess.open(sprite_dir)
	if not dir:
		return names
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".png") and entry != "bg.png":
			names.append(entry.get_basename())
		entry = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names


# ── Anchor Application ─────────────────────────────────────────────────────────

func _apply_anchors(scene_data: HideSeekSceneData, theme: String) -> void:
	if not _anchor_data.has(theme):
		return
	scene_data.anchors.clear()
	for a_data in _anchor_data[theme]:
		var anchor := HideSeekAnchor.new()
		anchor.position = Vector2(a_data["x"], a_data["y"])
		anchor.radius = a_data["radius"]
		anchor.difficulty = a_data.get("difficulty", 1)
		for t in a_data.get("tags", []):
			anchor.tags.append(str(t))
		scene_data.anchors.append(anchor)


# ── Tag Application ────────────────────────────────────────────────────────────

func _apply_tags(scene_data: HideSeekSceneData, theme: String) -> void:
	if not _tag_data.has(theme):
		return
	var theme_tags: Dictionary = _tag_data[theme]
	for item in scene_data.items:
		if not theme_tags.has(item.item_name):
			continue
		item.tags.clear()
		for t in theme_tags[item.item_name]:
			item.tags.append(str(t))
		var item_path := "%s/%s/%s.tres" % [RESOURCES_ROOT, theme, item.item_name]
		if ResourceLoader.exists(item_path):
			ResourceSaver.save(item, item_path)


# ── Helpers ────────────────────────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		print("No JSON found at %s — skipping." % path)
		return {}
	var result := JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		return result
	push_error("Invalid JSON at: " + path)
	return {}


func _ensure_dir(path: String) -> void:
	var dir := DirAccess.open(path.get_base_dir())
	if dir and not dir.dir_exists(path.get_file()):
		dir.make_dir(path.get_file())
