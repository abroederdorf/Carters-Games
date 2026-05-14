import os
from pathlib import Path
from PIL import Image

# Targeted files with internal transparency "holes"
FILES = [
    "assets/sprites/hide_seek/mountains/hiker.png",
    "assets/sprites/hide_seek/mountains/skier.png",
    "assets/sprites/hide_seek/mountains/water_bottle.png",
    "assets/sprites/hide_seek/mountains/climbing_rope.png"
]

def surgical_fix(path):
    print(f"Surgically fixing transparency: {path}")
    if not os.path.exists(path):
        print(f"  Warning: File not found {path}")
        return

    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Target near-white pixels (Imagen usually uses 255, 255, 255 for bg)
            # Threshold of 240 is safe for these specific items which are mostly bold colors
            if r >= 240 and g >= 240 and b >= 240:
                pixels[x, y] = (255, 255, 255, 0)

    img.save(path)

if __name__ == "__main__":
    for f in FILES:
        surgical_fix(f)
    print("Done.")
