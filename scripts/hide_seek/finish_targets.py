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

ASSET_ROOT = Path("assets/sprites/hide_seek")
ITEM_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "

# --- Targeted Themes ---
TARGETS = {
    "fire_station": {
        "model": "imagen-4.0-fast-generate-001", # User requested Fast
        "scene": "Children's book illustration of a busy, colorful fire station. Large red fire trucks in the bays, firefighters in uniform checking equipment, a fire pole, Dalmatian dogs, and a command center with maps. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with station details like hoses, ladders, helmets, and bells. Professional, heroic, and energetic mood.",
        "items": {
            "fire_truck": "classic red fire truck, ladder on side, shiny chrome details, simple shapes",
            "dalmatian": "cute white dog with black spots, wearing a small red fire hat",
            "helmet": "bright red firefighter helmet, yellow shield on front",
            "fire_extinguisher": "red extinguisher with a black hose and silver handle",
            "hydrant": "classic red street fire hydrant, three-way valves",
            "axe": "firefighter's axe with a red head and wooden handle",
            "boots": "pair of tall black rubber fire boots, yellow trim",
            "hose_reel": "large red reel with a thick gray fire hose coiled",
            "bell": "shiny silver alarm bell on a red bracket",
            "ladder": "silver extendable ladder, leaning slightly"
        }
    },
    "space": {
        "model": "imagen-4.0-generate-001", # User requested Standard for consistency
        "scene": "Children's book illustration of a busy futuristic moon base. Gray lunar surface with craters, black star-filled sky with Earth visible in the distance, glass-domed habitats, satellite dishes, and neon-lit walkways. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with technological details, lunar rocks, flashing lights, and stars. Exciting and sci-fi mood.",
        "items": {
            "astronaut": "person in a white spacesuit, gold visor, waving, friendly",
            "alien": "small green alien, three eyes, antenna, waving, cute",
            "rocket": "red and white rocket ship, pointy nose, circular window",
            "moon_rover": "white buggy with big wheels, antenna, solar panel",
            "saturn": "planet with rings, yellow and orange, tilted",
            "star": "bright yellow five-pointed star, glowing effect",
            "flying_saucer": "silver UFO, glass dome, green lights underneath",
            "space_helmet": "white helmet with blue visor, sitting upright",
            "ray_gun": "retro ray gun, silver with red rings, bubble muzzle",
            "crater": "round gray moon crater, shadows inside, simple"
        }
    }
}

def generate_image(prompt, output_path, model, aspect_ratio="1:1"):
    if output_path.exists():
        return True
        
    print(f"Generating ({model}): {output_path.relative_to(ASSET_ROOT)}...")
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

def main():
    for theme_name, data in TARGETS.items():
        theme_dir = ASSET_ROOT / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)
        
        # 1. Background
        bg_name = "bg.png" if theme_name == "space" else "bg_fast.png" # Keep consistent with what we started
        generate_image(data['scene'], theme_dir / bg_name, data['model'], aspect_ratio="16:9")
        time.sleep(5)
        
        # 2. Items
        for item_name, item_desc in data['items'].items():
            item_path = theme_dir / f"{item_name}.png"
            if item_path.exists(): continue
            
            success = generate_image(ITEM_PREFIX + item_desc, item_path, data['model'])
            if success: time.sleep(5)

if __name__ == "__main__":
    main()
