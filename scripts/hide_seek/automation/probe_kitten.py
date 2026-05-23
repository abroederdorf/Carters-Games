from PIL import Image

def probe_kitten(image_path):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    print(f"Kitten size: {w}x{h}")
    
    # Scan for opaque white-ish pixels that are surrounded by non-white pixels
    # This might help identify internal gaps.
    white_spots = []
    for y in range(10, h - 10, 5):
        for x in range(10, w - 10, 5):
            p = img.getpixel((x, y))
            if p[3] > 0 and p[0] > 240 and p[1] > 240 and p[2] > 240:
                white_spots.append((x, y))
    
    print(f"Found {len(white_spots)} white points. Printing first 20:")
    for spot in white_spots[:20]:
        print(f"  {spot}: {img.getpixel(spot)}")

if __name__ == "__main__":
    probe_kitten("assets/sprites/hide_seek/pet_shop/kitten.png")
