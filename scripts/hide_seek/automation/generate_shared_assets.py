import os
import time
import io
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
MODEL_NAME = "imagen-4.0-fast-generate-001"

SHARED_ROOT = Path("assets/sprites/hide_seek/shared")

THEMES_JSON = Path("assets/data/hide_seek/themes.json")

# See local/hide-seek-art-guide.md for canonical item prompt formula.
CHARACTER_PREFIX = "Isolated on white background, "
OBJECT_PREFIX = "Isolated on white background, isolated object only, no people, no characters, no background, "
ITEM_SUFFIX = ", centered, thick black outlines, vibrant colors, children's book illustration, 512x512."

def load_master_index():
    with open(THEMES_JSON, "r") as f:
        return json.load(f)

def generate_image(prompt, output_path, model):
    print(f"Generating Shared: {output_path.name}...")
    try:
        response = client.models.generate_images(
            model=model,
            prompt=prompt,
            config=types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio="1:1",
                output_mime_type='image/png'
            )
        )
        if response.generated_images:
            image_bytes = response.generated_images[0].image.image_bytes
            image = Image.open(io.BytesIO(image_bytes))
            image.save(output_path)
            print(f"  Saved.")
            return True
    except Exception as e:
        print(f"  Error: {e}")
    return False

def main():
    SHARED_ROOT.mkdir(parents=True, exist_ok=True)
    index = load_master_index()
    shared_items = index["shared"]
    
    for item_name, data in shared_items.items():
        output_path = SHARED_ROOT / f"{item_name}.png"
        if output_path.exists():
            continue
            
        prefix = OBJECT_PREFIX if data["type"] == "object" else CHARACTER_PREFIX
        full_prompt = f"{prefix}{data['desc']}{ITEM_SUFFIX}"
        
        success = generate_image(full_prompt, output_path, MODEL_NAME)
        if success:
            time.sleep(5)

if __name__ == "__main__":
    main()
