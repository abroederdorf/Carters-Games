extends SceneTree

const SPRITES_ROOT := "res://assets/sprites/hide_seek"
const RESOURCES_ROOT := "res://resources/hide_seek"
const ANCHORS_JSON := "res://assets/data/hide_seek/anchors_data.json"
const TAGS_JSON := "res://assets/data/hide_seek/item_tags.json"
const DEFAULT_RADIUS := 60.0

const BG_NAMES := [
	"bg.png",
	"bg_fast.png",
	"bg_standard.png",
	"bg_mountain.png",
	"bg_ocean.png",
	"bg_jungle.png",
	"bg_space.png",
	"bg_dinosaur.png",
	"bg_fire_station.png",
	"bg_monster_jam.png",
	"bg_construction.png"
]

const THEMES_JSON := "res://assets/data/hide_seek/themes.json"
const SHARED_SPRITES := "res://assets/sprites/hide_seek/shared"

var _theme_data: Dictionary = {}
var _anchor_data: Dictionary = {}
var _tag_data: Dictionary = {}
var _created := 0
var _updated := 0
var _skipped := 0


func _init() -> void:
	print("=== sync_resources: starting ===")

	_theme_data = _load_json(THEMES_JSON)
	if _theme_data.is_empty() or not _theme_data.has("themes"):
		push_error("Themes master index not found or invalid.")
		quit()
		return

	_anchor_data = _load_json(ANCHORS_JSON)
	_tag_data = _load_json(TAGS_JSON)

	var themes: Array = _theme_data["themes"].keys()
	print("Found %d themes in master index." % themes.size())

	for theme in themes:
		_sync_theme(theme)

	print("=== Done. created=%d  updated=%d  skipped=%d ===" % [_created, _updated, _skipped])
	quit()


# ── Per-Theme Sync ─────────────────────────────────────────────────────────────

func _sync_theme(theme: String) -> void:
	var data: Dictionary = _theme_data["themes"][theme]
	var scene_path := "%s/%s.tres" % [RESOURCES_ROOT, theme]
	var scene_data: HideSeekSceneData
	var is_new := false

	if ResourceLoader.exists(scene_path):
		scene_data = load(scene_path) as HideSeekSceneData
		if scene_data == null:
			push_error("[%s] Failed to load existing .tres — skipping." % theme)
			_skipped += 1
			return
	else:
		is_new = true
		scene_data = HideSeekSceneData.new()
		scene_data.scene_name = theme
		_ensure_dir("%s/%s" % [RESOURCES_ROOT, theme])

	# Always refresh background so changes to bg assets are picked up
	var bg_found := false
	for bg_name in BG_NAMES:
		var bg_path := "%s/%s/%s" % [SPRITES_ROOT, theme, bg_name]
		if FileAccess.file_exists(bg_path):
			scene_data.background_image = load(bg_path)
			bg_found = true
			break
	if not bg_found:
		push_warning("[%s] Background image not found." % theme)

	_sync_items(scene_data, theme, data.get("items", []))
	_apply_anchors(scene_data, theme)
	_apply_tags(scene_data, theme)
	
	# Final save for items (now with tags applied)
	for item in scene_data.items:
		var item_path := "%s/%s/%s.tres" % [RESOURCES_ROOT, theme, item.item_name]
		ResourceSaver.save(item, item_path)

	var err := ResourceSaver.save(scene_data, scene_path)
	if err == OK:
		print("[%s] OK (%d items, %d anchors)" % [theme, scene_data.items.size(), scene_data.anchors.size()])
		if is_new:
			_created += 1
		else:
			_updated += 1
	else:
		push_error("[%s] Failed to save scene resource: %d" % [theme, err])
		_skipped += 1


# ── Item Sync ──────────────────────────────────────────────────────────────────

func _sync_items(scene_data: HideSeekSceneData, theme: String, items_list: Array) -> void:
	var sprite_dir := "%s/%s" % [SPRITES_ROOT, theme]

	# Index existing items by name for fast lookup
	var existing: Dictionary = {}
	for item in scene_data.items:
		existing[item.item_name] = item

	var synced_items: Array[HideSeekItemData] = []

	for i_data in items_list:
		var item_name: String = i_data["name"]
		var item: HideSeekItemData
		if existing.has(item_name):
			item = existing[item_name]
		else:
			item = HideSeekItemData.new()
			item.item_name = item_name
			item.position = Vector2.ZERO
			item.radius = DEFAULT_RADIUS

		# Refresh thumbnail from sprite (local or shared)
		var thumb_path: String
		if i_data.has("shared"):
			thumb_path = "%s/%s.png" % [SHARED_SPRITES, i_data["shared"]]
		else:
			thumb_path = "%s/%s.png" % [sprite_dir, item_name]
		
		if ResourceLoader.exists(thumb_path):
			item.thumbnail = load(thumb_path)
		else:
			push_warning("[%s] Thumbnail not found: %s" % [theme, thumb_path])
		
		synced_items.append(item)

	scene_data.items = synced_items


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


# ── Helpers ────────────────────────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		print("No JSON found at %s — skipping." % path)
		return {}
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		return result
	push_error("Invalid JSON at: " + path)
	return {}


func _ensure_dir(path: String) -> void:
	var dir := DirAccess.open(path.get_base_dir())
	if dir and not dir.dir_exists(path.get_file()):
		dir.make_dir(path.get_file())
