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
MODEL_NAME = "imagen-4.0-fast-generate-001" # Fast model for these 3

ASSET_ROOT = Path("assets/sprites/hide_seek")
ITEM_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "

# --- Targeted Themes ---
TARGETS = {
    "dinosaur_land": {
        "scene": "Children's book illustration of a prehistoric prehistoric landscape. Smoking volcanoes in the distance, lush palm jungles, a bubbling tar pit, and large dinosaur footprints in the mud. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with prehistoric details like fossils, exotic ferns, and flying pterodactyls in the sky. Wild, ancient, and exciting mood.",
        "items": {
            "t_rex": "cute orange Tyrannosaurus Rex, tiny arms, big friendly smile",
            "triceratops": "blue triceratops with three white horns and a large frill",
            "stegosaurus": "green stegosaurus with red plates on its back and a spiky tail",
            "dino_egg": "large speckled egg sitting in a nest of straw",
            "volcano": "small triangular volcano with a puff of smoke coming out",
            "fossil": "white dinosaur bone partially embedded in a gray rock",
            "pterodactyl": "purple flying dinosaur with large wings, beak open",
            "palm_tree": "tall palm tree with a brown trunk and large green fronds",
            "fern": "bright green tropical fern leaf, symmetrical and simple",
            "footprint": "large three-toed dinosaur footprint in brown mud"
        }
    },
    "construction_site": {
        "scene": "Children's book illustration of a busy construction site. Tall yellow cranes, a partially built skyscraper with steel beams, piles of dirt, and various heavy machinery. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with site details like traffic cones, blueprints, toolboxes, and safety signs. Busy, industrious, and loud mood.",
        "items": {
            "excavator": "bright yellow excavator with a large digging bucket and tracks",
            "dump_truck": "yellow dump truck with a large tilting bed, big wheels",
            "cement_mixer": "white and orange cement mixer with a rotating drum",
            "hard_hat": "classic bright yellow plastic construction worker hat",
            "traffic_cone": "orange and white striped safety cone, triangular",
            "bulldozer": "yellow bulldozer with a large flat blade on the front",
            "hammer": "metal claw hammer with a wooden handle, simple",
            "blueprint": "rolled-up blue paper with white architectural lines",
            "toolbox": "red metal toolbox with a silver handle on top",
            "safety_vest": "bright neon orange vest with reflective silver stripes"
        }
    },
    "monster_truck_jam": {
        "scene": "Children's book illustration of a high-energy monster truck arena. Dirt ramps, crushed old cars, stadium lights, and a cheering crowd in the background. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with arena details like flags, mud splatters, tires, and trophies. Loud, exciting, and powerful mood.",
        "items": {
            "monster_truck": "giant truck with massive black tires and a purple flame body",
            "crushed_car": "flat, crumpled blue car, windows cracked, sitting in mud",
            "gas_can": "red plastic gasoline container with a black spout",
            "checkered_flag": "black and white checkered racing flag on a pole",
            "tire": "large, chunky black monster truck tire, thick tread",
            "flame_decal": "bright red and yellow fire flame sticker, stylized",
            "megaphone": "white plastic megaphone with a red handle and strap",
            "trophy": "large gold trophy cup with two handles, shiny",
            "mud_splatter": "brown splat of mud, irregular and messy shape",
            "wrench": "silver metal wrench, open-end and box-end, simple"
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
        generate_image(data['scene'], theme_dir / "bg.png", MODEL_NAME, aspect_ratio="16:9")
        time.sleep(5)
        
        # 2. Items
        for item_name, item_desc in data['items'].items():
            item_path = theme_dir / f"{item_name}.png"
            if item_path.exists(): continue
            
            success = generate_image(ITEM_PREFIX + item_desc, item_path, MODEL_NAME)
            if success: time.sleep(5)

if __name__ == "__main__":
    main()
