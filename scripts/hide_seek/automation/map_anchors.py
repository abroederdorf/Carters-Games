import json
import random
from pathlib import Path

try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

THEMES_JSON = Path("assets/data/hide_seek/themes.json")
ANCHORS_JSON = Path("assets/data/hide_seek/anchors_data.json")
ASSET_ROOT = Path("assets/sprites/hide_seek")

DEFAULT_WIDTH = 1920
DEFAULT_HEIGHT = 1080
GRID_COLS = 5
GRID_ROWS = 10   # 5×10 = 50 anchors per scene
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
    col_edge = abs(col - (GRID_COLS - 1) / 2) / ((GRID_COLS - 1) / 2)
    row_edge = abs(row - (GRID_ROWS - 1) / 2) / ((GRID_ROWS - 1) / 2)
    dist = max(col_edge, row_edge)
    if dist < 0.40:
        return 0
    elif dist < 0.85:
        return 1
    else:
        return 2


def _bg_size(theme_dir: Path) -> tuple:
    if PIL_AVAILABLE:
        for name in ["bg.png", "bg_fast.png", "bg_standard.png"]:
            p = theme_dir / name
            if p.exists():
                return Image.open(p).size
        for p in theme_dir.glob("bg_*.png"):
            return Image.open(p).size
    return DEFAULT_WIDTH, DEFAULT_HEIGHT


def _generate_anchors(width: int, height: int) -> list:
    cell_w = width / GRID_COLS
    cell_h = height / GRID_ROWS
    jx = cell_w * 0.25
    jy = cell_h * 0.25
    anchors = []
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            x = int(cell_w * (col + 0.5) + random.uniform(-jx, jx))
            y = int(cell_h * (row + 0.5) + random.uniform(-jy, jy))
            x = max(RADIUS, min(width - RADIUS, x))
            y = max(RADIUS, min(height - RADIUS, y))
            anchors.append({
                "x": x,
                "y": y,
                "radius": RADIUS,
                "tags": _row_tags(row),
                "difficulty": _difficulty(col, row),
            })
    return anchors


def main():
    with open(THEMES_JSON) as f:
        data = json.load(f)

    all_anchors: dict = {}
    if ANCHORS_JSON.exists():
        with open(ANCHORS_JSON) as f:
            all_anchors = json.load(f)

    themes = list(data["themes"].keys())

    for theme in themes:
        if theme in all_anchors:
            print(f"[{theme}] Already has anchors — skipping. (delete from anchors_data.json to regenerate)")
            continue

        theme_dir = ASSET_ROOT / theme
        width, height = _bg_size(theme_dir)
        random.seed(hash(theme) & 0xFFFFFF)
        anchors = _generate_anchors(width, height)
        all_anchors[theme] = anchors
        source = f"bg ({width}×{height})" if (width, height) != (DEFAULT_WIDTH, DEFAULT_HEIGHT) else f"default ({width}×{height})"
        print(f"[{theme}] Generated {len(anchors)} anchors — {source}")

    with open(ANCHORS_JSON, "w") as f:
        json.dump(all_anchors, f, indent=2)
    print(f"\nSaved anchors to {ANCHORS_JSON}")


if __name__ == "__main__":
    main()
