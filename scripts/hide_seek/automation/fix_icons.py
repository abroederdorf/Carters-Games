import os
from pathlib import Path
from PIL import Image, ImageDraw

def fix_rounded_corners(image_path, radius=450, tolerance=40):
    """
    Ensures corners are transparent by applying a rounded rectangle mask
    AND flood-filling white from the corners to catch any baked-in backgrounds.
    """
    print(f"Fixing corners for: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # 1. Flood fill white from the corners first to clear any solid white background
    for seed in [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]:
        pixel = img.getpixel(seed)
        if pixel[0] >= 200 and pixel[1] >= 200 and pixel[2] >= 200:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    # 2. Apply rounded mask
    mask = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, width, height), radius=radius, fill=255)
    
    result = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask=mask)
    
    result.save(image_path)

if __name__ == "__main__":
    icon_dir = Path("assets/icons")
    for img_path in icon_dir.glob("*.png"):
        fix_rounded_corners(str(img_path))
