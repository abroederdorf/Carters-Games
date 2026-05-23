import os
import sys
from pathlib import Path
from PIL import Image

ASSET_ROOT = Path("assets/sprites/hide_seek")

def make_transparent(image_path, tolerance=30):
    """
    Robustly makes the background transparent using a flood fill.
    Scans the perimeter for seeds to ensure background is hit.
    """
    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    from PIL import ImageDraw
    
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
        
    # Skip if top-left is already transparent (simple optimization)
    if img.getpixel((0,0))[3] == 0:
        print(f"  Skipping: {image_path.name} (already transparent)")
        return

    for seed in seeds:
        pixel = img.getpixel(seed)
        if pixel[3] == 0:
            continue
        # Only start if the seed is "whitish"
        if pixel[0] >= 220 and pixel[1] >= 220 and pixel[2] >= 220:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    # Autocrop
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"  Autocropped to: {img.size}")

    img.save(image_path)

def main():
    targets = sys.argv[1:]
    
    if targets:
        # Process specific files or entire theme folders passed as arguments
        for t in targets:
            p = Path(t)
            # Support relative paths from root
            if not p.exists():
                # Check if it's a theme name
                p = ASSET_ROOT / t
            
            if p.is_dir():
                print(f"\n--- Theme: {p.name} ---")
                for img_path in p.glob("*.png"):
                    if img_path.name == "bg.png" or img_path.name.startswith("bg_"):
                        continue
                    make_transparent(img_path)
            elif p.is_file() and p.suffix == ".png":
                make_transparent(p)
            else:
                print(f"Warning: Target {t} not found or not a valid PNG/Directory")
        return

    # Default: Iterate through all theme directories
    for theme_dir in ASSET_ROOT.iterdir():
        if not theme_dir.is_dir():
            continue
            
        print(f"\n--- Theme: {theme_dir.name} ---")
        for img_path in theme_dir.glob("*.png"):
            if img_path.name == "bg.png" or img_path.name.startswith("bg_"):
                continue
            make_transparent(img_path)


if __name__ == "__main__":
    main()
