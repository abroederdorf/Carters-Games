import os
import time
import io
import json
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
MODEL_NAME = "imagen-4.0-fast-generate-001"
client = genai.Client(api_key=API_KEY)

ASSET_ROOT = Path("assets/sprites/hide_seek")
THEMES_JSON = Path("assets/data/hide_seek/themes.json")

# --- Prefixes ---
CHARACTER_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "
OBJECT_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, isolated object only, no people, no characters, no background, no shadows, no text, "

def load_master_index():
    with open(THEMES_JSON, "r") as f:
        return json.load(f)

def generate_image(prompt, output_path, aspect_ratio="1:1"):
    print(f"Generating: {output_path.relative_to(ASSET_ROOT)}...")
    
    try:
        response = client.models.generate_images(
            model=MODEL_NAME,
            prompt=prompt,
            config=types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio=aspect_ratio,
                output_mime_type='image/png'
            )
        )
        
        if response.generated_images:
            image_bytes = response.generated_images[0].image.image_bytes
            image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
            
            # Make white background transparent for items using outside-in flood fill
            if aspect_ratio == "1:1":
                from PIL import ImageDraw
                width, height = image.size
                seeds = []
                for x in range(width):
                    seeds.append((x, 0))
                    seeds.append((x, height - 1))
                for y in range(1, height - 1):
                    seeds.append((0, y))
                    seeds.append((width - 1, y))
                
                for seed in seeds:
                    pixel = image.getpixel(seed)
                    if pixel[3] > 0 and pixel[0] >= 235 and pixel[1] >= 235 and pixel[2] >= 235:
                        ImageDraw.floodfill(image, seed, (255, 255, 255, 0), thresh=30)
                
            image.save(output_path)
            print(f"  Successfully saved (with robust transparency).")
            return True
        else:
            print(f"  No images generated for {output_path.name}")
            return False
            
    except Exception as e:
        print(f"  Error generating {output_path.name}: {e}")
        return False

def main():
    index = load_master_index()
    themes = index["themes"]
    
    for theme_name, data in themes.items():
        theme_dir = ASSET_ROOT / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)
        
        # 1. Generate Background (Scene)
        bg_path = theme_dir / "bg.png"
        if not bg_path.exists():
            generate_image(data['scene'], bg_path, aspect_ratio="16:9")
            time.sleep(5)
            
        # 2. Generate Items
        for item_data in data['items']:
            item_name = item_data["name"]
            
            # Skip shared items for local generation
            if "shared" in item_data:
                continue
                
            item_path = theme_dir / f"{item_name}.png"
            if item_path.exists():
                continue
                
            prefix = CHARACTER_PREFIX if item_data.get("type") == "character" else OBJECT_PREFIX
            success = generate_image(prefix + item_data["desc"], item_path, aspect_ratio="1:1")
            
            if success:
                time.sleep(5)
            else:
                print(f"Wait a bit before retrying...")
                time.sleep(10)

if __name__ == "__main__":
    main()
