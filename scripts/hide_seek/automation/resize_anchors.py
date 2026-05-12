import json
from pathlib import Path

JSON_PATH = Path("assets/data/hide_seek/anchors_data.json")

def resize_anchors(scale=1.25):
    if not JSON_PATH.exists():
        print(f"File not found: {JSON_PATH}")
        return

    with open(JSON_PATH, "r") as f:
        data = json.load(f)

    for theme, anchors in data.items():
        for anchor in anchors:
            anchor["radius"] = int(anchor["radius"] * scale)
    
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2)
    
    print(f"Increased radius for all anchors by {int((scale-1)*100)}%.")

if __name__ == "__main__":
    resize_anchors()
