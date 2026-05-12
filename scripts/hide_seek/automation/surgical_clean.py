import os
from pathlib import Path
from PIL import Image, ImageDraw

def surgical_transparency(image_path, tolerance=40):
    """
    More aggressive transparency that attempts to hit 'islands' of white 
    by checking a grid of seeds, not just the perimeter.
    """
    print(f"Surgical Transparency: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # Grid of seeds to catch 'inside' white areas
    # For a ladder/hiker, we check a 10x10 grid
    for x in range(0, width, width // 10):
        for y in range(0, height, height // 10):
            seed = (x, y)
            if seed[0] >= width or seed[1] >= height: continue
            
            pixel = img.getpixel(seed)
            # If it's very white and NOT transparent, try to fill
            if pixel[0] >= 240 and pixel[1] >= 240 and pixel[2] >= 240 and pixel[3] > 0:
                ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    img.save(image_path)

if __name__ == "__main__":
    items = [
        "assets/sprites/hide_seek/mountains/hiker.png",
        "assets/sprites/hide_seek/mountains/climber.png",
        "assets/sprites/hide_seek/fire_station/ladder.png"
    ]
    for item in items:
        if os.path.exists(item):
            surgical_transparency(item)
