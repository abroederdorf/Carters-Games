import sys
from pathlib import Path
from PIL import Image, ImageDraw

def refill_white(image_path):
    print(f"Refilling: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # Create a white background of the same size
    white_bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    
    # Composite the image over the white background
    # This fills ALL transparent areas with white
    filled = Image.alpha_composite(white_bg, img)
    
    # Now we need to restore the EXTERNAL transparency
    # We'll use floodfill from the edges to make the outside transparent again
    draw = ImageDraw.Draw(filled)
    
    # Collect seeds from the perimeter
    seeds = []
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    for y in range(1, height - 1):
        seeds.append((0, y))
        seeds.append((width - 1, y))
        
    for seed in seeds:
        pixel = filled.getpixel(seed)
        # If it's pure white and fully opaque, it's our new background
        if pixel == (255, 255, 255, 255):
            ImageDraw.floodfill(filled, seed, (255, 255, 255, 0), thresh=10)
            
    filled.save(image_path)
    print(f"  Done.")

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        p = Path(arg)
        if p.exists():
            refill_white(p)
