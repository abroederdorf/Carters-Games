from PIL import Image, ImageDraw

def clean_mesh_object(image_path, white_threshold=230, tolerance=50):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    print(f"Processing mesh object: {image_path} ({w}x{h})")
    
    # We scan the entire image in a fine grid and flood fill every white pixel we find.
    # This will catch all the "trapped" white areas between cage bars.
    for y in range(0, h, 10):
        for x in range(0, w, 10):
            p = img.getpixel((x, y))
            # If the pixel is opaque and very white
            if p[3] > 0 and p[0] >= white_threshold and p[1] >= white_threshold and p[2] >= white_threshold:
                ImageDraw.floodfill(img, (x, y), (255, 255, 255, 0), thresh=tolerance)
                
    img.save(image_path)
    print(f"  Aggressive mesh cleaning complete for {image_path}")

if __name__ == "__main__":
    clean_mesh_object("assets/sprites/hide_seek/pet_shop/bird_cage.png")
