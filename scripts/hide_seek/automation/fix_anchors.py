import json
from pathlib import Path

JSON_PATH = Path("assets/data/hide_seek/anchors_data.json")

# Image dimensions for these high-quality assets
WIDTH = 2752
HEIGHT = 1536
BUFFER = 120 # 120px buffer from edges to ensure visibility

def fix_anchors():
    if not JSON_PATH.exists():
        print(f"File not found: {JSON_PATH}")
        return

    with open(JSON_PATH, "r") as f:
        data = json.load(f)

    changed = 0
    for theme, anchors in data.items():
        for anchor in anchors:
            # Clamp X
            old_x = anchor["x"]
            anchor["x"] = max(BUFFER, min(WIDTH - BUFFER, anchor["x"]))
            if old_x != anchor["x"]:
                changed += 1
                
            # Clamp Y
            old_y = anchor["y"]
            anchor["y"] = max(BUFFER, min(HEIGHT - BUFFER, anchor["y"]))
            if old_y != anchor["y"]:
                changed += 1
    
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2)
    
    print(f"Clamped {changed} coordinate values to safe zone (Buffer: {BUFFER}px).")

if __name__ == "__main__":
    fix_anchors()
