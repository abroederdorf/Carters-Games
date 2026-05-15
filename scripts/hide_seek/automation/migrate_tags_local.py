import json
from pathlib import Path

ITEM_TAGS_JSON = Path("assets/data/hide_seek/item_tags.json")

def migrate():
    if not ITEM_TAGS_JSON.exists():
        print("item_tags.json not found.")
        return

    with open(ITEM_TAGS_JSON, "r") as f:
        old_data = json.load(f)

    new_data = {}
    
    for theme, items in old_data.items():
        new_data[theme] = {}
        for item_name, tags in items.items():
            # If it's already a dict, keep it, otherwise convert from list
            if isinstance(tags, dict):
                new_data[theme][item_name] = tags
            else:
                new_data[theme][item_name] = {
                    "tags": tags,
                    "base_scale": 1.0,
                    "preferred_anchors": []
                }
    
    with open(ITEM_TAGS_JSON, "w") as f:
        json.dump(new_data, f, indent=2)
    
    print(f"Successfully migrated {len(new_data)} themes to new format locally (Cost: $0.00)")

if __name__ == "__main__":
    migrate()
