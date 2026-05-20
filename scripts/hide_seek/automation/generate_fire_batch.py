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

ASSET_ROOT = Path("assets/sprites/hide_seek/fire_station")
OBJECT_PREFIX = "Isolated on white background, isolated object only, no people, no characters, no background, "
ITEM_SUFFIX = ", centered, thick black outlines, vibrant colors, children's book illustration, 512x512."

ITEMS = {
    "walkie_talkie": {
        "prompt": OBJECT_PREFIX + "black handheld radio with a short antenna and push-to-talk button, slight 3/4 view to show depth" + ITEM_SUFFIX
    },
    "bucket": {
        "prompt": OBJECT_PREFIX + "simple silver galvanized metal bucket with a silver handle, slight 3/4 view showing the opening" + ITEM_SUFFIX
    },
    "badge": {
        "prompt": OBJECT_PREFIX + "shiny gold star-shaped firefighter badge, perfectly flat front view" + ITEM_SUFFIX
    },
    "fire_hose": {
        "prompt": OBJECT_PREFIX + "neatly coiled gray fire hose with a brass nozzle, slight 3/4 view" + ITEM_SUFFIX
    }
}

def generate_image(prompt, output_path):
    if output_path.exists():
        print(f"Skipping {output_path.name}, already exists.")
        return
    
    print(f"Generating {output_path.name}...")
    try:
        response = client.models.generate_images(
            model=MODEL_NAME,
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
        else:
            print("  No image generated.")
    except Exception as e:
        print(f"  Error: {e}")

def main():
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    for name, data in ITEMS.items():
        output_path = ASSET_ROOT / f"{name}.png"
        generate_image(data['prompt'], output_path)
        time.sleep(2)

if __name__ == "__main__":
    main()
