# Hide & Seek Scene Automation

## Workflow Overview
We are automating the creation of a 45-scene "Find the Hidden Object" game for Android tablets. The workflow consists of three automated stages:

### 1. Asset Generation
- **Model:** `imagen-4.0-fast-generate-001` (Fast, $0.02/image) via Google GenAI API.
- **Backgrounds:** 16:9 aspect ratio, panoramic landscape.
- **Items:** 1:1 aspect ratio.
- **Surgical Prompting Pattern:** Always follow the **[Isolated] -> [Object/Orientation] -> [Style]** structure to prevent the AI from generating full scenes or incorrect perspectives.
    - **Isolated:** Always start with `Isolated on white background`.
    - **Orientation:** If a specific angle is needed (e.g. for game overlays), specify `perfect side profile` or `flat side view`.
    - **Object:** Describe the core subject (e.g. `simple oval-shaped red fish, no whiskers, solid color body with no patterns`).
    - **Style:** Always end with `thick black outlines, flat design, children's book illustration`.
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

## Directory Structure
- `assets/sprites/hide_seek/[theme_name]/`: Source images.
- `assets/sprites/hide_seek/shared/`: Reusable isolated items.
- `resources/hide_seek/[theme_name].tres`: Main scene resource.
- `resources/hide_seek/[theme_name]/`: Individual item resources.
- `scripts/hide_seek/`: Python automation and GDScript resource builders.
