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

SHARED_ROOT = Path("assets/sprites/hide_seek/shared")
SHARED_ROOT.mkdir(parents=True, exist_ok=True)

# --- Refined Prefixes ---
# Use this for items that ARE people (Hiker, Skier, etc.)
CHARACTER_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "

# Use this for items that are OBJECTS (Binoculars, Hammer, etc.)
OBJECT_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, isolated object only, no people, no characters, no background, no shadows, no text, "

# --- Shared Items Library ---
SHARED_ITEMS = {
    "binoculars": {"desc": "black and blue binoculars with a thin neck strap", "type": "object"},
    "hammer": {"desc": "metal claw hammer with a brown wooden handle", "type": "object"},
    "wrench": {"desc": "silver adjustable wrench, metallic look", "type": "object"},
    "tire": {"desc": "single black rubber tire with deep treads", "type": "object"},
    "popcorn": {"desc": "red and white striped bucket overflowing with buttered popcorn", "type": "object"},
    "trophy": {"desc": "large gold trophy cup with two handles, shiny", "type": "object"},
    "backpack": {"desc": "bright red hiking backpack with side pockets and straps", "type": "object"},
    "fire_hydrant": {"desc": "bright red street fire hydrant, three-way valves", "type": "object"},
    "tricycle": {"desc": "small green three-wheeled bike for a child", "type": "object"},
    "bicycle": {"desc": "red bike with a silver bell and a basket", "type": "object"},
    "tent": {"desc": "small orange camping tent, triangular, front flap open", "type": "object"},
    "toolbox": {"desc": "red metal toolbox with a silver handle on top", "type": "object"},
    "megaphone": {"desc": "red plastic megaphone with a handle", "type": "object"},
    "gas_can": {"desc": "red plastic gasoline container with a black spout", "type": "object"},
    "flashlight": {"desc": "silver flashlight with a bright yellow beam", "type": "object"},
    "camera": {"desc": "small black digital camera with a lens", "type": "object"}
}

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
    for item_name, data in SHARED_ITEMS.items():
        output_path = SHARED_ROOT / f"{item_name}.png"
        if output_path.exists():
            continue
            
        prefix = OBJECT_PREFIX if data["type"] == "object" else CHARACTER_PREFIX
        full_prompt = prefix + data["desc"]
        
        success = generate_image(full_prompt, output_path, MODEL_NAME)
        if success:
            time.sleep(5)

if __name__ == "__main__":
    main()
