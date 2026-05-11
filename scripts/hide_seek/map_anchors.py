import os
import json
import time
import io
import base64
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
client = genai.Client(api_key=API_KEY)
# We use Gemini 2.5 Flash for its strong vision capabilities
VISION_MODEL = "gemini-2.5-flash"

ASSET_ROOT = Path("assets/sprites/hide_seek")
RESOURCE_ROOT = Path("resources/hide_seek")

PROMPT = """
You are a game designer placing anchor points for a 'Find the Hidden Object' game.
Look at this background image for a children's game.

Identify 50 natural-looking anchor points where an object could be hidden (e.g., on a shelf, behind a rock, in a tree, on a cloud, on the floor, in a window, on a ledge).

Rules:
1. Spread the points across the entire scene (foreground, midground, background).
2. For each point, provide (X, Y) pixel coordinates where (0,0) is top-left and (1920, 1080) is bottom-right.
3. For each point, provide a 'Radius' in pixels (typically 25 to 130).
4. For each point, provide a list of 'Tags' describing the surface/context. Use: "ground", "sky", "water", "foliage", "structure", "shadow".
5. For each point, provide a 'Difficulty' (0: Easy, 1: Medium, 2: Hard). Hard points should be small, in shadows, or partially tucked behind something.

Return the result STRICTLY as a JSON array of objects:
[
  {"x": 100, "y": 200, "radius": 80, "tags": ["ground"], "difficulty": 0},
  ...
]
"""

def get_anchors_for_image(image_path):
    print(f"Analyzing: {image_path}")
    
    with open(image_path, "rb") as f:
        image_bytes = f.read()

    response = client.models.generate_content(
        model=VISION_MODEL,
        contents=[
            PROMPT,
            types.Part.from_bytes(data=image_bytes, mime_type="image/png")
        ]
    )
    
    text = response.text
    # Extract JSON if there's any markdown wrapping
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0]
    elif "```" in text:
        text = text.split("```")[1].split("```")[0]
        
    try:
        return json.loads(text.strip())
    except Exception as e:
        print(f"Error parsing JSON for {image_path}: {e}")
        print("Raw response:", text)
        return None

def update_godot_resource(theme_name, anchors):
    # This function will generate the GDScript to update the resources
    # For now, we'll just print the data or save it to a JSON for the GDScript to read.
    pass

def main():
    themes = [
        "mountains", "ocean", "jungle", "space", 
        "fire_station", "dinosaur_land", "construction_site", "monster_truck_jam"
    ]
    
    all_anchors = {}
    
    for theme in themes:
        theme_dir = ASSET_ROOT / theme
        bg_path = theme_dir / "bg.png"
        if not bg_path.exists():
            bg_path = theme_dir / "bg_fast.png"
        
        if not bg_path.exists():
            print(f"Background not found for {theme}")
            continue
            
        anchors = get_anchors_for_image(bg_path)
        if anchors:
            all_anchors[theme] = anchors
            print(f"  Found {len(anchors)} anchors for {theme}")
            
    # Save to a temporary JSON file for Godot to ingest
    with open("scripts/hide_seek/anchors_data.json", "w") as f:
        json.dump(all_anchors, f, indent=2)
    print("\nSaved anchor data to scripts/hide_seek/anchors_data.json")

if __name__ == "__main__":
    main()
