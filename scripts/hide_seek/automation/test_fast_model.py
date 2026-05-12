import os
import time
import io
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
# Using the FAST model for testing
MODEL_NAME = "imagen-4.0-fast-generate-001" 
client = genai.Client(api_key=API_KEY)

ASSET_ROOT = Path("assets/sprites/hide_seek")
THEME_NAME = "fire_station"

# --- Prompt Data ---
SCENE_PROMPT = "Children's book illustration of a busy, colorful fire station. Large red fire trucks in the bays, firefighters in uniform checking equipment, a fire pole, Dalmatian dogs, and a command center with maps. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with station details like hoses, ladders, helmets, and bells. Professional, heroic, and energetic mood."
ITEM_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "
ITEM_DESC = "classic red fire truck, ladder on side, shiny chrome details, simple shapes"

def generate_image(prompt, output_path, aspect_ratio="1:1"):
    print(f"Generating Fast: {output_path.name}...")
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
            image = Image.open(io.BytesIO(image_bytes))
            image.save(output_path)
            print(f"  Saved to {output_path}")
            return True
    except Exception as e:
        print(f"  Error: {e}")
    return False

def main():
    theme_dir = ASSET_ROOT / THEME_NAME
    theme_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate 1 Background and 1 Item to test quality
    generate_image(SCENE_PROMPT, theme_dir / "bg_fast.png", aspect_ratio="16:9")
    time.sleep(2)
    generate_image(ITEM_PREFIX + ITEM_DESC, theme_dir / "truck_fast.png", aspect_ratio="1:1")

if __name__ == "__main__":
    main()
