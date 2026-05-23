from PIL import Image, ImageDraw

def clean_kitten(image_path):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    
    # We'll try to find white gaps that might be trapped inside limbs
    # but aren't the eyes (usually in the upper half).
    
    # First, standard perimeter fill with high tolerance
    seeds = [(0,0), (w-1, 0), (0, h-1), (w-1, h-1), (w//2, 0), (w//2, h-1), (0, h//2), (w-1, h//2)]
    for s in seeds:
        ImageDraw.floodfill(img, s, (255, 255, 255, 0), thresh=80)
        
    # Now look for white islands in the bottom half (gaps between legs)
    for y in range(h // 2, h - 5, 5):
        for x in range(5, w - 5, 5):
            p = img.getpixel((x, y))
            # If very white and opaque
            if p[3] > 0 and p[0] > 240 and p[1] > 240 and p[2] > 240:
                # Potential gap between legs
                ImageDraw.floodfill(img, (x, y), (255, 255, 255, 0), thresh=50)
                
    img.save(image_path)
    print(f"Cleaned kitten: {image_path}")

if __name__ == "__main__":
    clean_kitten("assets/sprites/hide_seek/pet_shop/kitten.png")
