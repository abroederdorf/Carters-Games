from PIL import Image, ImageDraw
from pathlib import Path

def clean_bottom_white(image_path, height_percent=0.2, tolerance=40):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    
    # Scan the bottom X% of the image for white pixels
    start_y = int(h * (1.0 - height_percent))
    
    for y in range(h - 1, start_y, -5):
        for x in range(1, w - 1, 5):
            p = img.getpixel((x, y))
            # If pixel is opaque and even remotely white-ish
            if p[3] > 0 and p[0] >= 200 and p[1] >= 200 and p[2] >= 200:
                # Check if it's likely a gap (not part of a tiny detail)
                # We flood fill it with a high tolerance
                ImageDraw.floodfill(img, (x, y), (255, 255, 255, 0), thresh=70)
                
    img.save(image_path)
    print(f"Cleaned bottom white areas in {image_path}")

if __name__ == "__main__":
    clean_bottom_white("assets/sprites/hide_seek/space/robot.png")
