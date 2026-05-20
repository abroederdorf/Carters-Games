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

# See local/hide-seek-art-guide.md for canonical item prompt formula.
CHARACTER_PREFIX = "Isolated on white background, "
OBJECT_PREFIX = "Isolated on white background, isolated object only, no people, no characters, no background, "
ITEM_SUFFIX = ", centered, thick black outlines, vibrant colors, children's book illustration, 512x512."

# --- Master Themes Data (Refined) ---
THEMES = {
    "pet_shop": {
        "scene": "Children's book illustration of a busy pet shop. Rows of fish tanks, bird cages, and a play area for puppies. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "hamster": {"desc": "cute fuzzy hamster sitting upright, eating a seed", "type": "character"},
            "kitten": {"desc": "tiny orange kitten playing with a ball of yarn", "type": "character"},
            "puppy": {"desc": "happy brown puppy wagging its tail", "type": "character"},
            "goldfish_bowl": {"desc": "round glass bowl with blue water and one orange fish", "type": "object"},
            "parrot": {"desc": "bright green parrot sitting on a perch", "type": "character"},
            "bunny": {"desc": "small white rabbit with long ears", "type": "character"},
            "cat_toy": {"desc": "small colorful ball with a bell and feathers", "type": "object"},
            "guinea_pig": {"desc": "round brown and white guinea pig", "type": "character"},
            "turtle": {"desc": "small green turtle in a shallow water dish", "type": "character"},
            "lizard": {"desc": "bright green gecko clinging to a branch", "type": "character"}
        }
    },
    "circus": {
        "scene": "Children's book illustration of a grand circus tent interior. A center ring with sand, colorful spotlights, tiered seating. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "clown_nose": {"desc": "bright red sponge ball, perfectly round", "type": "object"},
            "top_hat": {"desc": "black felt magician hat with a red ribbon", "type": "object"},
            "unicycle": {"desc": "silver unicycle with a black seat and one wheel", "type": "object"},
            "trapeze": {"desc": "simple horizontal bar hanging from two long ropes", "type": "object"},
            "aerial_hoop": {"desc": "large metal ring for aerial acrobatics", "type": "object"},
            "lion": {"desc": "sitting male lion with a large mane", "type": "character"},
            "popcorn": {"shared": "popcorn"},
            "megaphone": {"shared": "megaphone"},
            "cotton_candy": {"desc": "pink fluffy cloud of candy on a paper cone", "type": "object"},
            "juggling_club": {"desc": "three colorful juggling pins", "type": "object"}
        }
    },
    "city": {
        "scene": "Children's book illustration of a busy city street corner. Tall buildings, storefronts, traffic, and a small park. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "taxi": {"desc": "bright yellow city taxi cab with a 'TAXI' sign", "type": "object"},
            "stop_sign": {"desc": "red octagonal sign with white 'STOP' text", "type": "object"},
            "traffic_light": {"desc": "black pole with red, yellow, and green lights", "type": "object"},
            "skyscraper": {"desc": "tall blue glass building with many small windows", "type": "object"},
            "fire_hydrant": {"shared": "fire_hydrant"},
            "trash_can": {"desc": "silver metal bin with a lid", "type": "object"},
            "bus": {"desc": "long bright red city bus, simple shapes", "type": "object"},
            "bicycle": {"shared": "bicycle"},
            "subway_sign": {"desc": "white sign with a large blue 'S' or 'M' letter", "type": "object"},
            "newsstand": {"desc": "small green box with a glass window", "type": "object"}
        }
    },
    # The script will now proceed with the remaining 30 themes...
}

def generate_image(prompt, output_path, model, aspect_ratio="1:1"):
    if output_path.exists(): return True
    print(f"Generating: {output_path.relative_to(ASSET_ROOT) if ASSET_ROOT in output_path.parents else output_path.name}...")
    try:
        response = client.models.generate_images(
            model=model,
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
            print(f"  Saved.")
            return True
    except Exception as e:
        print(f"  Error: {e}")
    return False

# Function to be expanded with all 41 themes and logic...
def main():
    # Initial run for the 3 refined themes
    for theme_name, data in THEMES.items():
        theme_dir = ASSET_ROOT / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)
        generate_image(data['scene'], theme_dir / "bg.png", MODEL_NAME, aspect_ratio="16:9")
        time.sleep(5)
        for item_name, item_data in data['items'].items():
            if "shared" in item_data: continue
            item_path = theme_dir / f"{item_name}.png"
            prefix = CHARACTER_PREFIX if item_data["type"] == "character" else OBJECT_PREFIX
            generate_image(f"{prefix}{item_data['desc']}{ITEM_SUFFIX}", item_path, MODEL_NAME)
            time.sleep(5)

if __name__ == "__main__":
    main()
