import json
from pathlib import Path

ITEM_TAGS = Path("assets/data/hide_seek/item_tags.json")

def fix_scales():
    with open(ITEM_TAGS, "r") as f:
        data = json.load(f)
    
    ps = data["pet_shop"]
    
    # Setting more realistic scales for small pet shop items
    ps["kitten"]["base_scale"] = 0.4
    ps["puppy"]["base_scale"] = 0.5
    ps["goldfish_bowl"]["base_scale"] = 0.5
    ps["parrot"]["base_scale"] = 0.35
    ps["bunny"]["base_scale"] = 0.4
    ps["cat_toy"]["base_scale"] = 0.25
    ps["guinea_pig"]["base_scale"] = 0.3
    ps["turtle"]["base_scale"] = 0.4
    ps["lizard"]["base_scale"] = 0.25
    ps["bird_cage"]["base_scale"] = 0.5
    ps["snake"]["base_scale"] = 0.45
    ps["pet_food_bowl"]["base_scale"] = 0.25
    ps["leash"]["base_scale"] = 0.3
    ps["dog_collar"]["base_scale"] = 0.25
    ps["tennis_ball"]["base_scale"] = 0.2
    ps["hamster_wheel"]["base_scale"] = 0.45
    ps["beta_fish"]["base_scale"] = 0.35
    ps["tetra_fish"]["base_scale"] = 0.3
    ps["mouse"]["base_scale"] = 0.2

    with open(ITEM_TAGS, "w") as f:
        json.dump(data, f, indent=2)
    print("Updated item_tags.json with improved Pet Shop scales.")

if __name__ == "__main__":
    fix_scales()
