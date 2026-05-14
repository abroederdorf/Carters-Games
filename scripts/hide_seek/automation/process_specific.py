import sys
from pathlib import Path
from PIL import Image, ImageDraw

def make_transparent(image_path, tolerance=30):
    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    seeds = []
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    for y in range(1, height - 1):
        seeds.append((0, y))
        seeds.append((width - 1, y))
        
    for seed in seeds:
        pixel = img.getpixel(seed)
        if pixel[3] == 0:
            continue
        if pixel[0] >= 200 and pixel[1] >= 200 and pixel[2] >= 200:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    # Autocrop
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"  Autocropped to: {img.size}")

    img.save(image_path)

if __name__ == "__main__":
    for path in sys.argv[1:]:
        make_transparent(Path(path))
