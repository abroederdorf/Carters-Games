import os
import time
import io
import json
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
MODEL_NAME = "imagen-4.0-generate-001"
client = genai.Client(api_key=API_KEY)

ASSET_ROOT = Path("assets/sprites/hide_seek")

# --- All Themes Data ---
THEMES = {
    "mountains": {
        "scene": "Children's book illustration of a large, busy mountain scene packed with things to find. Snow-capped peaks in the background, pine forest on the slopes, a winding trail, a mountain lake, rocky cliffs, meadows with wildflowers. The scene is wide and panoramic (landscape orientation, roughly 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Every part of the scene is filled with interesting details — rocks, bushes, snowdrifts, fallen logs, streams. Friendly and adventurous mood, suitable for children age 5–8.",
        "items": {
            "bear": "cute brown bear sitting upright, friendly expression, simple shapes",
            "tent": "small orange camping tent, triangular, front flap open",
            "campfire": "small campfire with orange and yellow flames, logs underneath",
            "fish": "single trout fish, blue and silver with pink stripe, facing right",
            "climber": "person in red jacket and helmet scaling a rock wall, rope attached",
            "skier": "person in blue ski suit skiing downhill, poles out, goggles on",
            "hiker": "person in green jacket and hat walking with a wooden walking stick",
            "tree": "single pine/fir tree, dark green, triangular, simple",
            "flowers": "small cluster of three wildflowers, purple and yellow, green stems",
            "birds": "two small blue birds perched side by side, simple cartoon style",
            "backpack": "red hiking backpack with side pockets and straps, front-facing",
            "deer": "brown deer standing, white spots on back, small antlers, side view",
            "cave": "dark cave entrance in a rocky cliff face, stones around opening",
            "rock": "single large rounded gray boulder, simple, slightly mossy"
        }
    },
    "ocean": {
        "scene": "Children's book illustration of a vibrant, busy underwater coral reef scene. Sunbeams filtering through the blue water, colorful coral formations, bubbling vents, swaying seaweed, and sandy patches. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. The scene is packed with details like shells, pebbles, small schools of fish, and shipwrecks in the distance. Friendly and adventurous mood.",
        "items": {
            "shark": "cute blue shark, friendly smile, dorsal fin visible, simple shapes",
            "crab": "small bright red crab, large claws, big eyes, side view",
            "seahorse": "yellow seahorse, curly tail, facing left, whimsical",
            "treasure_chest": "golden treasure chest, slightly open with jewels peeking out",
            "jellyfish": "pink translucent jellyfish, long trailing tentacles, glowing effect",
            "submarine": "small yellow submarine, round porthole, periscope on top",
            "starfish": "orange starfish, textured surface, five-point shape, smiling",
            "sea_turtle": "green sea turtle, patterned shell, swimming pose, side view",
            "anchor": "old gray iron anchor, thick rope wrapped around it",
            "clownfish": "orange and white striped fish, small and round, friendly"
        }
    },
    "jungle": {
        "scene": "Children's book illustration of a dense, lush jungle canopy. Tall mahogany trees with vines, giant ferns, misty waterfalls in the background, a small stream flowing through. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Every corner is filled with leaves, colorful flowers, hidden hollows, and twisted roots. Tropical, lively, and mysterious mood.",
        "items": {
            "monkey": "cheeky brown monkey, long tail, hanging by one hand, smiling",
            "parrot": "bright scarlet macaw, red yellow and blue feathers, big beak",
            "tiger": "cute orange tiger with black stripes, sitting down, friendly",
            "snake": "coiled green snake, yellow belly, big friendly eyes",
            "butterfly": "large blue morpho butterfly, symmetrical wings, perched",
            "banana_bunch": "cluster of bright yellow bananas, slightly curved",
            "explorer_hat": "tan pith helmet, brown strap, sitting flat",
            "binoculars": "black binoculars, glass lenses reflecting light",
            "orchid": "exotic pink and white tropical flower, large petals",
            "sloth": "smiling sloth hanging from a branch, slow and cozy"
        }
    },
    "space": {
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
    },
    "train_station": {
        "scene": "Children's book illustration of a bustling Victorian-style train station. Grand arched roof, iron beams, brick platforms, steam trains puffing smoke, passengers waiting, and luggage carts. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with details like tracks, posters, pigeons, benches, and snack carts. Busy, nostalgic, and exciting mood.",
        "items": {
            "locomotive": "bright red steam engine, puffing smoke, big wheels",
            "ticket": "golden train ticket, 'PASS' written on it, punch hole",
            "suitcase": "brown vintage suitcase, leather straps, handle on top",
            "conductor_hat": "blue hat with gold braid, flat top",
            "station_clock": "round white clock, Roman numerals, black hands",
            "bench": "wooden station bench, iron legs, side view",
            "lantern": "old oil lantern, glass pane, glowing yellow light",
            "whistle": "silver train whistle, metal loop, shiny",
            "passenger": "person holding a newspaper, wearing a coat and hat",
            "signal_light": "tall pole with red and green lights, simple"
        }
    },
    "airport": {
        "scene": "Children's book illustration of a busy modern airport terminal and runway. Large glass windows, planes parked at gates, baggage handlers, fueling trucks, and a control tower in the background. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with details like signage, cones, ground vehicles, and runways. Dynamic, high-tech, and adventurous mood.",
        "items": {
            "airplane": "white commercial jet, blue tail, windows along the side",
            "luggage_cart": "silver cart with three suitcases stacked on it",
            "pilot": "person in blue uniform, pilot cap, aviator sunglasses",
            "control_tower": "tall white tower, glass top, radar dish on roof",
            "passport": "blue passport book, gold emblem on front",
            "taxi_sign": "yellow airport taxi sign, black text 'TAXI'",
            "wind_sock": "orange and white striped wind sock, blowing in wind",
            "helicopter": "small red helicopter, black rotors, landing skids",
            "security_camera": "small white camera on a bracket, black lens",
            "departure_board": "black screen with orange text rows, digital style"
        }
    },
    "classroom": {
        "scene": "Children's book illustration of a colorful, busy primary school classroom. Desks with chairs, a large chalkboard with drawings, bookshelves, cubbies, posters on the walls, and a play corner. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with classroom details like toys, plants, maps, and art supplies. Warm, educational, and lively mood.",
        "items": {
            "globe": "colorful world globe on a gold stand, tilted",
            "pencil_sharpener": "retro crank-style sharpener, silver, sitting on a desk",
            "apple": "bright red apple with a green leaf, shiny",
            "stack_of_books": "three colorful books stacked neatly, different colors",
            "ruler": "yellow wooden ruler, black markings, straight",
            "chalkboard_eraser": "wooden block with gray felt, dusty with chalk",
            "lunchbox": "blue metal lunchbox with a handle, simple latches",
            "backpack": "green school backpack, front pocket, side mesh for bottle",
            "scissors": "child-safe scissors, blue plastic handles, silver blades",
            "paint_palette": "wooden palette with blobs of rainbow paint, a brush on top"
        }
    },
    "kitchen": {
        "scene": "Children's book illustration of a large, cozy family kitchen. Wooden cabinets, a big island in the center, a stove with pots, a refrigerator with magnets, and a window over the sink. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with kitchen details like spices, fruit bowls, towels, and utensils. Homey, warm, and appetizing mood.",
        "items": {
            "toaster": "silver toaster, two slots, one slice of bread popping up",
            "rolling_pin": "wooden rolling pin, handles on both ends, smooth",
            "tea_kettle": "bright red tea kettle, steam coming from spout",
            "mixing_bowl": "large yellow ceramic bowl, white interior",
            "spatula": "turquoise silicone spatula, wooden handle",
            "egg_carton": "gray cardboard carton, half-dozen white eggs inside",
            "salt_shaker": "glass shaker with silver top, 'S' on the front",
            "chef_hat": "tall white pleated chef hat, sitting upright",
            "oven_mitt": "red quilted oven mitt, thumb out, simple pattern",
            "measuring_cup": "clear plastic cup with red volume markings, handle"
        }
    },
    "soccer_game": {
        "scene": "Children's book illustration of a busy soccer stadium during a match. Green pitch with white markings, stadium seating filled with colorful fans, floodlights, and a scoreboard. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with sports details like flags, equipment, cones, and benches. Energetic, competitive, and fun mood.",
        "items": {
            "soccer_ball": "classic black and white pentagon pattern ball",
            "goal_post": "white metal goal frame with net, green grass underneath",
            "whistle": "silver referee whistle on a black lanyard",
            "yellow_card": "bright yellow rectangular card, sharp corners",
            "water_bottle": "transparent blue sports bottle, pop-top lid",
            "corner_flag": "small red flag on a white pole, stuck in grass",
            "cleats": "pair of bright green soccer shoes, studs visible",
            "trophy": "gold trophy cup with two handles, shiny",
            "jersey": "striped blue and white soccer jersey, short sleeves",
            "stopwatch": "silver digital stopwatch, black buttons, lanyard"
        }
    },
    "baseball_game": {
        "scene": "Children's book illustration of a classic baseball diamond. Red clay infield, green grass outfield, dugouts, bleachers, and a large electronic scoreboard. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with stadium details like popcorn boxes, banners, batting cages, and lights. Summery, nostalgic, and sporting mood.",
        "items": {
            "baseball_bat": "wooden baseball bat, light tan, grain visible",
            "baseball_glove": "brown leather catcher's mitt, pocket open",
            "baseball": "white ball with red stitching, circular",
            "batting_helmet": "blue plastic helmet, ear guard on one side",
            "hot_dog": "hot dog in a bun, yellow mustard squiggle",
            "foam_finger": "large blue 'Number 1' foam finger",
            "home_plate": "white pentagonal rubber plate, slightly dirty",
            "pitcher_s_mound": "small dirt hill, white rubber slab on top",
            "cap": "red baseball cap, white logo on front, curved brim",
            "pennant_flag": "triangular felt flag, 'TEAM' written on it"
        }
    },
    "basketball_game": {
        "scene": "Children's book illustration of a bright indoor basketball arena. Polished wooden court, hoop at each end, tiered seating, and large screen overhead. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with court details like water coolers, towels, basketball racks, and team logos. Action-packed, vibrant, and indoor mood.",
        "items": {
            "basketball": "orange ball with black lines, textured surface",
            "hoop": "orange rim with white net, clear backboard",
            "sneaker": "high-top basketball shoe, red and black, laces tied",
            "scoreboard": "black digital board with red LED numbers",
            "megaphone": "red plastic cheerleading megaphone, handle",
            "pom_poms": "pair of fluffy gold and blue pom-poms",
            "headband": "white terrycloth headband, thick",
            "wristband": "pair of blue terrycloth wristbands",
            "clipboard": "wooden clipboard with a basketball court diagram",
            "dunking_figure": "silhouette of a player jumping towards a hoop"
        }
    },
    "zoo": {
        "scene": "Children's book illustration of a busy, colorful city zoo. Different enclosures (savanna, arctic, jungle), paved paths with visitors, snack stands, and a large entrance gate. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with zoo details like benches, signs, trees, and small animals. Educational, fun, and lively mood.",
        "items": {
            "elephant": "cute gray elephant, trunk raised, big ears, smiling",
            "lion": "male lion with large bushy mane, sitting proudly",
            "giraffe": "tall yellow giraffe with brown spots, long neck",
            "penguin": "small tuxedo-colored penguin, orange beak and feet",
            "zebra": "black and white striped zebra, standing, side view",
            "zoo_map": "colorful paper map with animal icons and paths",
            "ice_cream_cart": "white cart with a colorful umbrella and pictures of popsicles",
            "flamingo": "pink flamingo standing on one leg, curved neck",
            "gorilla": "large dark gray gorilla sitting, friendly expression",
            "hippo": "purple-gray hippo with mouth wide open, cute"
        }
    },
    "beach": {
        "scene": "Children's book illustration of a sunny, crowded beach. Golden sand, blue ocean waves with surfboards, people sunbathing under umbrellas, and a pier in the distance. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with beach details like seagulls, crabs, beach towels, and ice cream stalls. Summery, relaxing, and happy mood.",
        "items": {
            "sandcastle": "yellow sandcastle with towers and a red flag on top",
            "beach_ball": "classic beach ball with red, blue, and yellow panels",
            "sunglasses": "bright pink sunglasses with dark lenses",
            "flip_flops": "pair of turquoise flip-flops with yellow straps",
            "beach_umbrella": "striped blue and white umbrella stuck in sand",
            "surfboard": "long wooden surfboard with a green stripe",
            "lifeguard_chair": "tall white wooden chair with a red life ring hanging",
            "seashell": "pink spiral conch shell, sitting on sand",
            "sunscreen_bottle": "yellow bottle with 'SPF 50' and a sun icon",
            "pail_and_shovel": "blue bucket with a red plastic spade inside"
        }
    },
    "lake_fishing": {
        "scene": "Children's book illustration of a peaceful mountain lake at dawn. Calm blue water, pine forest surroundings, a small wooden dock, and mountains in the distance. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Filled with lake details like pebbles, reeds, fish jumping, and dragonflies. Serene, natural, and outdoor mood.",
        "items": {
            "fishing_rod": "brown rod with a silver reel and a line hanging",
            "tackle_box": "green plastic box, open to show small colorful lures",
            "rowboat": "small red wooden boat with two oars inside",
            "frog": "bright green frog sitting on a lily pad, big eyes",
            "dragonfly": "small blue dragonfly with translucent wings",
            "fishing_net": "wooden handle with a mesh net, triangular shape",
            "bobber": "red and white circular fishing float, bobbing in water",
            "canoe": "long orange canoe, two paddles, sitting on the shore",
            "cattails": "cluster of brown cattail plants with green leaves",
            "duck": "mother duck with three small yellow ducklings"
        }
    },
    "playground": {
        "scene": "Children's book illustration of a large, busy neighborhood playground. Soft rubber ground, various play structures, trees for shade, and benches for parents. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with playground details like discarded balls, hopscotch patterns, and flowers. Playful, safe, and energetic mood.",
        "items": {
            "slide": "tall yellow spiral slide, silver ladder",
            "swing_set": "two red swings hanging from a blue metal frame",
            "seesaw": "orange and green seesaw, handles on both ends",
            "sandbox": "wooden square filled with sand, colorful toys inside",
            "jungle_gym": "colorful metal dome structure for climbing",
            "tricycle": "classic red tricycle with black handles and wheels",
            "kite": "diamond-shaped purple kite with a long tail",
            "frisbee": "bright orange plastic flying disc",
            "drinking_fountain": "silver fountain on a concrete base, water arching",
            "monkey_bars": "red horizontal ladder on tall poles"
        }
    },
    "farm": {
        "scene": "Children's book illustration of a busy, traditional farmyard. Rolling green hills, a vegetable patch, a fenced-in pasture, and the farmhouse in the background. The scene is wide and panoramic (landscape orientation, 2:1 ratio). Bright saturated colors, flat design, thick black outlines, no text. Packed with farm details like mud puddles, grain sacks, butterflies, and a weather vane. Rustic, cozy, and hardworking mood.",
        "items": {
            "barn": "large red barn with a white roof and 'X' doors",
            "tractor": "bright green tractor with big black wheels",
            "scarecrow": "straw-filled man in a flannel shirt and hat",
            "pig": "cute pink pig, curly tail, muddy patches",
            "cow": "black and white spotted cow, chewing grass",
            "rooster": "colorful rooster with a bright red comb, crowing",
            "hay_bale": "large yellow rectangular block of dried grass",
            "pitchfork": "wooden handle with three sharp metal tines",
            "chicken_coop": "small wooden hut with a wire fence and a ramp",
            "vegetable_basket": "wicker basket overflowing with carrots and corn"
        }
    }
}

ITEM_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "

def generate_image(prompt, output_path, aspect_ratio="1:1"):
    print(f"Generating: {output_path.relative_to(ASSET_ROOT)}...")
    
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
            image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
            
            # Make white background transparent for items
            if aspect_ratio == "1:1":
                datas = image.getdata()
                new_data = []
                for item in datas:
                    if item[0] >= 240 and item[1] >= 240 and item[2] >= 240:
                        new_data.append((255, 255, 255, 0))
                    else:
                        new_data.append(item)
                image.putdata(new_data)
                
            image.save(output_path)
            print(f"  Successfully saved (with transparency).")
            return True
        else:
            print(f"  No images generated for {output_path.name}")
            return False
            
    except Exception as e:
        print(f"  Error generating {output_path.name}: {e}")
        return False

def main():
    for theme_name, data in THEMES.items():
        theme_dir = ASSET_ROOT / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)
        
        # 1. Generate Background (Scene)
        bg_path = theme_dir / "bg.png"
        if not bg_path.exists():
            generate_image(data['scene'], bg_path, aspect_ratio="16:9")
            time.sleep(5)
            
        # 2. Generate Items
        for item_name, item_desc in data['items'].items():
            item_path = theme_dir / f"{item_name}.png"
            if item_path.exists():
                continue
                
            full_prompt = ITEM_PREFIX + item_desc
            success = generate_image(full_prompt, item_path, aspect_ratio="1:1")
            
            if success:
                time.sleep(5)
            else:
                print(f"Wait a bit before retrying...")
                time.sleep(10)

if __name__ == "__main__":
    main()
