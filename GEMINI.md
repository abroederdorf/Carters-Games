# Hide & Seek Scene Automation

## Workflow Overview
We are automating the creation of a 45-scene "Find the Hidden Object" game for Android tablets. The workflow consists of three automated stages:

### 1. Asset Generation
- **Model:** `imagen-4.0-fast-generate-001` (Fast, $0.02/image) via Google GenAI API.
- **Backgrounds:** 16:9 aspect ratio, panoramic landscape.
- **Items:** 1:1 aspect ratio.
- **Surgical Prompting Pattern:** Always follow the **[Isolated] -> [Object/Orientation] -> [Style]** structure to prevent the AI from generating full scenes or incorrect perspectives. Canonical formula is in `local/hide-seek-art-guide.md`.
    - **Isolated:** Always start with `Isolated on white background`.
    - **Object:** Describe the core subject (e.g. `simple oval-shaped red fish, no whiskers, solid color body with no patterns`).
    - **Orientation:** Specify view — `perfectly flat front view`, `perfectly flat side view`, or `slight 3/4 view` (use 3/4 for items that would look flat or ambiguous in profile, e.g. buckets, cans, stacked items).
    - **Style:** Always end with `thick black outlines, vibrant colors, children's book illustration, 512x512`.
- **Prompts:** 
    - **Object Prefix:** Stricter prompt following the surgical pattern to ensure isolated objects (no people).
    - **Character Prefix:** Used for people or animals while maintaining the surgical structure.
- **Shared Library:** Reusable items (Hammer, Popcorn, etc.) are stored in `assets/sprites/hide_seek/shared/` and skipped during theme generation to save credits.

### 2. Vision Mapping
- Gemini analyzes the generated `bg.png` to identify the best thematic pixel coordinates (X, Y) and radius for each item.
- This mapping is then converted into a Godot `.tres` manifest.

### 3. Godot Resource Generation
- A Godot `SceneTree` script (e.g., `scripts/hide_seek/create_mountain_resources.gd`) programmatically creates:
    - `HideSeekItemData.tres` for each item.
    - `HideSeekSceneData.tres` for the full scene.
- Resources are stored in `resources/hide_seek/`.

## Resource & Cost Management
- **MANDATORY CONFIRMATION:** Never execute scripts that perform expensive API operations (Vision analysis, Image generation, etc.) without explicit user confirmation.
- **Affected Scripts:** This includes, but is not limited to:
    - `tag_items.py` (Vision analysis)
    - `map_anchors.py` (Vision mapping)
    - `generate_*.py` (Image generation)
- **Local Alternatives:** Always consider if a task can be performed locally (e.g., data migration) before resorting to paid API calls.

## Directory Structure
- `assets/sprites/hide_seek/[theme_name]/`: Source images.
- `assets/sprites/hide_seek/shared/`: Reusable isolated items.
- `resources/hide_seek/[theme_name].tres`: Main scene resource.
- `resources/hide_seek/[theme_name]/`: Individual item resources.
- `scripts/hide_seek/`: Python automation and GDScript resource builders.
