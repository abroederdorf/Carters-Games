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

### 2. Pre-seeding
- Instead of automated vision mapping, we use a Godot script to "pre-seed" the scene.
- This script (`scripts/hide_seek/automation/preseed_scene.gd`) creates the initial Godot resources.
- Items are stacked in the upper-left (0.5 scale) and 50 anchors are placed in an offset grid pattern (40.0 radius) across the 16:9 scene.
- This provides a clean starting point for manual placement in the Godot Scene Builder.

### 3. Godot Resource Finalization
- Manual placement and tagging are performed in the Godot Editor.
- Resources are stored in `resources/hide_seek/`.

## Resource & Cost Management
- **MANDATORY CONFIRMATION:** Never execute scripts that perform expensive API operations (Image generation) without explicit user confirmation.
- **CONFIRMATION KEYWORD:** For any generation tasks, you MUST wait for the user to explicitly say "PROCEED WITH GENERATION". Do not interpret "go ahead", "yes", or "ok" as sufficient for full batch execution.
- **STRICT BATCH LIMITS:** All generation scripts (e.g. `generate_assets.py`) must enforce a hard limit of **3 items per run** to allow for style review and prevent accidental large-scale credit usage.
- **Affected Scripts:** This includes `generate_*.py` scripts.
- **Local Alternatives:** Always use the local `preseed_scene.gd` script to initialize scenes rather than relying on automated vision analysis.

## Directory Structure
- `assets/sprites/hide_seek/[theme_name]/`: Source images.
- `assets/sprites/hide_seek/shared/`: Reusable isolated items.
- `resources/hide_seek/[theme_name].tres`: Main scene resource.
- `resources/hide_seek/[theme_name]/`: Individual item resources.
- `scripts/hide_seek/`: Python automation and GDScript resource builders.
