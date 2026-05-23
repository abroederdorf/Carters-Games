import json
from pathlib import Path

# Constants
ANCHORS_JSON = Path("assets/data/hide_seek/anchors_data.json")
THEME = "pet_shop"
WIDTH = 1408
HEIGHT = 768
GRID_COLS = 5
GRID_ROWS = 10
RADIUS = 50

def _row_tags(row: int) -> list:
    frac = row / GRID_ROWS
    if frac < 0.20:
        return ["sky"]
    elif frac < 0.45:
        return ["sky", "foliage"]
    elif frac < 0.70:
        return ["foliage", "structure"]
    elif frac < 0.88:
        return ["ground"]
    else:
        return ["ground", "shadow"]

def _difficulty(col: int, row: int) -> int:
    # Simpler calculation for a clean grid
    return 1

def generate_grid():
    margin_x = WIDTH * 0.1
    margin_y = HEIGHT * 0.1
    usable_w = WIDTH - (margin_x * 2)
    usable_h = HEIGHT - (margin_y * 2)
    
    cell_w = usable_w / (GRID_COLS - 1) if GRID_COLS > 1 else 0
    cell_h = usable_h / (GRID_ROWS - 1) if GRID_ROWS > 1 else 0
    
    anchors = []
    idx = 0
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            x = int(margin_x + (cell_w * col))
            y = int(margin_y + (cell_h * row))
            anchors.append({
                "id": idx,
                "x": x,
                "y": y,
                "radius": RADIUS,
                "tags": _row_tags(row),
                "difficulty": _difficulty(col, row),
            })
            idx += 1
    return anchors

def main():
    if not ANCHORS_JSON.exists():
        print(f"Error: {ANCHORS_JSON} not found")
        return

    with open(ANCHORS_JSON, "r") as f:
        all_data = json.load(f)

    # Replace pet_shop anchors with clean grid
    all_data[THEME] = generate_grid()

    with open(ANCHORS_JSON, "w") as f:
        json.dump(all_data, f, indent=2)
    
    print(f"[{THEME}] Reset to clean {GRID_ROWS}x{GRID_COLS} grid in anchors_data.json")

if __name__ == "__main__":
    main()
