from PIL import Image, ImageDraw

def clean_leash(image_path, white_threshold=230, tolerance=50):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    print(f"Processing leash: {image_path} ({w}x{h})")
    
    # We scan the entire image and flood fill every white pixel we find.
    # This will catch the "trapped" white area in the handle.
    for y in range(0, h, 20):
        for x in range(0, w, 20):
            p = img.getpixel((x, y))
            # If the pixel is opaque and very white
            if p[3] > 0 and p[0] >= white_threshold and p[1] >= white_threshold and p[2] >= white_threshold:
                ImageDraw.floodfill(img, (x, y), (255, 255, 255, 0), thresh=tolerance)
                
    img.save(image_path)
    print(f"  Cleaning complete for {image_path}")

if __name__ == "__main__":
    clean_leash("assets/sprites/hide_seek/pet_shop/leash.png")
