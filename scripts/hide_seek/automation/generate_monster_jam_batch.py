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

ASSET_ROOT = Path("assets/sprites/hide_seek/monster_truck_jam")
OBJECT_PREFIX = "Isolated on white background, isolated object only, no people, no characters, no background, "
ITEM_SUFFIX = ", centered, thick black outlines, vibrant colors, children's book illustration, 512x512."

ITEMS = {
    "racing_helmet": {
        "prompt": OBJECT_PREFIX + "simple red and white full-face racing helmet with a dark visor, slight 3/4 view, flat design" + ITEM_SUFFIX
    },
    "pennant_flag": {
        "prompt": OBJECT_PREFIX + "generic triangular sports pennant flag on a thin wooden stick, two-tone blue and yellow with simple nested triangle shapes, perfectly flat side view, flat design" + ITEM_SUFFIX
    },
    "oil_can": {
        "prompt": OBJECT_PREFIX + "classic silver metal oil can with a long flexible spout, perfectly flat side view, flat design" + ITEM_SUFFIX
    },
    "dirt_pile": {
        "prompt": OBJECT_PREFIX + "simple rounded mound of brown dirt, slight 3/4 view, flat design, simple vector shapes" + ITEM_SUFFIX
    },
    "crowd_barrier": {
        "prompt": OBJECT_PREFIX + "silver metal crowd control barrier fence, perfectly flat side view, flat design" + ITEM_SUFFIX
    },
    "foam_finger": {
        "prompt": OBJECT_PREFIX + "oversized blue foam finger with the index finger pointing up, perfectly flat front view, flat design" + ITEM_SUFFIX
    },
    "broken_car_door": {
        "prompt": OBJECT_PREFIX + "single dented blue car door laying flat on the ground, slight 3/4 view from above, flat design, simple shapes" + ITEM_SUFFIX
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
