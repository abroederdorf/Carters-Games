import os
import time
import io
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
client = genai.Client(api_key=API_KEY)
MODEL_NAME = "imagen-4.0-fast-generate-001"

ASSET_ROOT = Path("assets/sprites/hide_seek")
SHARED_ROOT = Path("assets/sprites/hide_seek/shared")

# --- Prefixes ---
CHARACTER_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "
OBJECT_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, isolated object only, no people, no characters, no background, no shadows, no text, "

# --- Load Master Index ---
THEMES_JSON = Path("assets/data/hide_seek/themes.json")

def load_master_index():
    with open(THEMES_JSON, "r") as f:
        return json.load(f)

def main():
    index = load_master_index()
    themes = index["themes"]
    shared = index["shared"]
    
    for theme_name, data in themes.items():
        theme_dir = ASSET_ROOT / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)
        
        # 1. Background
        generate_image(data['scene'], theme_dir / "bg.png", MODEL_NAME, aspect_ratio="16:9")
        time.sleep(5)
        
        # 2. Items
        for item_data in data['items']:
            item_name = item_data["name"]
            
            # Skip shared items for local generation
            if "shared" in item_data:
                continue
                
            item_path = theme_dir / f"{item_name}.png"
            if item_path.exists():
                continue
                
            prefix = CHARACTER_PREFIX if item_data.get("type") == "character" else OBJECT_PREFIX
            success = generate_image(prefix + item_data["desc"], item_path, MODEL_NAME)
            if success:
                time.sleep(5)

if __name__ == "__main__":
    main()
