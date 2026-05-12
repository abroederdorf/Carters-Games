import json
from pathlib import Path

JSON_PATH = Path("assets/data/hide_seek/anchors_data.json")
MAX_Y = 700

def fix_anchors():
    if not JSON_PATH.exists():
        print(f"File not found: {JSON_PATH}")
        return

    with open(JSON_PATH, "r") as f:
        data = json.load(f)

    changed = 0
    for theme, anchors in data.items():
        for anchor in anchors:
            if anchor["y"] > MAX_Y:
                anchor["y"] = MAX_Y
                changed += 1
    
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2)
    
    print(f"Updated {changed} anchors. Max Y is now {MAX_Y}.")

if __name__ == "__main__":
    fix_anchors()
