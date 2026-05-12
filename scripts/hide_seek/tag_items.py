import os
import json
from pathlib import Path
from google import genai
from google.genai import types

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
client = genai.Client(api_key=API_KEY)
TAG_MODEL = "gemini-2.5-flash"

ASSET_ROOT = Path("assets/sprites/hide_seek")

PROMPT = """
You are a game designer. Categorize these game items with appropriate tags for logical placement in a scene.

Available Tags:
- "ground": For items that sit on the floor, rocks, or dirt.
- "sky": For items that fly, float, or are in the air.
- "water": For items that belong in or on water (fish, anchors, boats).
- "foliage": For items that belong in trees, bushes, or flowers.
- "structure": For items that sit on buildings, shelves, or man-made objects.

Theme: {theme}
Items: {items}

Rules:
1. Return a JSON object where keys are item names and values are lists of 1-2 relevant tags.
2. If an item could fit in multiple (e.g. ground and structure), list both.

Example:
{{"bird": ["sky", "foliage"], "rock": ["ground"]}}
"""

def main():
    themes = [
        "mountains", "ocean", "jungle", "space", 
        "fire_station", "dinosaur_land", "construction_site", "monster_truck_jam"
    ]
    
    all_item_tags = {}
    
    for theme in themes:
        theme_dir = ASSET_ROOT / theme
        items = [f.stem for f in theme_dir.glob("*.png") if not f.name.startswith("bg")]
        
        if not items:
            continue
            
        print(f"Tagging items for: {theme}")
        
        formatted_prompt = PROMPT.format(theme=theme, items=", ".join(items))
        
        response = client.models.generate_content(
            model=TAG_MODEL,
            contents=formatted_prompt
        )
        
        text = response.text
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
            
        try:
            tags = json.loads(text.strip())
            all_item_tags[theme] = tags
            print(f"  Tagged {len(tags)} items.")
        except Exception as e:
            print(f"  Error parsing JSON for {theme}: {e}")
            
    with open("scripts/hide_seek/item_tags.json", "w") as f:
        json.dump(all_item_tags, f, indent=2)
    print("\nSaved item tags to scripts/hide_seek/item_tags.json")

if __name__ == "__main__":
    main()
