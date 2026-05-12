import os
import json
from pathlib import Path
from google import genai
from google.genai import types

# --- Configuration ---
API_KEY = os.environ.get("GEMINI_API_KEY", "")
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

THEMES_JSON = Path("assets/data/hide_seek/themes.json")

def load_master_index():
    with open(THEMES_JSON, "r") as f:
        return json.load(f)

def main():
    index = load_master_index()
    themes = index["themes"]
    
    all_item_tags = {}
    
    for theme_name, theme_data in themes.items():
        items = []
        for item in theme_data["items"]:
            items.append(item["name"])
            
        if not items:
            continue
            
        print(f"Tagging items for: {theme_name}")
        
        formatted_prompt = PROMPT.format(theme=theme_name, items=", ".join(items))
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
            all_item_tags[theme_name] = tags
            print(f"  Tagged {len(tags)} items.")
        except Exception as e:
            print(f"  Error parsing JSON for {theme_name}: {e}")
            
    with open("assets/data/hide_seek/item_tags.json", "w") as f:
        json.dump(all_item_tags, f, indent=2)
    print("\nSaved item tags to assets/data/hide_seek/item_tags.json")

if __name__ == "__main__":
    main()
