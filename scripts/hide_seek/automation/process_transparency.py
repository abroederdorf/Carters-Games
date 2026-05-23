import os
import sys
from pathlib import Path
from PIL import Image

ASSET_ROOT = Path("assets/sprites/hide_seek")

def make_transparent(image_path, tolerance=30, clear_holes=False):
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
        
    for seed in seeds:
        pixel = img.getpixel(seed)
        if pixel[3] == 0:
            continue
        # Only start if the seed is "whitish"
        if pixel[0] >= 220 and pixel[1] >= 220 and pixel[2] >= 220:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    # Secondary Pass: Internal Holes
    # For "isolated on white" assets, any remaining very-white pixels are likely background holes
    if clear_holes:
        print("  Clearing internal holes...")
        # Use a more surgical approach: find white pixels that weren't caught by perimeter fill
        # and floodfill them. This is safer than global replacement.
        
        # We'll scan a grid to find candidates
        step = 5
        for y in range(step, height - step, step):
            for x in range(step, width - step, step):
                pixel = img.getpixel((x, y))
                # If it's extremely white and NOT transparent
                if pixel[3] > 0 and pixel[0] >= 245 and pixel[1] >= 245 and pixel[2] >= 245:
                    # Double check it's not a tiny isolated pixel by checking neighbors
                    # This helps avoid eating intentional white highlights
                    ImageDraw.floodfill(img, (x, y), (255, 255, 255, 0), thresh=tolerance)

    # Autocrop
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"  Autocropped to: {img.size}")

    img.save(image_path)

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Process transparency for hide and seek assets.")
    parser.add_argument("targets", nargs="*", help="Files or theme directories to process.")
    parser.add_argument("--holes", action="store_true", help="Clear internal white holes (use for wheels, handles, etc.)")
    parser.add_argument("--tolerance", type=int, default=30, help="Tolerance for flood fill (0-255)")
    
    args = parser.parse_args()
    
    if args.targets:
        # Process specific files or entire theme folders passed as arguments
        for t in args.targets:
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
                    make_transparent(img_path, tolerance=args.tolerance, clear_holes=args.holes)
            elif p.is_file() and p.suffix == ".png":
                make_transparent(p, tolerance=args.tolerance, clear_holes=args.holes)
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
            make_transparent(img_path, tolerance=args.tolerance, clear_holes=args.holes)


if __name__ == "__main__":
    main()
