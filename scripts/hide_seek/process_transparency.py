import os
from pathlib import Path
from PIL import Image

ASSET_ROOT = Path("assets/sprites/hide_seek")

def make_transparent(image_path, tolerance=20):
    """
    Makes the background of an image transparent using a flood fill from the corners.
    This preserves white pixels inside the object.
    """
    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    
    # Use flood fill from the four corners (0,0), (w-1,0), (0,h-1), (w-1,h-1)
    # Target color is usually white (255,255,255)
    width, height = img.size
    
    # We'll use a mask-based approach or ImageDraw.floodfill
    from PIL import ImageDraw
    
    # Coordinates to start flood fill from
    seeds = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]
    
    for seed in seeds:
        pixel = img.getpixel(seed)
        # Only start if the corner is actually "whitish"
        if pixel[0] >= 230 and pixel[1] >= 230 and pixel[2] >= 230:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

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
