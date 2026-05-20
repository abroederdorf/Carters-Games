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

ASSET_ROOT = Path("assets/sprites/hide_seek/construction_site")
OBJECT_PREFIX = "Isolated on white background, isolated object only, no people, no characters, no background, "
CHARACTER_PREFIX = "Isolated on white background, "
ITEM_SUFFIX = ", centered, thick black outlines, vibrant colors, children's book illustration, 512x512."

# Applying "flat design" and "simple shapes" to prevent photorealism
FLAT_STYLE = ", perfectly flat design, simple vector shapes, no realistic textures"

ITEMS = {
    "crane": {
        "prompt": OBJECT_PREFIX + "tall yellow construction crane with a hook, simple lattice structure, perfectly flat side view" + FLAT_STYLE + ITEM_SUFFIX
    },
    "saw": {
        "prompt": OBJECT_PREFIX + "simple silver hand saw with a brown wooden handle, perfectly flat side view" + FLAT_STYLE + ITEM_SUFFIX
    },
    "brick_stack": {
        "prompt": OBJECT_PREFIX + "small neat stack of red clay bricks, slight 3/4 view" + FLAT_STYLE + ITEM_SUFFIX
    },
    "scaffolding": {
        "prompt": OBJECT_PREFIX + "simple gray metal scaffolding frame with a single wooden plank, slight 3/4 view" + FLAT_STYLE + ITEM_SUFFIX
    },
    "worker": {
        "prompt": CHARACTER_PREFIX + "friendly construction worker character wearing an orange safety vest and a yellow hard hat, waving, perfectly flat front view" + FLAT_STYLE + ITEM_SUFFIX
    },
    "wheelbarrow": {
        "prompt": OBJECT_PREFIX + "simple silver metal wheelbarrow with one black wheel, perfectly flat side view" + FLAT_STYLE + ITEM_SUFFIX
    },
    "measuring_tape": {
        "prompt": OBJECT_PREFIX + "yellow retractable measuring tape with a silver metal clip, slight 3/4 view" + FLAT_STYLE + ITEM_SUFFIX
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
