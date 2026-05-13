import os
from pathlib import Path
from PIL import Image, ImageDraw

# Target files in the fishing directory
TARGET_FILES = [
    "fish_plain_green.png",
    "fish_plain_orange.png",
    "fish_plain_purple.png",
    "fish_plain_red.png",
    "fish_plain_white.png",
    "fish_plain_yellow.png",
    "fish_sword.png",
    "fish_butterfly.png",
    "pelican.png",
    "octopus.png",
    "shark.png"
]

FISHING_DIR = Path("assets/sprites/fishing")

def make_transparent(image_path, tolerance=30):
    """
    Robustly makes the background transparent using a flood fill.
    Scans the perimeter for seeds to ensure background is hit.
    """
    if not image_path.exists():
        print(f"Skipping (not found): {image_path}")
        return

    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # Collect seeds from the entire perimeter
    seeds = []
    # Top and bottom edges
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    # Left and right edges
    for y in range(1, height - 1):
        seeds.append((0, y))
        seeds.append((width - 1, y))
        
    for seed in seeds:
        pixel = img.getpixel(seed)
        if pixel[3] == 0:
            continue
        # Check if the pixel is whitish
        if pixel[0] >= 220 and pixel[1] >= 220 and pixel[2] >= 220:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    img.save(image_path)

if __name__ == "__main__":
    for filename in TARGET_FILES:
        make_transparent(FISHING_DIR / filename)
    print("Done processing transparency for fishing assets.")
