# Find It! — Scene Pipeline

How to add a new scene to the Hide & Seek game. The game is fully data-driven — no code changes required for new scenes.

---

## Adding a New Scene

### 1. Write prompts and generate images

**Item images** — use [ImageFX](https://aitestkitchen.withgoogle.com/tools/image-fx) or equivalent:

```
512x512, isolated on a white background, children's book illustration, flat design,
bright saturated colors, thick black outlines, no scenery, just the item,
[item description], [view]
```

View options:
- `perfectly flat front view` — faces you straight on (badges, helmets, characters)
- `perfectly flat side view` — profile is clear (tools, vehicles, animals)
- `slight 3/4 view` — would look flat otherwise (buckets, cans, stacked items)

Keep item descriptions short: pose, color, one distinguishing detail.

**Background image** — use [Whisk](https://labs.google/tools/whisk) or equivalent (upload 3–4 item images as references first):

```
Children's book illustration of a large, busy [THEME] scene packed with things to find.
[2-3 sentences describing environment and key landmarks].
The scene is wide and panoramic (landscape orientation, roughly 2:1 ratio).
Bright saturated colors, flat design, thick black outlines, no text.
Every part of the scene is filled with interesting details — [list 4-5 background fillers].
Friendly and [MOOD] mood, suitable for children age 5–10.
```

**Shared items** — common items (hammer, popcorn, etc.) live in `assets/sprites/hide_seek/shared/`. Reference them in `themes.json` with a `"shared"` key instead of generating a duplicate.

---

### 2. Strip backgrounds from item images

Run from the project root after placing the raw PNGs into `assets/sprites/hide_seek/<scene_name>/`:

```bash
# Process a specific theme folder
python scripts/hide_seek/automation/process_transparency.py <scene_name>

# Process specific files
python scripts/hide_seek/automation/process_transparency.py assets/sprites/hide_seek/<scene>/item.png

# Extra flag: remove internal white holes (useful for wheels, handles with holes)
python scripts/hide_seek/automation/process_transparency.py <scene_name> --holes

# Adjust flood-fill tolerance (default 30; increase if background bleeds into object)
python scripts/hide_seek/automation/process_transparency.py <scene_name> --tolerance 40
```

Requires `Pillow`. The script flood-fills from the image perimeter to make the white background transparent, then auto-crops.

If the flood-fill ate too much (object detail gone transparent), use `refill_white.py` to recover internal holes:

```bash
python scripts/hide_seek/automation/refill_white.py assets/sprites/hide_seek/<scene>/item.png
```

If AI generation left a thin bounding-box outline artifact around the image, trim it first:

```bash
# Edit cleanup_assets.py to target your scene directory, then run:
python scripts/hide_seek/automation/cleanup_assets.py
```

---

### 3. Convert PNGs to WebP

WebP is smaller and loads faster. Run after transparency processing:

```bash
# Convert a whole theme folder
python scripts/hide_seek/automation/optimize_new_assets.py <scene_name>

# Convert everything in hide_seek
python scripts/hide_seek/automation/optimize_new_assets.py
```

This script:
1. Converts each PNG → WebP (quality 90, lossless mode for Godot PCK)
2. Writes a `.import` stub so Godot recognizes the file
3. Deletes the original PNG and its old `.import` file
4. Updates any `.tres` files that referenced the old PNG path

Requires `cwebp` on PATH (`brew install webp`).

---

### 4. Import into Godot

**Open the Godot editor** before running any GDScript automation. Godot must see the new files to generate `.import` metadata — without it the preseed script can't load textures.

1. Open the project in the Godot editor
2. Wait for the import bar to finish (bottom of the screen)
3. Verify the new files appear in the FileSystem panel

---

### 5. Add the scene to themes.json

`assets/data/hide_seek/themes.json` is the source of truth for the pipeline — `preseed_scene.gd` and `fix_item_thumbnails.gd` both read from it. The game itself does **not** read this file at runtime; once a scene is preseeded and placed, the `.tres` files are what the game uses.

It contains a `shared` section for reusable items and a `themes` section for scene definitions.

If you need inspiration for item descriptions, check `assets/data/hide_seek/item_suggestions.json` for pre-written prompts.

Add an entry to the `themes` section:

```json
"themes": {
  "<scene_name>": {
    "scene": "Children's book illustration of a ...",
    "items": [
      { "name": "bear", "desc": "cute brown bear sitting upright, friendly expression", "type": "character" },
      { "name": "tent", "desc": "small orange camping tent, triangular, front flap open" },
      { "name": "hammer", "shared": "hammer" }
    ]
  }
}
```

- `type: "character"` uses the character prompt prefix (allows people/animals)
- `"shared": "<filename>"` points to `assets/sprites/hide_seek/shared/<filename>.webp`

---

### 6. Run the preseed script

From the project root (Godot editor must be **closed** for headless mode):

```bash
godot --headless --script scripts/hide_seek/automation/preseed_scene.gd -- --theme <scene_name>
```

This script reads `themes.json` and creates:
- `resources/hide_seek/<scene>.tres` — the main scene resource
- `resources/hide_seek/<scene>/<item>.tres` — one resource per item
- 50 anchor points in an offset grid across the 1920×1080 canvas
- Items stacked in the upper-left at 0.5 scale, ready for manual placement

The script is **safe to re-run** — it checks `is_manual_edit = true` and will abort rather than overwrite a scene you've already manually positioned.

---

### 7. Place items in the Scene Builder

1. Open Godot editor
2. Open `scenes/hide_seek/HideSeekSceneBuilder.tscn`
3. Press **Run Current Scene** (F6)
4. Use the Scene Builder UI to load the background, adjust item positions, set hit-zone radii, and assign tags
5. Save — writes back to `resources/hide_seek/<scene>.tres`

Once saved, set `is_manual_edit = true` in the `.tres` file to protect it from preseed overwrites.

---

### 8. Validate tags

Before committing, ensure all items are correctly tagged and matched to at least one anchor point in the scene:

```bash
python scripts/hide_seek/automation/verify_tags.py
```

This script parses the `.tres` resources directly and reports any items without tags or items whose tags don't match any anchor points in that scene. This also runs automatically on every PR via GitHub Actions.

---

### Fixing thumbnails after moving images to shared/ *(optional)*

If you move an item's image from a scene folder into `shared/`, its `.tres` thumbnail reference breaks. Fix it without losing any manual positioning data:

```bash
godot --headless --script scripts/hide_seek/automation/fix_item_thumbnails.gd -- --theme <scene_name>
```

This script:
- Repairs stale or embedded thumbnail references for all existing items
- Adds any items from `themes.json` that are missing from the `.tres` (new items added since last preseed)
- **Does not touch** positions, radii, scales, anchors, or tags

---

## Generating Assets Programmatically

`generate_assets.py` calls the Google Imagen API (`imagen-4.0-fast-generate-001`) to batch-generate item and background images from `themes.json`. This costs API credits — **always confirm before running**.

```bash
# Generate all missing assets for one theme
python scripts/hide_seek/automation/generate_assets.py --theme <scene_name>

# Generate from a flat JSON manifest
python scripts/hide_seek/automation/generate_assets.py --manifest my_manifest.json
```

Requires a `GEMINI_API_KEY` in `.env`. The script caps at 3 generations per run for review cycles.

---

## Python Script Dependencies

```bash
pip install Pillow python-dotenv google-genai
brew install webp   # for cwebp (WebP conversion)
```
