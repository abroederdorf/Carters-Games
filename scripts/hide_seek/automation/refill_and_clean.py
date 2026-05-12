import os
from pathlib import Path
from PIL import Image, ImageDraw

ASSET_ROOT = Path("assets/sprites/hide_seek")

def refill_and_clean(image_path, crop_pixels=15, tolerance=40):
    """
    1. Refills transparent areas with pure white.
    2. Crops aggressive borders to remove artifacts.
    3. Re-processes transparency with a higher tolerance.
    """
    print(f"Refilling and Cleaning: {image_path}")
    
    # 1. Refill with White
    img = Image.open(image_path).convert("RGBA")
    white_bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    white_bg.paste(img, (0, 0), img)
    img = white_bg.convert("RGBA")
    
    # 2. Aggressive Crop
    width, height = img.size
    if width > crop_pixels * 2 and height > crop_pixels * 2:
        img = img.crop((crop_pixels, crop_pixels, width - crop_pixels, height - crop_pixels))
        width, height = img.size

    # 3. Re-process Transparency
    # Collect seeds from the entire perimeter
    seeds = []
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    for y in range(1, height - 1):
        seeds.append((0, y))
        seeds.append((width - 1, y))
        
    for seed in seeds:
        pixel = img.getpixel(seed)
        # If it's whitish, flood fill with transparency
        if pixel[0] >= 200 and pixel[1] >= 200 and pixel[2] >= 200:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    img.save(image_path)

def main():
    for theme_dir in ASSET_ROOT.iterdir():
        if not theme_dir.is_dir() or theme_dir.name == "shared":
            continue
            
        print(f"\n--- Processing Theme: {theme_dir.name} ---")
        for img_path in theme_dir.glob("*.png"):
            if "bg" in img_path.name:
                continue
            refill_and_clean(img_path)

if __name__ == "__main__":
    main()
