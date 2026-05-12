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

# --- Prefixes ---
CHARACTER_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, no shadows, no text, "
OBJECT_PREFIX = "Children's book illustration, flat design, bright saturated colors, thick black outlines, white background, centered, isolated object only, no people, no characters, no background, no shadows, no text, "

# --- ALL 45 THEMES ---
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
    "airport": {
        "scene": "Children's book illustration of a busy modern airport terminal and runway. Large glass windows, planes parked at gates, baggage handlers, fueling trucks, and a control tower. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "airplane": {"desc": "white commercial jet, blue tail, windows along side", "type": "object"},
            "luggage_cart": {"desc": "silver cart with three suitcases stacked on it", "type": "object"},
            "pilot": {"desc": "person in blue uniform, pilot cap, sunglasses", "type": "character"},
            "control_tower": {"desc": "tall white tower, glass top, radar dish", "type": "object"},
            "passport": {"desc": "blue passport book, gold emblem on front", "type": "object"},
            "taxi_sign": {"desc": "yellow airport taxi sign, black text 'TAXI'", "type": "object"},
            "wind_sock": {"desc": "orange and white striped wind sock, blowing", "type": "object"},
            "helicopter": {"desc": "small red helicopter, black rotors", "type": "object"},
            "security_camera": {"desc": "small white camera on a bracket", "type": "object"},
            "departure_board": {"desc": "black screen with rows of orange text", "type": "object"}
        }
    },
    "classroom": {
        "scene": "Children's book illustration of a colorful, busy primary school classroom. Desks with chairs, a large chalkboard with drawings, bookshelves, and cubbies. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "globe": {"desc": "colorful world globe on a gold stand, tilted", "type": "object"},
            "pencil_sharpener": {"desc": "retro crank-style sharpener, silver, sitting", "type": "object"},
            "apple": {"desc": "bright red apple with a green leaf, shiny", "type": "object"},
            "stack_of_books": {"desc": "three colorful books stacked neatly", "type": "object"},
            "ruler": {"desc": "yellow wooden ruler, black markings, straight", "type": "object"},
            "chalkboard_eraser": {"desc": "wooden block with gray felt, dusty", "type": "object"},
            "lunchbox": {"desc": "blue metal lunchbox with a handle", "type": "object"},
            "backpack": {"shared": "backpack"},
            "scissors": {"desc": "child-safe scissors, blue plastic handles", "type": "object"},
            "paint_palette": {"desc": "wooden palette with blobs of rainbow paint", "type": "object"}
        }
    },
    "kitchen": {
        "scene": "Children's book illustration of a large, cozy family kitchen. Wooden cabinets, a big island, a stove with pots, and a refrigerator with magnets. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "toaster": {"desc": "silver toaster, one slice of bread popping up", "type": "object"},
            "rolling_pin": {"desc": "wooden rolling pin, handles on both ends", "type": "object"},
            "tea_kettle": {"desc": "bright red tea kettle, steam from spout", "type": "object"},
            "mixing_bowl": {"desc": "large yellow ceramic bowl, white interior", "type": "object"},
            "spatula": {"desc": "turquoise silicone spatula, wooden handle", "type": "object"},
            "egg_carton": {"desc": "gray cardboard carton, six white eggs", "type": "object"},
            "salt_shaker": {"desc": "glass shaker with silver top, 'S' on front", "type": "object"},
            "chef_hat": {"desc": "tall white pleated chef hat, upright", "type": "object"},
            "oven_mitt": {"desc": "red quilted oven mitt, simple pattern", "type": "object"},
            "measuring_cup": {"desc": "clear plastic cup with red markings", "type": "object"}
        }
    },
    "soccer_game": {
        "scene": "Children's book illustration of a busy soccer stadium during a match. Green pitch, stadium seating with fans, floodlights, and a scoreboard. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "soccer_ball": {"desc": "classic black and white pentagon pattern ball", "type": "object"},
            "goal_post": {"desc": "white metal goal frame with net", "type": "object"},
            "whistle": {"desc": "silver referee whistle on a lanyard", "type": "object"},
            "yellow_card": {"desc": "bright yellow rectangular card", "type": "object"},
            "water_bottle": {"desc": "transparent blue sports bottle, pop-top", "type": "object"},
            "corner_flag": {"desc": "small red flag on a white pole", "type": "object"},
            "cleats": {"desc": "pair of bright green soccer shoes, studs", "type": "object"},
            "trophy": {"shared": "trophy"},
            "jersey": {"desc": "striped blue and white soccer jersey", "type": "object"},
            "stopwatch": {"desc": "silver digital stopwatch, black buttons", "type": "object"}
        }
    },
    "baseball_game": {
        "scene": "Children's book illustration of a classic baseball diamond. Red clay infield, green grass outfield, dugouts, and bleachers. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "baseball_bat": {"desc": "wooden baseball bat, light tan, grain", "type": "object"},
            "baseball_glove": {"desc": "brown leather catcher's mitt, pocket open", "type": "object"},
            "baseball": {"desc": "white ball with red stitching, circular", "type": "object"},
            "batting_helmet": {"desc": "blue plastic helmet, ear guard", "type": "object"},
            "hot_dog": {"desc": "hot dog in a bun, yellow mustard squiggle", "type": "object"},
            "foam_finger": {"desc": "large blue 'Number 1' foam finger", "type": "object"},
            "home_plate": {"desc": "white pentagonal rubber plate, dirty", "type": "object"},
            "pitcher_s_mound": {"desc": "small dirt hill, white rubber slab", "type": "object"},
            "cap": {"desc": "red baseball cap, white logo on front", "type": "object"},
            "pennant_flag": {"desc": "triangular felt flag, 'TEAM' on it", "type": "object"}
        }
    },
    "basketball_game": {
        "scene": "Children's book illustration of a bright indoor basketball arena. Polished wooden court, hoop at each end, tiered seating. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "basketball": {"desc": "orange ball with black lines, textured", "type": "object"},
            "hoop": {"desc": "orange rim with white net, clear backboard", "type": "object"},
            "sneaker": {"desc": "high-top basketball shoe, red and black", "type": "object"},
            "scoreboard": {"desc": "black digital board with red LED numbers", "type": "object"},
            "megaphone": {"shared": "megaphone"},
            "pom_poms": {"desc": "pair of fluffy gold and blue pom-poms", "type": "object"},
            "headband": {"desc": "white terrycloth headband, thick", "type": "object"},
            "wristband": {"desc": "pair of blue terrycloth wristbands", "type": "object"},
            "clipboard": {"desc": "wooden clipboard with court diagram", "type": "object"},
            "dunking_figure": {"desc": "silhouette of player jumping to hoop", "type": "character"}
        }
    },
    "zoo": {
        "scene": "Children's book illustration of a busy, colorful city zoo. Enclosures, paved paths with visitors, and snack stands. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "elephant": {"desc": "cute gray elephant, trunk raised, smiling", "type": "character"},
            "lion": {"desc": "male lion with bushy mane, sitting proudly", "type": "character"},
            "giraffe": {"desc": "tall yellow giraffe with brown spots", "type": "character"},
            "penguin": {"desc": "small tuxedo-colored penguin, orange beak", "type": "character"},
            "zebra": {"desc": "black and white striped zebra, standing", "type": "character"},
            "zoo_map": {"desc": "colorful paper map with animal icons", "type": "object"},
            "ice_cream_cart": {"desc": "white cart with a colorful umbrella", "type": "object"},
            "flamingo": {"desc": "pink flamingo standing on one leg", "type": "character"},
            "gorilla": {"desc": "large dark gray gorilla sitting, friendly", "type": "character"},
            "hippo": {"desc": "purple-gray hippo with mouth wide open", "type": "character"}
        }
    },
    "beach": {
        "scene": "Children's book illustration of a sunny beach. Golden sand, blue ocean waves, people under umbrellas. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "sandcastle": {"desc": "yellow sandcastle with towers and red flag", "type": "object"},
            "beach_ball": {"desc": "classic beach ball with red, blue, yellow", "type": "object"},
            "sunglasses": {"desc": "bright pink sunglasses with dark lenses", "type": "object"},
            "flip_flops": {"desc": "pair of turquoise flip-flops, yellow straps", "type": "object"},
            "beach_umbrella": {"desc": "striped blue and white umbrella in sand", "type": "object"},
            "surfboard": {"desc": "long wooden surfboard, green stripe", "type": "object"},
            "lifeguard_chair": {"desc": "tall white chair, red life ring", "type": "object"},
            "seashell": {"desc": "pink spiral conch shell on sand", "type": "object"},
            "sunscreen_bottle": {"desc": "yellow bottle with SPF 50 and sun icon", "type": "object"},
            "pail_and_shovel": {"desc": "blue bucket with red plastic spade", "type": "object"}
        }
    },
    "lake_fishing": {
        "scene": "Children's book illustration of a peaceful mountain lake. Calm blue water, pine forest, and a small wooden dock. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "fishing_rod": {"desc": "brown rod, silver reel, line hanging", "type": "object"},
            "tackle_box": {"desc": "green plastic box, colorful lures", "type": "object"},
            "rowboat": {"desc": "small red wooden boat, two oars", "type": "object"},
            "frog": {"desc": "bright green frog on a lily pad", "type": "character"},
            "dragonfly": {"desc": "small blue dragonfly, translucent wings", "type": "character"},
            "fishing_net": {"desc": "wooden handle, mesh net, triangular", "type": "object"},
            "bobber": {"desc": "red and white circular fishing float", "type": "object"},
            "canoe": {"desc": "long orange canoe, two paddles", "type": "object"},
            "cattails": {"desc": "cluster of brown cattail plants", "type": "object"},
            "duck": {"desc": "mother duck with yellow ducklings", "type": "character"}
        }
    },
    "playground": {
        "scene": "Children's book illustration of a large, busy playground. Soft rubber ground, various play structures, and trees. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "slide": {"desc": "tall yellow spiral slide, silver ladder", "type": "object"},
            "swing_set": {"desc": "two red swings, blue metal frame", "type": "object"},
            "seesaw": {"desc": "orange and green seesaw, handles", "type": "object"},
            "sandbox": {"desc": "wooden square with sand and toys", "type": "object"},
            "jungle_gym": {"desc": "colorful metal dome structure", "type": "object"},
            "tricycle": {"shared": "tricycle"},
            "kite": {"desc": "diamond-shaped purple kite, long tail", "type": "object"},
            "frisbee": {"desc": "bright orange plastic flying disc", "type": "object"},
            "drinking_fountain": {"desc": "silver fountain on concrete base", "type": "object"},
            "monkey_bars": {"desc": "red horizontal ladder on tall poles", "type": "object"}
        }
    },
    "farm": {
        "scene": "Children's book illustration of a busy, traditional farmyard. Rolling hills, vegetable patch, and a red barn. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "barn": {"desc": "large red barn, white roof, 'X' doors", "type": "object"},
            "tractor": {"desc": "bright green tractor, big black wheels", "type": "object"},
            "scarecrow": {"desc": "straw-filled man, flannel shirt and hat", "type": "character"},
            "pig": {"desc": "cute pink pig, curly tail, muddy", "type": "character"},
            "cow": {"desc": "black and white spotted cow, grazing", "type": "character"},
            "rooster": {"desc": "colorful rooster with red comb, crowing", "type": "character"},
            "hay_bale": {"desc": "large yellow block of dried grass", "type": "object"},
            "pitchfork": {"desc": "wooden handle, three metal tines", "type": "object"},
            "ladder": {"shared": "ladder"},
            "chicken_coop": {"desc": "small wooden hut with wire fence", "type": "object"},
            "vegetable_basket": {"desc": "wicker basket with carrots and corn", "type": "object"}
        }
    },
    "car_repair": {
        "scene": "Children's book illustration of a busy car repair shop. Cars on lifts, tool chests, stacks of tires. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "wrench": {"shared": "wrench"},
            "tire": {"shared": "tire"},
            "oil_can": {"shared": "gas_can"}, # Reusing gas can for oil can
            "car_jack": {"desc": "red floor jack with a handle", "type": "object"},
            "battery": {"desc": "black car battery, red and blue terminals", "type": "object"},
            "steering_wheel": {"desc": "black three-spoke steering wheel", "type": "object"},
            "headlight": {"desc": "round glass car headlight, shiny", "type": "object"},
            "spark_plug": {"desc": "white and silver spark plug, small", "type": "object"},
            "toolbox": {"shared": "toolbox"},
            "funnel": {"desc": "bright orange plastic oil funnel", "type": "object"}
        }
    },
    "wood_shop": {
        "scene": "Children's book illustration of a cozy wood shop. Workbenches, saws on walls, piles of lumber. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "hand_saw": {"desc": "classic hand saw, wooden handle", "type": "object"},
            "hammer": {"shared": "hammer"},
            "wood_glue": {"desc": "white bottle, orange tip, 'GLUE' label", "type": "object"},
            "measuring_tape": {"desc": "yellow retractable tape measure", "type": "object"},
            "pencil": {"desc": "thick yellow carpenter's pencil, flat", "type": "object"},
            "clamp": {"desc": "black and orange bar clamp, screw", "type": "object"},
            "birdhouse": {"desc": "small wooden birdhouse, round hole", "type": "object"},
            "ladder": {"shared": "ladder"},
            "paintbrush": {"desc": "wide brush, red handle, tan bristles", "type": "object"},
            "screwdriver": {"desc": "blue handled flat-head screwdriver", "type": "object"},
            "safety_goggles": {"desc": "clear plastic goggles, black strap", "type": "object"}
        }
    },
    "doctors_office": {
        "scene": "Children's book illustration of a doctor's exam room. Exam table, medical charts, height scale. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "stethoscope": {"desc": "blue stethoscope, silver chest piece", "type": "object"},
            "thermometer": {"desc": "white digital thermometer, smiley face", "type": "object"},
            "bandaid": {"desc": "tan adhesive bandage with small hearts", "type": "object"},
            "reflex_hammer": {"desc": "silver hammer, triangular red head", "type": "object"},
            "clipboard": {"desc": "wooden clipboard, colorful medical chart", "type": "object"},
            "medicine_bottle": {"desc": "orange plastic bottle, white cap", "type": "object"},
            "scales": {"desc": "white standing height and weight scale", "type": "object"},
            "otoscope": {"desc": "silver tool for looking in ears, glowing", "type": "object"},
            "tongue_depressor": {"desc": "simple flat wooden stick", "type": "object"},
            "vitamins": {"desc": "jar of colorful gummy bear vitamins", "type": "object"}
        }
    },
    "grocery_store": {
        "scene": "Children's book illustration of a grocery store aisle. Cereal boxes, fruit, checkout counter. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "shopping_cart": {"desc": "silver wire cart, four red wheels", "type": "object"},
            "banana": {"desc": "single bright yellow banana, curved", "type": "object"},
            "milk_carton": {"desc": "white and blue carton, cow icon", "type": "object"},
            "egg_carton": {"desc": "gray cardboard carton, six eggs", "type": "object"},
            "cereal_box": {"desc": "bright red box, bowl of colorful loops", "type": "object"},
            "apple": {"desc": "shiny red apple, green leaf", "type": "object"},
            "bread": {"desc": "loaf of sliced bread, clear bag", "type": "object"},
            "basket": {"desc": "red plastic handheld shopping basket", "type": "object"},
            "scanner": {"desc": "black handheld barcode scanner", "type": "object"},
            "juice_bottle": {"desc": "clear bottle, orange juice, straw", "type": "object"}
        }
    },
    "restaurant": {
        "scene": "Children's book illustration of a family diner. Checkerboard floor, red booths, kitchen window. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "burger": {"desc": "hamburger with cheese, sesame bun", "type": "object"},
            "menu": {"desc": "tall red menu, 'DELICIOUS' on front", "type": "object"},
            "ketchup": {"desc": "red squeeze bottle, yellow cap", "type": "object"},
            "mustard": {"desc": "yellow squeeze bottle, red cap", "type": "object"},
            "milkshake": {"desc": "pink strawberry milkshake, cherry", "type": "object"},
            "plate": {"desc": "white ceramic plate, blue rim", "type": "object"},
            "fork_and_spoon": {"desc": "silver fork and spoon crossed", "type": "object"},
            "napkin_holder": {"desc": "silver dispenser, white napkins", "type": "object"},
            "pizza_slice": {"desc": "triangular slice with pepperoni", "type": "object"},
            "waiter_tray": {"desc": "silver circular tray, white cloth", "type": "object"}
        }
    },
    "ice_cream_shop": {
        "scene": "Children's book illustration of a colorful ice cream parlor. Rainbow walls, glass display case. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "ice_cream_cone": {"desc": "waffle cone, large scoop of pink ice cream", "type": "object"},
            "sprinkles": {"desc": "jar of colorful rainbow sprinkles", "type": "object"},
            "scooper": {"desc": "silver ice cream scoop, black handle", "type": "object"},
            "cherry": {"desc": "bright red cherry, green stem", "type": "object"},
            "sundae": {"desc": "glass bowl, three scoops, cherry", "type": "object"},
            "popsicle": {"desc": "rainbow striped popsicle on a stick", "type": "object"},
            "banana_split": {"desc": "long dish with bananas, cream", "type": "object"},
            "spoon": {"desc": "small colorful plastic tasting spoon", "type": "object"},
            "apron": {"desc": "white apron, pink ice cream cone print", "type": "object"},
            "topping_shaker": {"desc": "clear shaker with chocolate chips", "type": "object"}
        }
    },
    "art_studio": {
        "scene": "Children's book illustration of a messy art studio. Easels, paint splattered tables. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "easel": {"desc": "wooden stand, blank white canvas", "type": "object"},
            "paint_palette": {"desc": "wooden palette, blobs of rainbow paint", "type": "object"},
            "brush_jar": {"desc": "glass jar with many paintbrushes", "type": "object"},
            "sketchbook": {"desc": "open book, pencil drawing of a cat", "type": "object"},
            "crayons": {"desc": "box of 8 colorful wax crayons", "type": "object"},
            "pottery_wheel": {"desc": "gray spinning wheel, small clay pot", "type": "object"},
            "watercolor_set": {"desc": "tin box, small squares of dry paint", "type": "object"},
            "sculpting_tool": {"desc": "wooden tool with wire loop", "type": "object"},
            "canvas_frame": {"desc": "empty ornate wooden frame", "type": "object"},
            "beret": {"desc": "classic red artist hat", "type": "object"}
        }
    },
    "arctic": {
        "scene": "Children's book illustration of a snowy arctic landscape. Icebergs, snow drifts, igloo. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "polar_bear": {"desc": "fluffy white bear, friendly smile", "type": "character"},
            "penguin": {"desc": "black and white penguin, sliding", "type": "character"},
            "igloo": {"desc": "dome-shaped house of white ice blocks", "type": "object"},
            "walrus": {"desc": "brown walrus, long white tusks", "type": "character"},
            "snowmobile": {"desc": "red snow vehicle, skis on front", "type": "object"},
            "fishing_hole": {"desc": "round hole in ice, fishing rod", "type": "object"},
            "snowflake": {"desc": "large symmetrical white and blue snowflake", "type": "object"},
            "parka": {"desc": "thick blue coat, furry hood", "type": "object"},
            "sled": {"desc": "wooden sled, silver runners", "type": "object"},
            "mittens": {"desc": "pair of red wool mittens", "type": "object"}
        }
    },
    "cruise_ship": {
        "scene": "Children's book illustration of a giant cruise ship. Multiple decks, pools, ocean. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "life_ring": {"desc": "red and white circular life preserver", "type": "object"},
            "captain_hat": {"desc": "white hat, gold anchor, black brim", "type": "object"},
            "deck_chair": {"desc": "blue striped lounge chair", "type": "object"},
            "binocular": {"shared": "binoculars"},
            "anchor": {"desc": "large gray iron anchor, heavy chain", "type": "object"},
            "pool_float": {"desc": "yellow rubber ring, duck shape", "type": "object"},
            "sunscreen": {"desc": "yellow bottle, sun icon, SPF 100", "type": "object"},
            "cocktail_glass": {"desc": "fruit juice, tiny umbrella, straw", "type": "object"},
            "ship_wheel": {"desc": "wooden steering wheel, many spokes", "type": "object"},
            "fog_horn": {"desc": "large brass horn, shiny", "type": "object"}
        }
    },
    "desert": {
        "scene": "Children's book illustration of a sandy desert. Giant cacti, rolling dunes, oasis. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "cactus": {"desc": "tall green saguaro cactus, two arms", "type": "object"},
            "camel": {"desc": "brown camel, two humps, smiling", "type": "character"},
            "lizard": {"desc": "small green lizard, long tail", "type": "character"},
            "canteen": {"desc": "metal water bottle, canvas strap", "type": "object"},
            "scorpion": {"desc": "purple desert scorpion, curled tail", "type": "character"},
            "cowboy_hat": {"desc": "brown felt hat, curved brim", "type": "object"},
            "tumbleweed": {"desc": "ball of dry brown branches", "type": "object"},
            "fossil_skull": {"desc": "white cow skull in sand", "type": "object"},
            "treasure_map": {"desc": "rolled-up map, 'X' marks the spot", "type": "object"},
            "tent": {"shared": "tent"}
        }
    },
    "bowling_alley": {
        "scene": "Children's book illustration of a bright bowling alley. Wooden lanes, colorful balls. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "bowling_pin": {"desc": "white pin, two red stripes", "type": "object"},
            "bowling_ball": {"desc": "bright blue ball, three holes", "type": "object"},
            "bowling_shoe": {"desc": "clown-style shoe, red and blue", "type": "object"},
            "trophy": {"shared": "trophy"},
            "pizza_box": {"desc": "square box, 'FRESH PIZZA' icon", "type": "object"},
            "soda_cup": {"desc": "striped cup, lid, straw", "type": "object"},
            "scorecard": {"desc": "paper with grids, 'X' and '/'", "type": "object"},
            "ball_rack": {"desc": "metal stand, three colorful balls", "type": "object"},
            "strike_sign": {"desc": "bright neon sign, 'STRIKE!'", "type": "object"},
            "bench": {"desc": "curved orange plastic bench", "type": "object"}
        }
    },
    "arcade": {
        "scene": "Children's book illustration of a neon-lit arcade. Game machines, prize counter. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "joystick": {"desc": "red ball-top joystick, black base", "type": "object"},
            "game_token": {"desc": "gold coin with a star", "type": "object"},
            "ticket_roll": {"desc": "long strip of red tickets", "type": "object"},
            "prize_bear": {"desc": "giant fluffy teddy bear, ribbon", "type": "character"},
            "air_hockey_paddle": {"desc": "red plastic mallet, felt bottom", "type": "object"},
            "claw_machine": {"desc": "silver metal claw for machines", "type": "object"},
            "racing_wheel": {"desc": "black steering wheel, buttons", "type": "object"},
            "pixel_heart": {"desc": "red heart, colorful squares", "type": "object"},
            "gamepad": {"desc": "gray controller, d-pad, buttons", "type": "object"},
            "popcorn_bucket": {"shared": "popcorn"}
        }
    },
    "movie_theater": {
        "scene": "Children's book illustration of a large movie theater. Rows of red seats, silver screen. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "popcorn": {"shared": "popcorn"},
            "movie_ticket": {"desc": "yellow ticket stub, 'ADMIT ONE'", "type": "object"},
            "film_reel": {"desc": "silver metal reel, black film strip", "type": "object"},
            "3d_glasses": {"desc": "red and blue cardboard glasses", "type": "object"},
            "projector": {"desc": "vintage movie projector, two reels", "type": "object"},
            "clapperboard": {"desc": "black and white board, 'SCENE 1'", "type": "object"},
            "drink_cup": {"desc": "large blue cup, white lid, straw", "type": "object"},
            "candy_box": {"desc": "bright yellow box, raisins", "type": "object"},
            "red_chair": {"desc": "plush red theater seat, cup holder", "type": "object"},
            "flashlight": {"shared": "flashlight"}
        }
    },
    "neighborhood": {
        "scene": "Children's book illustration of a friendly street. Colorful houses, sidewalks, mail truck. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "mailbox": {"desc": "blue standing mailbox, red flag up", "type": "object"},
            "bicycle": {"shared": "bicycle"},
            "dog_house": {"desc": "small brown house, red roof", "type": "object"},
            "fire_hydrant": {"shared": "fire_hydrant"},
            "street_lamp": {"desc": "tall black pole, glowing top", "type": "object"},
            "picket_fence": {"desc": "section of white wooden fence", "type": "object"},
            "flower_pot": {"desc": "orange clay pot, yellow daisies", "type": "object"},
            "tricycle": {"shared": "tricycle"},
            "mail_truck": {"desc": "white truck, blue and red stripe", "type": "object"},
            "trash_can": {"desc": "silver metal bin with a lid", "type": "object"}
        }
    },
    "music_studio": {
        "scene": "Children's book illustration of a high-tech music studio. Large speakers, mixing board. Wide panoramic landscape (2:1 ratio), bright saturated colors, flat design, thick black outlines, no text.",
        "items": {
            "microphone": {"desc": "silver mic on a tall black stand", "type": "object"},
            "headphones": {"desc": "large blue over-ear headphones", "type": "object"},
            "guitar": {"desc": "brown acoustic guitar, six strings", "type": "object"},
            "keyboard": {"desc": "black and white electronic keys", "type": "object"},
            "speaker": {"desc": "large black speaker box, woofer", "type": "object"},
            "record_player": {"desc": "vintage turntable, black record", "type": "object"},
            "cassette_tape": {"desc": "clear plastic tape, brown reels", "type": "object"},
            "note": {"desc": "black musical eighth note", "type": "object"},
            "metronome": {"desc": "wooden pyramid-shaped timekeeper", "type": "object"},
            "gold_record": {"desc": "shiny gold vinyl, square frame", "type": "object"}
        }
    }
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

def main():
    for theme_name, data in THEMES.items():
        theme_dir = ASSET_ROOT / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)
        
        # 1. Background
        generate_image(data['scene'], theme_dir / "bg.png", MODEL_NAME, aspect_ratio="16:9")
        time.sleep(5)
        
        # 2. Items
        for item_name, item_data in data['items'].items():
            if "shared" in item_data: continue
            item_path = theme_dir / f"{item_name}.png"
            prefix = CHARACTER_PREFIX if item_data["type"] == "character" else OBJECT_PREFIX
            success = generate_image(prefix + item_data["desc"], item_path, MODEL_NAME)
            if success: time.sleep(5)

if __name__ == "__main__":
    main()
