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
ITEM_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "

# --- New 15 Themes ---
TARGETS = {
    "car_repair": {
        "scene": "Children's book illustration of a busy car repair shop. Cars on lifts, tool chests, stacks of tires, oil cans, and a friendly mechanic in overalls. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "wrench": "silver adjustable wrench, simple shape",
            "tire": "black rubber tire with deep treads",
            "oil_can": "red oil can with a long thin spout",
            "car_jack": "red floor jack with a handle",
            "battery": "black car battery with red and blue terminals",
            "steering_wheel": "black three-spoke steering wheel",
            "headlight": "round glass car headlight, shiny",
            "spark_plug": "white and silver spark plug, small",
            "toolbox": "red metal rolling tool chest",
            "funnel": "bright orange plastic oil funnel"
        }
    },
    "wood_shop": {
        "scene": "Children's book illustration of a cozy wood shop. Workbenches with wood shavings, saws hanging on walls, piles of lumber, and partially finished birdhouses. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "hand_saw": "classic hand saw with a brown wooden handle",
            "hammer": "metal claw hammer with a wooden handle",
            "wood_glue": "white bottle with an orange tip, 'GLUE' label",
            "measuring_tape": "yellow retractable tape measure, silver clip",
            "pencil": "thick yellow carpenter's pencil, flat shape",
            "clamp": "black and orange bar clamp, metal screw",
            "birdhouse": "small wooden birdhouse with a round hole",
            "paintbrush": "wide brush with a red handle and tan bristles",
            "screwdriver": "blue handled flat-head screwdriver",
            "safety_goggles": "clear plastic goggles with a black strap"
        }
    },
    "doctors_office": {
        "scene": "Children's book illustration of a friendly doctor's exam room. A tall exam table, charts on the wall, a height scale, and jars of cotton balls. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "stethoscope": "blue stethoscope with silver chest piece",
            "thermometer": "white digital thermometer showing a smiley face",
            "bandaid": "tan adhesive bandage with small hearts",
            "reflex_hammer": "silver hammer with a triangular red rubber head",
            "clipboard": "wooden clipboard with a colorful medical chart",
            "medicine_bottle": "orange plastic bottle with a white child-proof cap",
            "scales": "white standing height and weight scale",
            "otoscope": "small silver tool for looking in ears, glowing tip",
            "tongue_depressor": "simple flat wooden stick",
            "vitamins": "jar of colorful gummy bear vitamins"
        }
    },
    "grocery_store": {
        "scene": "Children's book illustration of a busy grocery store aisle. Shelves of cereal, fruit displays, a checkout counter, and shopping carts. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "shopping_cart": "silver wire cart with four red wheels",
            "banana": "single bright yellow banana, slightly curved",
            "milk_carton": "white and blue carton with a cow icon",
            "egg_carton": "gray cardboard carton with six white eggs",
            "cereal_box": "bright red box with a bowl of colorful loops",
            "apple": "shiny red apple with a small green leaf",
            "bread": "loaf of sliced bread in a clear bag",
            "basket": "red plastic handheld shopping basket",
            "scanner": "black handheld barcode scanner, red laser tip",
            "juice_bottle": "clear bottle with orange juice and a straw"
        }
    },
    "restaurant": {
        "scene": "Children's book illustration of a cheerful diner. Checkerboard floor, red booths, a counter with stools, and a kitchen window. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "burger": "hamburger with cheese, lettuce, and a sesame bun",
            "menu": "tall red menu with 'DELICIOUS' written on front",
            "ketchup": "red squeeze bottle with a yellow cap",
            "mustard": "yellow squeeze bottle with a red cap",
            "milkshake": "pink strawberry milkshake with a cherry and straw",
            "plate": "white ceramic plate with a blue rim",
            "fork_and_spoon": "silver fork and spoon crossed together",
            "napkin_holder": "silver dispenser with white napkins",
            "pizza_slice": "triangular slice with pepperoni and melted cheese",
            "waiter_tray": "silver circular tray with a white cloth"
        }
    },
    "ice_cream_shop": {
        "scene": "Children's book illustration of a colorful ice cream parlor. Rainbow-colored walls, a glass display case with many flavors, and tall sundae glasses. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "ice_cream_cone": "waffle cone with a large scoop of pink ice cream",
            "sprinkles": "jar of colorful rainbow sprinkles",
            "scooper": "silver ice cream scoop with a black handle",
            "cherry": "bright red cherry with a small green stem",
            "sundae": "glass bowl with three scoops, chocolate syrup, and a cherry",
            "popsicle": "rainbow striped popsicle on a wooden stick",
            "banana_split": "long dish with bananas, ice cream, and whipped cream",
            "spoon": "small colorful plastic tasting spoon",
            "apron": "white apron with a pink ice cream cone print",
            "topping_shaker": "clear shaker with chocolate chips"
        }
    },
    "art_studio": {
        "scene": "Children's book illustration of a messy art studio. Easels with canvases, paint splattered tables, jars of brushes, and colorful sculptures. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "easel": "wooden tripod stand with a blank white canvas",
            "paint_palette": "wooden palette with blobs of rainbow paint",
            "brush_jar": "glass jar filled with many different paintbrushes",
            "sketchbook": "open book with a pencil drawing of a cat",
            "crayons": "box of 8 colorful wax crayons",
            "pottery_wheel": "gray spinning wheel with a small clay pot",
            "watercolor_set": "tin box with small squares of dry paint",
            "sculpting_tool": "wooden tool with a wire loop for clay",
            "canvas_frame": "empty wooden frame for a painting",
            "beret": "classic red artist hat, wool texture"
        }
    },
    "arctic": {
        "scene": "Children's book illustration of a snowy arctic landscape. Icebergs in the sea, snow drifts, an igloo, and a view of the northern lights. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "polar_bear": "fluffy white bear standing on two legs, smiling",
            "penguin": "black and white penguin sliding on its belly",
            "igloo": "dome-shaped house made of white ice blocks",
            "walrus": "brown walrus with long white tusks, whiskers",
            "snowmobile": "red snow vehicle with skis on the front",
            "fishing_hole": "round hole in blue ice with a fishing rod",
            "snowflake": "large symmetrical white and blue snowflake",
            "parka": "thick blue coat with a furry hood",
            "sled": "wooden sled with silver metal runners",
            "mittens": "pair of red wool mittens connected by a string"
        }
    },
    "cruise_ship": {
        "scene": "Children's book illustration of a giant cruise ship. Multiple decks with pools, a tall smokestack, a captain's bridge, and the ocean. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "life_ring": "red and white circular life preserver, 'S.S. SMILE'",
            "captain_hat": "white hat with a gold anchor and black brim",
            "deck_chair": "blue striped lounge chair, slightly reclined",
            "binocular": "black binoculars with a neck strap",
            "anchor": "large gray iron anchor, heavy chain",
            "pool_float": "yellow rubber ring in the shape of a duck",
            "sunscreen": "yellow bottle with a sun icon, 'SPF 100'",
            "cocktail_glass": "tropical fruit juice with a tiny umbrella",
            "ship_wheel": "wooden steering wheel with many spokes",
            "fog_horn": "large brass horn, shiny"
        }
    },
    "desert": {
        "scene": "Children's book illustration of a sandy desert. Giant cacti, rolling dunes, an oasis with palm trees, and a hot yellow sun. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "cactus": "tall green saguaro cactus with two arms",
            "camel": "brown camel with two humps, smiling",
            "lizard": "small green lizard with a long curly tail",
            "canteen": "metal water bottle with a canvas strap",
            "scorpion": "purple desert scorpion with a curled tail",
            "cowboy_hat": "brown felt hat with a curved brim",
            "tumbleweed": "ball of dry brown branches, circular",
            "fossil_skull": "white cow skull in the sand",
            "treasure_map": "rolled-up map with an 'X' marks the spot",
            "tent": "simple canvas tent with a desert pattern"
        }
    },
    "bowling_alley": {
        "scene": "Children's book illustration of a bright bowling alley. Shiny wooden lanes, ball returns, colorful bowling balls, and score screens. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "bowling_pin": "white pin with two red stripes on the neck",
            "bowling_ball": "bright blue ball with three black finger holes",
            "bowling_shoe": "clown-style shoe, red and blue with a tan sole",
            "trophy": "tall gold trophy with a bowling ball on top",
            "pizza_box": "square box with 'FRESH PIZZA' and a slice icon",
            "soda_cup": "striped cup with a lid and a straw",
            "scorecard": "paper with grids and small 'X' and '/' marks",
            "ball_rack": "metal stand with three colorful balls",
            "strike_sign": "bright neon sign saying 'STRIKE!'",
            "bench": "curved orange plastic bench for players"
        }
    },
    "arcade": {
        "scene": "Children's book illustration of a neon-lit arcade. Game machines with joysticks, a prize counter, air hockey tables, and ticket dispensers. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "joystick": "red ball-top joystick with a black base",
            "game_token": "gold coin with a star in the center",
            "ticket_roll": "long strip of red tickets, perforated",
            "prize_bear": "giant fluffy teddy bear with a ribbon",
            "air_hockey_paddle": "red plastic mallet with a felt bottom",
            "claw_machine": "silver metal claw for a toy machine",
            "racing_wheel": "black steering wheel on a game cabinet",
            "pixel_heart": "red heart made of small squares",
            "gamepad": "gray controller with a d-pad and buttons",
            "popcorn_bucket": "red and white striped bucket filled with corn"
        }
    },
    "movie_theater": {
        "scene": "Children's book illustration of a large movie theater. Rows of red seats, a massive silver screen, curtains, and a projector beam. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "popcorn": "overflowing bucket of buttered popcorn",
            "movie_ticket": "yellow ticket stub, 'ADMIT ONE'",
            "film_reel": "silver metal reel with black film strip",
            "3d_glasses": "red and blue cardboard glasses",
            "projector": "vintage movie projector with two large reels",
            "clapperboard": "black and white board, 'SCENE 1, TAKE 1'",
            "drink_cup": "large blue cup with a lid and straw",
            "candy_box": "bright box of chocolate-covered raisins",
            "red_chair": "plush red theater seat with armrests",
            "flashlight": "silver flashlight with a bright yellow beam"
        }
    },
    "neighborhood": {
        "scene": "Children's book illustration of a friendly neighborhood street. Colorful houses, sidewalks, gardens, a mail truck, and kids playing. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "mailbox": "blue standing mailbox with a red flag up",
            "bicycle": "red bike with a silver bell and a basket",
            "dog_house": "small brown house with a red roof",
            "fire_hydrant": "bright red street hydrant",
            "street_lamp": "tall black pole with a glowing glass top",
            "picket_fence": "section of white wooden fence",
            "flower_pot": "orange clay pot with yellow daisies",
            "tricycle": "small green three-wheeled bike",
            "mail_truck": "white truck with a blue and red stripe",
            "trash_can": "silver metal bin with a lid"
        }
    },
    "music_studio": {
        "scene": "Children's book illustration of a high-tech music studio. Large speakers, a mixing board with sliders, a piano, and soundproof foam on walls. Panoramic landscape (2:1), bright colors, flat design, thick black outlines, no text.",
        "items": {
            "microphone": "silver mic on a tall black stand",
            "headphones": "large blue over-ear headphones, black padding",
            "guitar": "brown acoustic guitar with six strings",
            "keyboard": "black and white electronic piano keys",
            "speaker": "large black speaker box, circular woofer",
            "record_player": "vintage turntable with a black vinyl record",
            "cassette_tape": "clear plastic tape with brown reels",
            "note": "black musical eighth note, stylized",
            "metronome": "wooden pyramid-shaped timekeeper",
            "gold_record": "shiny gold vinyl in a square frame"
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
        generate_image(data['scene'], theme_dir / "bg.png", MODEL_NAME, aspect_ratio="16:9")
        time.sleep(5)
        for item_name, item_desc in data['items'].items():
            item_path = theme_dir / f"{item_name}.png"
            if item_path.exists(): continue
            success = generate_image(ITEM_PREFIX + item_desc, item_path, MODEL_NAME)
            if success: time.sleep(5)

if __name__ == "__main__":
    main()
