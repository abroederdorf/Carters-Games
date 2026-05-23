import os
from pathlib import Path
from PIL import Image, ImageDraw

def surgical_transparency(image_path, seeds, tolerance=30):
    """
    Makes specific areas transparent based on seed points.
    """
    print(f"Surgically processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    
    for seed in seeds:
        pixel = img.getpixel(seed)
        print(f"  Seed {seed} color: {pixel}")
        # Flood fill with transparency
        ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    img.save(image_path)
    print(f"  Saved changes to {image_path}")

if __name__ == "__main__":
    # Path to the purple alien
    alien_path = Path("assets/sprites/hide_seek/space/purple_alien.png")
    
    # We need to find the coordinate between the legs.
    # Since I can't "see" the image, I'll use a middle-bottom strategy 
    # based on the current size of the image.
    img = Image.open(alien_path)
    width, height = img.size
    print(f"Image size: {width}x{height}")
    
    # Typical "between legs" area for a centered character is bottom-middle
    # We'll try a few points in that vicinity that are likely to be the white gap.
    target_seeds = [
        (width // 2, height - 20),
        (width // 2, height - 50),
        (width // 2 - 10, height - 30),
        (width // 2 + 10, height - 30)
    ]
    
    surgical_transparency(alien_path, target_seeds)
