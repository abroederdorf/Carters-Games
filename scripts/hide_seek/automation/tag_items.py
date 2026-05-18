import json
import re
from pathlib import Path

THEMES_JSON = Path("assets/data/hide_seek/themes.json")
OUTPUT_JSON = Path("assets/data/hide_seek/item_tags.json")

# (scale, keywords) — checked in order, first match wins on name+desc
SCALE_RULES = [
    (3.0, ["car", "truck", "tractor", "vehicle", "boat", "ship", "submarine", "rocket",
           "dinosaur", "elephant", "horse", "whale", "dragon", "windmill", "castle",
           "boulder", "volcano", "bus", "train", "plane", "airplane", "helicopter"]),
    (2.0, ["tent", "bike", "bicycle", "sled", "wagon", "barrel", "tree_stump", "stump",
           "penguin", "bear", "panda", "wolf", "deer", "fox", "beaver", "otter",
           "swan", "eagle", "giraffe", "lion", "tiger", "gorilla", "moose", "camel",
           "zebra", "chest", "crate", "drum", "anvil", "cannon", "kettle", "cauldron"]),
    (0.3, ["bug", "ant", "bee", "fly", "butterfly", "coin", "button", "seed", "pebble",
           "gem", "acorn", "snail", "worm", "key", "ring", "marble", "berry", "thimble",
           "thumbtack", "nail", "bead", "sequin", "stamp", "pin"]),
    (0.6, ["camera", "shoe", "boot", "ball", "cup", "bottle", "flower", "mushroom",
           "frog", "mouse", "squirrel", "fish", "bird", "hat", "candle", "book",
           "egg", "leaf", "feather", "glove", "lantern", "phone", "compass", "jar",
           "tin", "lunchbox", "helmet", "apple", "carrot", "cookie", "cupcake",
           "donut", "fork", "spoon", "knife", "scissors", "brush", "comb",
           "crayon", "pencil", "pen", "eraser", "ruler", "magnify", "flashlight",
           "sock", "mitten", "ribbon", "bow", "badge", "medal", "whistle", "crab",
           "starfish", "dragonfly", "parrot", "turtle", "snail", "frog", "lizard"]),
]
DEFAULT_SCALE = 1.0


def get_base_scale(name: str, desc: str) -> float:
    # Match name tokens exactly (avoids "dragon" matching "dragonfly")
    name_tokens = set(name.lower().split("_"))
    desc_lower = desc.lower()
    for scale, keywords in SCALE_RULES:
        for kw in keywords:
            if kw in name_tokens or re.search(r"\b" + re.escape(kw) + r"\b", desc_lower):
                return scale
    return DEFAULT_SCALE


def main():
    with open(THEMES_JSON) as f:
        data = json.load(f)

    shared = data.get("shared", {})
    themes = data["themes"]

    shared_cache: dict = {}
    for name, item in shared.items():
        tags = item.get("tags", ["ground"])
        desc = item.get("desc", "")
        shared_cache[name] = {
            "tags": tags,
            "base_scale": get_base_scale(name, desc),
            "preferred_anchors": [],
        }

    all_tags: dict = {}

    for theme_name, theme_data in themes.items():
        theme_tags: dict = {}
        for item in theme_data.get("items", []):
            item_name = item["name"]

            if "shared" in item:
                shared_key = item["shared"]
                theme_tags[item_name] = shared_cache.get(
                    shared_key,
                    {"tags": ["ground"], "base_scale": DEFAULT_SCALE, "preferred_anchors": []},
                ).copy()
            else:
                tags = item.get("tags", ["ground"])
                desc = item.get("desc", "")
                theme_tags[item_name] = {
                    "tags": tags,
                    "base_scale": get_base_scale(item_name, desc),
                    "preferred_anchors": [],
                }

        all_tags[theme_name] = theme_tags
        print(f"Tagged {len(theme_tags)} items for: {theme_name}")

    with open(OUTPUT_JSON, "w") as f:
        json.dump(all_tags, f, indent=2)
    print(f"\nSaved item tags to {OUTPUT_JSON}")


if __name__ == "__main__":
    main()
