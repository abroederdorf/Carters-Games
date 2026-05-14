import os
import json
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
from google import genai
from google.genai import types
from PIL import Image

# --- Configuration ---
API_KEY = os.environ.get("GEMINI_API_KEY", "")
client = genai.Client(api_key=API_KEY)
# We use Gemini 2.5 Flash for its strong vision capabilities
VISION_MODEL = "gemini-2.5-flash"

ASSET_ROOT = Path("assets/sprites/hide_seek")
RESOURCE_ROOT = Path("resources/hide_seek")

PROMPT = """
You are a game designer for a 'Find the Hidden Object' game. 
Look at this background image for a children's game.

Task 1: Anchor Points
Identify exactly 50 natural-looking anchor points where an object could be hidden. 
Image Dimensions: {width} x {height}

Spatial Distribution Rules (MANDATORY):
1. Imagine the image divided into a 5x4 grid (20 equal cells).
2. You MUST place at least 2 anchor points in every single cell of that grid.
3. This ensures points are spread into the far corners, edges, and 'empty' areas, not just clustered in the center.
4. The remaining 10 points should be placed in the most visually complex areas.

Data Rules:
- Provide (X, Y) pixel coordinates where (0,0) is top-left.
- Provide a 'Radius' (R) in pixels for the touch area (usually 20-50px).
- Tags: "ground", "sky", "water", "foliage", "structure", "shadow".
- Difficulty: 0 (Easy/Visible), 1 (Medium/Partial cover), 2 (Hard/Very hidden).

Task 2: Item Suggestions
Suggest 15 items to hide in this specific scene.
- "In Scene" (7-8 items): Items that are actually part of the background art (e.g. if there is a specific rock or flower in the image).
- "Thematic" (7-8 items): Items that fit the theme but are NOT in the image (e.g. a 'compass' in a jungle).
- Provide a short visual 'desc' for each, optimized for image generation.

Return result STRICTLY as JSON object:
{{
  "anchors": [{{"x": X, "y": Y, "radius": R, "tags": [T], "difficulty": D}}],
  "items": [{{"name": "slug", "desc": "description", "type": "in_scene"|"thematic"}}]
}}
"""

def get_analysis_for_image(image_path):
    print(f"Analyzing: {image_path.name}")
    
    img = Image.open(image_path)
    width, height = img.size
    
    with open(image_path, "rb") as f:
        image_bytes = f.read()

    try:
        response = client.models.generate_content(
            model=VISION_MODEL,
            contents=[
                PROMPT.format(width=width, height=height),
                types.Part.from_bytes(data=image_bytes, mime_type="image/png")
            ]
        )
        
        text = response.text
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
            
        return json.loads(text.strip())
    except Exception as e:
        print(f"  Error: {e}")
        return None

THEMES_JSON = Path("assets/data/hide_seek/themes.json")
ANCHORS_JSON = Path("assets/data/hide_seek/anchors_data.json")
SUGGESTIONS_JSON = Path("assets/data/hide_seek/item_suggestions.json")

def main():
    with open(THEMES_JSON, "r") as f:
        index = json.load(f)
    
    themes = index["themes"].keys()
    
    # Load existing data to merge
    all_anchors = {}
    if ANCHORS_JSON.exists():
        with open(ANCHORS_JSON, "r") as f:
            all_anchors = json.load(f)
            
    all_suggestions = {}
    if SUGGESTIONS_JSON.exists():
        with open(SUGGESTIONS_JSON, "r") as f:
            all_suggestions = json.load(f)

    for theme in themes:
        print(f"Checking theme: {theme}")
        theme_dir = ASSET_ROOT / theme
        
        # Look for the best background
        bg_path = None
        possible_names = [
            f"bg_{theme}.png",
            f"bg_{theme.replace('_land', '')}.png",
            f"bg_{theme.replace('_jam', '')}.png",
            f"bg_{theme.replace('monster_truck_jam', 'monster_jam')}.png",
            f"bg_{theme.replace('mountains', 'mountain')}.png",
            f"bg_{theme.replace('_site', '')}.png",
            "bg.png",
            "bg_fast.png"
        ]
        
        for name in possible_names:
            p = theme_dir / name
            if p.exists():
                bg_path = p
                print(f"  Found background: {name}")
                break
        
        # Final fallback: Look for any png starting with bg_
        if not bg_path:
            for p in theme_dir.glob("bg_*.png"):
                bg_path = p
                print(f"  Found background via glob: {p.name}")
                break
        
        if not bg_path:
            print(f"  No background found for {theme}")
            continue
        
        target_themes = ["mountains", "ocean", "jungle", "space", "dinosaur_land", "fire_station", "monster_truck_jam", "construction_site"]
        if theme not in target_themes:
            print(f"  Theme {theme} not in target list, skipping.")
            continue

        result = get_analysis_for_image(bg_path)
        if result:
            all_anchors[theme] = result.get("anchors", [])
            all_suggestions[theme] = result.get("items", [])
            print(f"  Captured {len(all_anchors[theme])} anchors and {len(all_suggestions[theme])} suggestions.")
            
            # Save incrementally
            with open(ANCHORS_JSON, "w") as f:
                json.dump(all_anchors, f, indent=2)
            with open(SUGGESTIONS_JSON, "w") as f:
                json.dump(all_suggestions, f, indent=2)

    print("\nProcessing complete.")

if __name__ == "__main__":
    main()
