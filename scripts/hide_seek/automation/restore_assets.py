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

# Targeted re-generation of Fire Station and specific missing-white items
TARGETS = {
    "fire_station": [
        "dalmatian", "boots", "bell", "fire_truck", "ladder", 
        "truck_fast", "hose_reel", "axe", "fire_extinguisher", "helmet", "hydrant"
    ],
    "mountains": ["bear", "skier", "fish", "hiker", "birds", "climber"],
    "ocean": ["shark", "clownfish", "submarine", "sea_turtle", "jellyfish"]
}

ITEM_DESCRIPTIONS = {
    "dalmatian": "cute white dog with black spots, wearing a small red fire hat",
    "boots": "pair of tall black rubber fire boots, yellow trim",
    "bell": "shiny silver alarm bell on a red bracket",
    "fire_truck": "classic red fire truck, ladder on side, shiny chrome details",
    "ladder": "silver extendable ladder, leaning slightly",
    "truck_fast": "large red airport fire crash tender, multiple wheels",
    "hose_reel": "large red reel with a thick gray fire hose coiled",
    "axe": "firefighter's axe with a red head and wooden handle",
    "fire_extinguisher": "red extinguisher with a black hose and silver handle",
    "helmet": "bright red firefighter helmet, yellow shield on front",
    "hydrant": "classic red street fire hydrant, three-way valves",
    "bear": "cute brown grizzly bear, standing upright, friendly face",
    "skier": "person in a blue snowsuit skiing, red skis, goggles",
    "fish": "silver trout jumping out of water, simple scales",
    "hiker": "person with a backpack and walking stick, wearing a green hat",
    "birds": "group of small black birds flying in a V formation",
    "climber": "person climbing a rock wall with a rope and harness",
    "shark": "gray shark with a white belly, large fin, simple teeth",
    "clownfish": "orange and white striped tropical fish, friendly",
    "submarine": "yellow submarine with a periscope and round windows",
    "sea_turtle": "green sea turtle swimming, brown shell pattern",
    "jellyfish": "pink translucent jellyfish with long flowing tentacles"
}

def generate_image(prompt, output_path, model="imagen-4.0-generate-001"):
    print(f"Re-generating: {output_path.relative_to(ASSET_ROOT)}...")
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
            image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
            
            # Robust transparency for re-generation
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
            print(f"  Successfully restored {output_path.name}")
            return True
    except Exception as e:
        print(f"  Error: {e}")
    return False

def main():
    for theme, items in TARGETS.items():
        theme_dir = ASSET_ROOT / theme
        for item in items:
            desc = ITEM_DESCRIPTIONS.get(item)
            if not desc: continue
            
            output_path = theme_dir / f"{item}.png"
            success = generate_image(ITEM_PREFIX + desc, output_path)
            if success:
                time.sleep(10) # Standard model needs more cooling time

if __name__ == "__main__":
    main()
