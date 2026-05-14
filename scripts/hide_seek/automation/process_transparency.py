import os
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
        
    # We use a set to track already processed background to avoid redundant fills
    # However, floodfill is fast enough to just call. 
    # To be more efficient, we check if the pixel is still whitish before filling.
    for seed in seeds:
        pixel = img.getpixel(seed)
        # If it's already transparent, skip
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
    # Iterate through all theme directories
    for theme_dir in ASSET_ROOT.iterdir():
        if not theme_dir.is_dir() or theme_dir.name == "shared":
            continue
            
        print(f"\n--- Theme: {theme_dir.name} ---")
        for img_path in theme_dir.glob("*.png"):
            # Skip background images
            if img_path.name == "bg.png" or img_path.name.startswith("bg_"):
                continue
                
            make_transparent(img_path)

    # Also process shared folder
    shared_dir = ASSET_ROOT / "shared"
    if shared_dir.exists():
        print("\n--- Shared Items ---")
        for img_path in shared_dir.glob("*.png"):
            make_transparent(img_path)

if __name__ == "__main__":
    main()
