import os
import json
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
from google import genai
from google.genai import types

# --- Configuration ---
API_KEY = os.environ.get("GEMINI_API_KEY", "")
client = genai.Client(api_key=API_KEY)
TAG_MODEL = "gemini-2.5-flash"

ASSET_ROOT = Path("assets/sprites/hide_seek")

PROMPT = """
You are a game designer. Categorize these game items with appropriate tags and sizing for logical placement in a scene.

Available Tags:
- "ground": sits on floor, dirt, or rocks
- "sky": flies, floats, or lives in the air
- "water": belongs in or on water
- "foliage": lives in trees or bushes
- "structure": sits on walls, shelves, or man-made surfaces
- "shadow": tucked in dark or obscured areas

Rules:
1. Return a JSON object where keys are item names.
2. Value is an object: {{"tags": [list], "base_scale": float, "preferred_anchors": []}}
3. base_scale: 0.3 (tiny, e.g. bug/coin), 0.6 (small, e.g. camera/shoe), 1.0 (standard, e.g. bucket/dog), 2.0 (large, e.g. tent/bike), 3.0 (huge, e.g. car/boulder).
4. preferred_anchors: Leave as empty array [] for now.

Theme: {theme}
Items: {items}

Example:
{{"bird": {{"tags": ["sky", "foliage"], "base_scale": 0.5, "preferred_anchors": []}}}}
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
